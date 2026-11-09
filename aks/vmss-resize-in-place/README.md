# AKS VMSS in-place resize

The default behaviour of VM resizing in an [azurerm_kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) is to create a temporary node pool while the default one is being resized.

This examples demonstrates how to utilise the in-place resize using combination of AzureRM and AzAPI while the feature is still in preview: https://learn.microsoft.com/en-us/azure/aks/resize-node-pool?tabs=azure-cli#resize-a-vmss-node-pool-in-place-preview 

Once GA and supported in AzureRM, the `default_node_pool.vm_size` can be adjusted to the remote value in Azure, and `lifecycle.ignore_changes` and `azapi_update_resource` removed. Removing `azapi_update_resource` won't delete the AKS cluster.

```diff
 resource "azurerm_kubernetes_cluster" "example" {
   # ...
   default_node_pool {
     name       = "default"
     node_count = 1
     type       = "VirtualMachineScaleSets"
-    vm_size    = "Standard_D4ds_v6"
+    vm_size    = "Standard_D8ds_v6"
   }
   # ...
-  lifecycle {
-    # AzAPI owns the VM size after AzureRM creates the default node pool.
-    ignore_changes = [default_node_pool[0].vm_size]
-  }
 }

-resource "azapi_update_resource" "default_node_pool_resize" {
-  type        = "Microsoft.ContainerService/managedClusters/agentPools@2026-07-01"
-  resource_id = "${azurerm_kubernetes_cluster.example.id}/agentPools/${azurerm_kubernetes_cluster.example.default_node_pool[0].name}"
-
-  body = {
-    properties = {
-      vmSize = "Standard_D8ds_v6"
-    }
-  }
-
-  timeouts {
-    create = "90m"
-    update = "90m"
-  }
-}
```
