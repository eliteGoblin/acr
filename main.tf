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
############################
# Resource Group
############################
resource "azurerm_resource_group" "rg" {
  name     = "rg-acr-bundle-demo"
  location = "australiaeast"
  tags     = { env = "lab" }
}

############################
# Spoke VNets + PE subnets
############################
resource "azurerm_virtual_network" "spoke1" {
  name                = "vnet-spoke1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
  tags                = { env = "lab" }
}

resource "azurerm_subnet" "spoke1_pl" {
  name                 = "snet-privatelink"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = ["10.10.1.0/24"]
  # Intentionally not setting private_endpoint_network_policies_* here; defaults are fine for PE.
}

resource "azurerm_virtual_network" "spoke2" {
  name                = "vnet-spoke2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.20.0.0/16"]
  tags                = { env = "lab" }
}

resource "azurerm_subnet" "spoke2_pl" {
  name                 = "snet-privatelink"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = ["10.20.1.0/24"]
}

############################
# Private DNS zone + VNet links
############################
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = { env = "lab" }
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke1" {
  name                  = "link-spoke1"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.spoke1.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke2" {
  name                  = "link-spoke2"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.spoke2.id
  registration_enabled  = false
}

############################
# ACR + (N) Private Endpoints (bundled module)
############################
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  numeric = true
  special = false
}

module "acr_bundle" {
  # Point this to the Azure Container Registry module
  source = "./modules/azure_container_registry"

  name                = "labacr${random_string.suffix.result}" # must be globally unique
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # Module enforces Premium SKU and secure defaults automatically
  # No need to specify sku, public_network_access_enabled, or admin_enabled

  # Private endpoints with corporate naming conventions and static IPs
  private_endpoints = {
    "lab-acr-pe-spoke1" = {
      subnet_id          = azurerm_subnet.spoke1_pl.id
      private_ip_address = "10.10.1.10"  # Static IP within spoke1 subnet (10.10.1.0/24)
    }
    "lab-acr-pe-spoke2" = {
      subnet_id          = azurerm_subnet.spoke2_pl.id
    }
  }

  # Note: DNS zone linking handled externally
  # The azurerm_private_dns_zone.acr and links are for demonstration

  tags = { env = "lab" }
}

############################
# Outputs
############################
output "acr_login_server" {
  value       = module.acr_bundle.login_server
  description = "e.g., labacrXXXXX.azurecr.io"
}

output "acr_id" {
  value = module.acr_bundle.acr_id
}

output "private_endpoint_ids" {
  value = module.acr_bundle.private_endpoint_ids
}

output "private_endpoint_private_ips" {
  value = module.acr_bundle.private_endpoint_private_ips
}

output "private_endpoint_details" {
  value = module.acr_bundle.private_endpoint_details
}
