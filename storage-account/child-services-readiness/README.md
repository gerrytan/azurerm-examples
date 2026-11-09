# Storage account child services readiness

main.tf implements the child services (blob, file, queue, table) readiness check after creation of a storage account to workaround AzureRM issue https://github.com/hashicorp/terraform-provider-azurerm/issues/33650