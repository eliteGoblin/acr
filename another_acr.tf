############################
# Load YAML Configuration
############################
locals {
  acr_config = yamldecode(file("${path.module}/config/azure_container_registry.yaml"))
}

############################
# Resource Group for ACRs
############################
resource "azurerm_resource_group" "acr_rg" {
  name     = local.acr_config.resource_group
  location = local.acr_config.location
  tags     = local.acr_config.tags
}

############################
# Data sources for subnets
############################
data "azurerm_subnet" "pe_subnets" {
  for_each = { for acr in local.acr_config.container_registries : acr.name => acr }

  name                 = each.value.private_endpoint.subnet.name
  virtual_network_name = each.value.private_endpoint.subnet.vnet_name
  resource_group_name  = each.value.private_endpoint.subnet.resource_group
}

############################
# ACRs with Private Endpoints
############################
module "devops_acrs" {
  for_each = { for acr in local.acr_config.container_registries : acr.name => acr }

  source = "./modules/azure_container_registry"

  # ACR configuration
  name                = each.value.name
  resource_group_name = azurerm_resource_group.acr_rg.name
  location            = azurerm_resource_group.acr_rg.location

  # Private endpoint configuration
  private_endpoints = {
    (each.value.private_endpoint.name) = {
      subnet_id         = data.azurerm_subnet.pe_subnets[each.key].id
      subresource_names = ["registry"]
      manual_connection = false
    }
  }

  tags = local.acr_config.tags
}

############################
# Outputs for ACRs
############################
output "devops_acrs_login_servers" {
  value       = { for name, acr in module.devops_acrs : name => acr.login_server }
  description = "DevOps ACR login server URLs"
}

output "devops_acrs_ids" {
  value       = { for name, acr in module.devops_acrs : name => acr.acr_id }
  description = "DevOps ACR resource IDs"
}

output "devops_acrs_private_endpoint_ids" {
  value       = { for name, acr in module.devops_acrs : name => acr.private_endpoint_ids }
  description = "DevOps ACR private endpoint IDs"
}

output "devops_acrs_private_endpoint_details" {
  value       = { for name, acr in module.devops_acrs : name => acr.private_endpoint_details }
  description = "DevOps ACR private endpoint details including assigned IPs"
}