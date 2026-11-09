terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "timeout --foreground \"$READINESS_TIMEOUT_SECONDS\" bash \"$POLLER_SCRIPT\""

    environment = {
      STORAGE_ACCOUNT_ID        = self.id
      POLLER_SCRIPT             = abspath("${path.module}/wait-for-service-properties.sh")
      READINESS_TIMEOUT_SECONDS = "600"
      POLL_INTERVAL_SECONDS     = "10"
    }
  }

  # PowerShell 7 alternative: uncomment this block and remove the Bash block above.
  # provisioner "local-exec" {
  #   interpreter = ["pwsh", "-NoProfile", "-NonInteractive", "-Command"]
  #   command     = "& $env:POLLER_SCRIPT"
  #
  #   environment = {
  #     STORAGE_ACCOUNT_ID        = self.id
  #     POLLER_SCRIPT             = abspath("${path.module}/wait-for-service-properties.ps1")
  #     READINESS_TIMEOUT_SECONDS = "600"
  #     POLL_INTERVAL_SECONDS     = "10"
  #   }
  # }
}

resource "azurerm_storage_account_queue_properties" "example" {
  storage_account_id = azurerm_storage_account.example.id

  logging {
    version               = "1.0"
    delete                = true
    read                  = true
    write                 = true
    retention_policy_days = 7
  }
}

resource "azurerm_storage_account_table_properties" "example" {
  storage_account_id = azurerm_storage_account.example.id

  logging {
    version               = "1.0"
    delete                = true
    read                  = true
    write                 = true
    retention_policy_days = 7
  }
}

output "storage_account_id" {
  value = azurerm_storage_account.example.id
}
