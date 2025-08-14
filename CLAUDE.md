# Azure Container Registry Module - Requirements & Implementation

## Overview

This document outlines the requirements and implementation details for the Azure Container Registry Terraform module. This module creates a secure Azure Container Registry with private endpoints following enterprise security practices.

## Requirements Summary

### Core Requirements
- **Security First**: Premium SKU, public access disabled, admin user disabled
- **Private Endpoint Focus**: Module is focused solely on ACR + Private Endpoints
- **Corporate Naming**: Users provide custom private endpoint names for corporate compliance
- **Network Control**: Optional private IP address specification for corporate DNS control
- **DNS Out of Scope**: No DNS zone or VNet link management - external responsibility

### Updated Requirements (Latest)

#### ✅ Implemented
1. **No DNS Zone Management** - Module does not create or manage private DNS zones
2. **No VNet Link Management** - DNS linking is out of scope for this module
3. **Security by Default** - All security settings hardcoded (Premium SKU, no public access, no admin)
4. **Module Structure** - Follows Azure Terraform module conventions

#### 🔄 New Requirements to Implement
1. **Custom Private Endpoint Names** - Users must provide specific PE names per corporate naming conventions
2. **Optional Private IP Specification** - Allow users to specify static private IP addresses for private endpoints
3. **Simplified DNS Integration** - Remove all DNS zone variables and logic from module

## Module Interface

### Required Inputs
- `name` - ACR name (globally unique)
- `resource_group_name` - Target resource group
- `location` - Azure region
- `private_endpoints` - Map of private endpoint configurations with custom names and optional IPs

### Optional Inputs
- `tags` - Resource tags

### Outputs
- `acr_id` - ACR resource ID
- `acr_name` - ACR name
- `login_server` - ACR login server URL
- `private_endpoint_ids` - List of private endpoint IDs
- `private_endpoint_details` - Detailed PE information including assigned IPs

## Private Endpoint Configuration

### Updated Structure
```hcl
private_endpoints = {
  "my-custom-pe-name-1" = {
    subnet_id           = "/subscriptions/.../subnets/pe-subnet-1"
    private_ip_address  = "10.1.1.100"  # Optional: specify static IP
    subresource_names   = ["registry"]   # Default to ["registry"]
    manual_connection   = false          # Default to false
  }
  "my-custom-pe-name-2" = {
    subnet_id           = "/subscriptions/.../subnets/pe-subnet-2"
    # private_ip_address not specified - will use dynamic IP
    subresource_names   = ["registry"]
    manual_connection   = false
  }
}
```

## Implementation Changes Required

### 1. Remove DNS Zone Support
- Remove `private_dns_zone_ids` variable
- Remove all DNS zone group logic from private endpoints
- Remove DNS-related outputs
- Update documentation to clarify DNS is out of scope

### 2. Update Private Endpoint Configuration
- Add `private_ip_address` optional field to private endpoint configuration
- Use map keys as private endpoint names instead of generating names
- Simplify private endpoint resource configuration

### 3. Update Examples
- Remove DNS zone creation and linking from examples
- Show how to use custom PE names
- Demonstrate optional private IP assignment
- Update documentation to reflect simplified scope

## Corporate Use Case Alignment

### Naming Conventions
- **Problem**: Different corporations have different naming conventions
- **Solution**: Users provide exact private endpoint names via map keys
- **Example**: `"corp-prod-acr-pe-001"` instead of auto-generated names

### Network Control
- **Problem**: Corporate DNS and IP management is strictly controlled
- **Solution**: Optional private IP address specification for private endpoints
- **Benefit**: Allows integration with corporate IPAM systems

### DNS Management
- **Problem**: DNS zone management varies by corporate policy
- **Solution**: Remove DNS concerns from module entirely
- **Approach**: Users handle DNS zones and linking externally

## Security Model

### Hardcoded Security Settings
- `sku = "Premium"` (required for private endpoints)
- `admin_enabled = false` (security requirement)
- `public_network_access_enabled = false` (security requirement)

### Validation
- Ensure at least one private endpoint is configured
- Validate private IP addresses are valid IPv4 (if specified)
- Ensure subnet compatibility

## Migration Path

### For Existing Users
1. Remove `private_dns_zone_ids` from module calls
2. Update `private_endpoints` map to use custom names as keys
3. Optionally specify `private_ip_address` for static IP assignment
4. Handle DNS zone management external to module

### Example Migration
```hcl
# Before
private_endpoints = {
  spoke1 = {
    subnet_id = "/subscriptions/.../subnets/pe-subnet"
  }
}
private_dns_zone_ids = ["/subscriptions/.../privateDnsZones/privatelink.azurecr.io"]

# After  
private_endpoints = {
  "mycompany-prod-acr-pe-001" = {
    subnet_id          = "/subscriptions/.../subnets/pe-subnet"
    private_ip_address = "10.1.1.100"  # Optional
  }
}
# DNS zone management handled externally
```

## Success Criteria

### Module Simplification
- ✅ Remove all DNS zone related code
- ✅ Remove VNet link related code  
- ✅ Simplify private endpoint configuration
- ✅ Maintain security-first approach

### Corporate Requirements
- ✅ Support custom private endpoint names
- ✅ Support optional static private IP assignment
- ✅ Clear separation of concerns (ACR + PE only)
- ✅ Enterprise-friendly configuration

### Documentation
- ✅ Update README with simplified scope
- ✅ Update examples to show corporate use cases
- ✅ Clear migration guidance for existing users
- ✅ Emphasize DNS is out of scope

## Notes

- This module focuses solely on Azure Container Registry and Private Endpoints
- DNS zone management is intentionally out of scope for enterprise flexibility
- Corporate naming conventions are supported through user-provided PE names
- Network control is enhanced through optional static IP assignment
- Security settings are hardcoded and non-configurable for compliance