##############################################################################
# Example Outputs
##############################################################################

output "resource_group_name" {
  description = "The name of the created resource group."
  value       = azurerm_resource_group.example.name
}

output "acr_login_server" {
  description = "The login server URL of the Azure Container Registry."
  value       = module.acr.login_server
}

output "acr_id" {
  description = "The resource ID of the Azure Container Registry."
  value       = module.acr.acr_id
}

output "acr_name" {
  description = "The name of the Azure Container Registry."
  value       = module.acr.acr_name
}

output "private_endpoint_ids" {
  description = "List of private endpoint resource IDs."
  value       = module.acr.private_endpoint_ids
}

output "private_endpoint_private_ips" {
  description = "Map of private endpoint names to their private IP addresses."
  value       = module.acr.private_endpoint_private_ips
}

output "private_endpoint_details" {
  description = "Detailed information about each private endpoint."
  value       = module.acr.private_endpoint_details
}

output "private_endpoint_fqdns" {
  description = "Fully qualified domain names for private endpoints."
  value       = module.acr.private_endpoint_fqdns
}

output "private_dns_zone_id" {
  description = "The resource ID of the private DNS zone."
  value       = azurerm_private_dns_zone.acr.id
}

output "subnet_ids" {
  description = "Map of subnet names to their resource IDs."
  value = {
    for k, subnet in azurerm_subnet.pe_subnet : k => subnet.id
  }
}

output "vnet_ids" {
  description = "Map of VNet names to their resource IDs."
  value = merge(
    { hub = azurerm_virtual_network.hub.id },
    { for k, vnet in azurerm_virtual_network.spoke : k => vnet.id }
  )
}