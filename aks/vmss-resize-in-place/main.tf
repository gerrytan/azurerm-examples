terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.13.0, < 6.0.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.13.0, < 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

provider "azapi" {
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "aks-vmss-resize-in-place"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "aks-vmss-resize-in-place"

  default_node_pool {
    name       = "default"
    node_count = 1
    type       = "VirtualMachineScaleSets"
    vm_size    = "Standard_D4ds_v6"
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    # AzAPI owns the VM size after AzureRM creates the default node pool.
    ignore_changes = [default_node_pool[0].vm_size]
  }
}

resource "azapi_update_resource" "default_node_pool_resize" {
  type        = "Microsoft.ContainerService/managedClusters/agentPools@2026-07-01"
  resource_id = "${azurerm_kubernetes_cluster.example.id}/agentPools/${azurerm_kubernetes_cluster.example.default_node_pool[0].name}"

  body = {
    properties = {
      vmSize = "Standard_D8ds_v6"
    }
  }

  timeouts {
    create = "90m"
    update = "90m"
  }
}
