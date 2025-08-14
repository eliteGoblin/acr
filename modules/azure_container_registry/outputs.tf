##############################################################################
# Azure Container Registry Outputs
##############################################################################

output "acr_id" {
  description = "The resource ID of the Azure Container Registry."
  value       = azurerm_container_registry.this.id
}

output "acr_name" {
  description = "The name of the Azure Container Registry."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "The login server URL of the Azure Container Registry (e.g., 'myacr.azurecr.io')."
  value       = azurerm_container_registry.this.login_server
}


##############################################################################
# Private Endpoint Outputs
##############################################################################

output "private_endpoint_ids" {
  description = "List of resource IDs for all created private endpoints."
  value       = [for pe in azurerm_private_endpoint.pe : pe.id]
}

output "private_endpoint_private_ips" {
  description = "Map of private endpoint names to their assigned private IP addresses."
  value = {
    for k, pe in azurerm_private_endpoint.pe :
    k => try(pe.private_service_connection[0].private_ip_address, null)
  }
}

output "private_endpoint_details" {
  description = "Detailed information about each private endpoint including IDs, names, IPs, and configurations."
  value = {
    for k, pe in azurerm_private_endpoint.pe :
    k => {
      id                = pe.id
      name              = pe.name
      private_ip        = try(pe.private_service_connection[0].private_ip_address, null)
      subnet_id         = pe.subnet_id
      subresource_names = pe.private_service_connection[0].subresource_names
      network_interface = pe.network_interface
    }
  }
}

