# Complete ACR Module Example

This example demonstrates a complete deployment of the Azure Container Registry module with private endpoints.

## Architecture

The example creates:

- **Resource Group**: Contains all resources
- **Networking**: 
  - 1 Hub VNet for centralized DNS
  - 2 Spoke VNets for private endpoints
  - Private endpoint subnets in each spoke
- **DNS**: Private DNS zone for ACR with VNet links
- **ACR**: Premium container registry with secure defaults
- **Private Endpoints**: 2 endpoints in different spokes

## Usage

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review the plan**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

4. **View outputs**:
   ```bash
   terraform output
   ```

## Features Demonstrated

- ✅ Secure ACR with Premium SKU
- ✅ Public access disabled
- ✅ Admin user disabled
- ✅ Multiple private endpoints
- ✅ Private DNS integration
- ✅ Comprehensive networking setup
- ✅ Proper tagging strategy

## Outputs

The example provides comprehensive outputs including:
- ACR details (name, ID, login server)
- Private endpoint information
- Network infrastructure IDs
- DNS configuration

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Security Notes

- ACR is configured with Premium SKU (required for private endpoints)
- Public network access is disabled
- Admin user is disabled for security
- All access is through private endpoints only
- Private DNS ensures proper name resolution