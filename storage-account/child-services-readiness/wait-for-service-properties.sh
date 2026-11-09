#!/usr/bin/env bash
set -euo pipefail

: "${STORAGE_ACCOUNT_ID:?Set STORAGE_ACCOUNT_ID to the storage account ARM resource ID}"
: "${POLL_INTERVAL_SECONDS:=10}"

if [[ ! "$POLL_INTERVAL_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
  printf 'POLL_INTERVAL_SECONDS must be a positive integer.\n' >&2
  exit 1
fi

trap 'printf "Timed out waiting for storage service properties on %s.\n" "$STORAGE_ACCOUNT_ID" >&2; exit 1' TERM

arm_endpoint=$(az cloud show --query endpoints.resourceManager --output tsv --only-show-errors)
api_version="2025-08-01"

# Standard StorageV2 supports all four services. For other account kinds/SKUs,
# adjust this list to probe only supported services
for service in blobServices fileServices queueServices tableServices; do
  url="${arm_endpoint%/}${STORAGE_ACCOUNT_ID}/${service}/default?api-version=${api_version}"
  printf 'Waiting for %s service properties...\n' "$service"

  while true; do
    if error=$(az rest --method get --url "$url" --output none --only-show-errors 2>&1); then
      printf '%s service properties are ready.\n' "$service"
      break
    fi

    if [[ "$error" =~ \([[:alnum:]]*NotFound\) ||
          "$error" == *"ERROR: Not Found"* ||
          "$error" =~ [Ss]tatus[[:space:]]+[Cc]ode:[[:space:]]*404 ]]; then
      printf '%s is not available yet; retrying in %s seconds.\n' "$service" "$POLL_INTERVAL_SECONDS"
      sleep "$POLL_INTERVAL_SECONDS"
    else
      printf 'Failed to read %s service properties:\n%s\n' "$service" "$error" >&2
      exit 1
    fi
  done
done

printf 'All supported storage service properties are ready.\n'
