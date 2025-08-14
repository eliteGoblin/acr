# Azure Container Registry with Private Endpoints Module

A Terraform module that creates a secure Azure Container Registry (ACR) with private endpoints, following security best practices with Premium SKU and disabled public access.

## Features

- ✅ **Premium SKU** - Required for private endpoints
- ✅ **Security by Default** - Public access and admin user disabled
- ✅ **Private Endpoints** - Secure network access only
- ✅ **Private DNS Integration** - Support for existing DNS zones
- ✅ **Validation** - Built-in security and configuration validation
- ✅ **Comprehensive Outputs** - Detailed resource information

## Usage

### Basic Example

```hcl
module "acr" {
  source = "./modules/azure_container_registry"

  name                = "myacrregistry"
  resource_group_name = "my-resource-group"
  location            = "East US"

  private_endpoints = {
    "corp-prod-acr-pe-001" = {
      subnet_id          = "/subscriptions/.../subnets/pe-subnet"
      private_ip_address = "10.1.1.100"  # Optional: specify static IP
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Advanced Example

```hcl
module "acr" {
  source = "./modules/azure_container_registry"

  name                = "myacrregistry"
  resource_group_name = "my-resource-group" 
  location            = "East US"

  private_endpoints = {
    "corp-prod-acr-pe-001" = {
      subnet_id          = "/subscriptions/.../subnets/pe-subnet-1"
      private_ip_address = "10.1.1.100"  # Optional: specify static IP
      subresource_names  = ["registry"]
      manual_connection  = false
    }
    "corp-prod-acr-pe-002" = {
      subnet_id         = "/subscriptions/.../subnets/pe-subnet-2"
      subresource_names = ["registry"]
      # Dynamic IP assignment for this endpoint
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-app"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.0 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the Azure Container Registry. Must be globally unique and contain only alphanumeric characters. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the ACR and associated resources. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The Azure region where the ACR and private endpoints will be created. | `string` | n/a | yes |
| <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints) | Map of private endpoints to create for the ACR. Each private endpoint requires subnet_id, and optionally subresource_names and manual_connection. | `map(object({...}))` | n/a | yes |
| <a name="input_private_dns_zone_ids"></a> [private\_dns\_zone\_ids](#input\_private\_dns\_zone\_ids) | List of existing Private DNS zone IDs to associate with the private endpoints. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to all resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acr_id"></a> [acr\_id](#output\_acr\_id) | The resource ID of the Azure Container Registry. |
| <a name="output_acr_name"></a> [acr\_name](#output\_acr\_name) | The name of the Azure Container Registry. |
| <a name="output_login_server"></a> [login\_server](#output\_login\_server) | The login server URL of the Azure Container Registry. |
| <a name="output_private_endpoint_ids"></a> [private\_endpoint\_ids](#output\_private\_endpoint\_ids) | List of resource IDs for all created private endpoints. |
| <a name="output_private_endpoint_private_ips"></a> [private\_endpoint\_private\_ips](#output\_private\_endpoint\_private\_ips) | Map of private endpoint names to their assigned private IP addresses. |
| <a name="output_private_endpoint_details"></a> [private\_endpoint\_details](#output\_private\_endpoint\_details) | Detailed information about each private endpoint including IDs, names, IPs, and configurations. |
| <a name="output_private_endpoint_fqdns"></a> [private\_endpoint\_fqdns](#output\_private\_endpoint\_fqdns) | Map of private endpoint names to their fully qualified domain names from DNS zone configurations. |

## Security Configuration

This module enforces security best practices:

- **Premium SKU**: Always uses Premium SKU (required for private endpoints)
- **No Public Access**: Public network access is disabled
- **No Admin User**: Admin user is disabled for security
- **Private Access Only**: All access is through private endpoints
- **Validation**: Built-in validation ensures security compliance

## Module Scope

This module focuses solely on Azure Container Registry and Private Endpoints:

- **DNS Management**: Out of scope - users handle DNS zones and linking externally
- **Custom Naming**: Private endpoint names provided by users for corporate compliance
- **Network Control**: Optional static IP assignment for corporate DNS/IPAM integration
- **Security First**: All security settings are hardcoded and non-configurable

## Examples

See the [examples](./examples/) directory for complete working examples.

## Contributing

1. Ensure all examples work correctly
2. Run CI pipeline: `./scripts/ci.sh`
3. Update documentation as needed
