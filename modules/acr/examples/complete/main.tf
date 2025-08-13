##############################################################################
# Complete Example: Azure Container Registry with Private Endpoints
#
# This example demonstrates a complete deployment of the ACR module with:
# - Resource group and networking infrastructure
# - Private DNS zone and VNet links
# - ACR with multiple private endpoints
# - Comprehensive outputs
##############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.112"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

##############################################################################
# Local Values
##############################################################################
locals {
  location = "East US"
  tags = {
    Environment = "example"
    Project     = "acr-module-demo"
    ManagedBy   = "terraform"
  }
}

##############################################################################
# Resource Group
##############################################################################
resource "azurerm_resource_group" "example" {
  name     = "rg-acr-module-example"
  location = local.location
  tags     = local.tags
}

##############################################################################
# Networking Infrastructure
##############################################################################
# Hub VNet with DNS zone
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

# Spoke VNets for private endpoints
resource "azurerm_virtual_network" "spoke" {
  for_each = {
    spoke1 = "10.1.0.0/16"
    spoke2 = "10.2.0.0/16"
  }

  name                = "vnet-${each.key}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = [each.value]
  tags                = local.tags
}

# Private endpoint subnets
resource "azurerm_subnet" "pe_subnet" {
  for_each = azurerm_virtual_network.spoke

  name                 = "snet-privatelink"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(each.value.address_space[0], 8, 1)]
}

##############################################################################
# Private DNS Zone
##############################################################################
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.example.name
  tags                = local.tags
}

# Link DNS zone to all VNets
resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = "link-hub"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  for_each = azurerm_virtual_network.spoke

  name                  = "link-${each.key}"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = each.value.id
  registration_enabled  = false
  tags                  = local.tags
}

##############################################################################
# Random suffix for globally unique ACR name
##############################################################################
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

##############################################################################
# ACR Module
##############################################################################
module "acr" {
  source = "../.."

  name                = "acrexample${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  # Configure private endpoints
  private_endpoints = {
    spoke1 = {
      subnet_id = azurerm_subnet.pe_subnet["spoke1"].id
    }
    spoke2 = {
      subnet_id         = azurerm_subnet.pe_subnet["spoke2"].id
      subresource_names = ["registry"]
    }
  }

  # Link to existing DNS zone
  private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]

  tags = local.tags
}