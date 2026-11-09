variable "subscription_id" {
  description = "Azure subscription used by both AzureRM and AzAPI. Defaults to ARM_SUBSCRIPTION_ID when omitted."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
  default     = "rg-aks-vmss-resize-in-place"
}

variable "location" {
  description = "Azure region for the resource group and AKS cluster."
  type        = string
  default     = "westus2"
}
