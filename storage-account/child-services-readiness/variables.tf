variable "subscription_id" {
  description = "Azure subscription used by both AzureRM and the Azure CLI ARM requests."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
  default     = "rg-storage-service-readiness"
}

variable "location" {
  description = "Azure region for the example resources."
  type        = string
  default     = "westus2"
}

variable "storage_account_name" {
  description = "Globally unique storage account name (3–24 lowercase letters or digits)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Use 3–24 lowercase letters or digits for the storage account name."
  }
}
