#requires -Version 7.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:STORAGE_ACCOUNT_ID)) {
    throw 'Set STORAGE_ACCOUNT_ID to the storage account ARM resource ID.'
}
foreach ($name in @('READINESS_TIMEOUT_SECONDS', 'POLL_INTERVAL_SECONDS')) {
    if ([Environment]::GetEnvironmentVariable($name) -notmatch '^[1-9][0-9]*$') {
        throw "$name must be a positive integer."
    }
}

$job = Start-Job -ScriptBlock {
    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $false
    $armEndpoint = az cloud show --query endpoints.resourceManager --output tsv --only-show-errors
    if ($LASTEXITCODE -ne 0) { throw 'Failed to get the Azure CLI ARM endpoint.' }
    $armEndpoint = $armEndpoint.TrimEnd('/')

    # Standard StorageV2 supports all four services. Adjust for other kinds/SKUs.
    foreach ($service in @('blobServices', 'fileServices', 'queueServices', 'tableServices')) {
        $url = "$armEndpoint$env:STORAGE_ACCOUNT_ID/$service/default?api-version=2025-08-01"
        Write-Output "Waiting for $service service properties..."
        while ($true) {
            $result = az rest --method get --url $url --output none --only-show-errors 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Output "$service service properties are ready."
                break
            }
            $message = $result | Out-String
            if ($message -match '\([a-zA-Z0-9]*NotFound\)|ERROR: Not Found|Status Code:\s*404') {
                Write-Output "$service is not available yet; retrying in $env:POLL_INTERVAL_SECONDS seconds."
                Start-Sleep -Seconds ([int]$env:POLL_INTERVAL_SECONDS)
            } else {
                throw "Failed to read $service service properties: $message"
            }
        }
    }
    Write-Output 'All supported storage service properties are ready.'
}

try {
    if (-not (Wait-Job -Job $job -Timeout ([int]$env:READINESS_TIMEOUT_SECONDS))) {
        throw "Timed out waiting for storage service properties on $env:STORAGE_ACCOUNT_ID."
    }
    Receive-Job -Job $job -ErrorAction Stop
    if ($job.State -ne 'Completed') { throw 'Storage service readiness poller failed.' }
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
} finally {
    Stop-Job -Job $job
    Remove-Job -Job $job -Force
}
