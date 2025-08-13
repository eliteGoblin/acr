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
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
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

  name                = "${var.name}-${each.key}-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = each.value.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-${each.key}-conn"
    private_connection_resource_id = azurerm_container_registry.this.id
    is_manual_connection           = each.value.manual_connection
    subresource_names              = each.value.subresource_names
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []

    content {
      name                 = "${var.name}-${each.key}-dnsgrp"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }
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