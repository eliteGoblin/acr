##############################################################################
# Azure Container Registry with Private Endpoints Module
# 
# This module creates a secure Azure Container Registry with:
# - Premium SKU (required for private endpoints)  
# - Public access disabled (secure by default)
# - Admin user disabled (secure by default)
# - Private endpoints for secure network access
##############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}

locals {
  # Validate that private endpoints are configured
  has_private_endpoints = length(var.private_endpoints) > 0
}

##############################################################################
# Azure Container Registry
##############################################################################
resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = var.tags

  lifecycle {
    precondition {
      condition     = local.has_private_endpoints
      error_message = "At least one private endpoint must be configured when public access is disabled."
    }
  }
}

##############################################################################
# Private Endpoints
##############################################################################
resource "azurerm_private_endpoint" "pe" {
  for_each = var.private_endpoints

  name                = each.key # Use the map key as the private endpoint name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = each.value.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${each.key}-conn"
    private_connection_resource_id = azurerm_container_registry.this.id
    is_manual_connection           = each.value.manual_connection
    subresource_names              = each.value.subresource_names
  }

  # Static IP configuration using ip_configuration block
  # ACR requires specific member names for static IP assignment
  dynamic "ip_configuration" {
    for_each = each.value.private_ip_address != null ? [
      {
        name               = "${each.key}-registry-ipconfig"
        private_ip_address = each.value.private_ip_address
        subresource_name   = "registry"
        member_name        = "registry"
      },
      {
        name               = "${each.key}-data-ipconfig"
        private_ip_address = join(".", concat(slice(split(".", each.value.private_ip_address), 0, 3), [tostring(tonumber(split(".", each.value.private_ip_address)[3]) + 1)]))
        subresource_name   = "registry"
        member_name        = "registry_data_australiaeast"
      }
    ] : []
    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = ip_configuration.value.subresource_name
      member_name        = ip_configuration.value.member_name
    }
  }

  # Static IP assignment is supported via private_ip_address parameter

  # DNS zone management is out of scope for this module
  # Users should handle DNS zones and linking externally
}

##############################################################################
# Validation
##############################################################################
resource "null_resource" "validate_security" {
  count = 1

  lifecycle {
    postcondition {
      condition     = azurerm_container_registry.this.sku == "Premium"
      error_message = "ACR SKU must be Premium for private endpoints."
    }

    postcondition {
      condition     = azurerm_container_registry.this.public_network_access_enabled == false
      error_message = "Public network access must be disabled for security."
    }

    postcondition {
      condition     = azurerm_container_registry.this.admin_enabled == false
      error_message = "Admin user must be disabled for security."
    }
  }
}