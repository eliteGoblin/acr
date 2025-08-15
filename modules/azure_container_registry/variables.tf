##############################################################################
# Required Variables
##############################################################################

variable "name" {
  description = "The name of the Azure Container Registry. Must be globally unique and contain only alphanumeric characters."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR name must be 5-50 characters long and contain only alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the ACR and associated resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the ACR and private endpoints will be created."
  type        = string
}

##############################################################################
# Private Endpoints Configuration
##############################################################################

variable "private_endpoints" {
  description = <<-EOT
    Map of private endpoints to create for the ACR. The map key becomes the private endpoint name,
    allowing you to use your corporate naming conventions. Each private endpoint requires:
    - subnet_id: The ID of the subnet where the private endpoint will be created
    - resource_group_name: The resource group where the private endpoint will be created (should match subnet's RG)
    - private_ip_address: Optional static IP assignment within the subnet range
    - manual_connection: Whether the connection requires manual approval (default: false)
    
    Example:
    ```
    private_endpoints = {
      "corp-prod-acr-pe-001" = {
        subnet_id           = "/subscriptions/.../subnets/pe-subnet"
        resource_group_name = "rg-network-prod"
        private_ip_address  = "10.1.1.100"  # Optional
      }
      "corp-prod-acr-pe-002" = {
        subnet_id           = "/subscriptions/.../subnets/pe-subnet-2" 
        resource_group_name = "rg-network-prod"
        manual_connection   = false
      }
    }
    ```
    
    Note: 
    - Private endpoints are always configured for ACR "registry" subresource
    - DNS zone management is out of scope for this module
  EOT
  type = map(object({
    subnet_id           = string
    resource_group_name = string
    private_ip_address  = optional(string, null)
    manual_connection   = optional(bool, false)
  }))

  validation {
    condition     = length(var.private_endpoints) > 0
    error_message = "At least one private endpoint must be configured for secure ACR access."
  }

  validation {
    condition = alltrue([
      for pe in var.private_endpoints :
      pe.private_ip_address == null || can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", pe.private_ip_address))
    ])
    error_message = "private_ip_address must be a valid IPv4 address when specified."
  }
}

##############################################################################
# Optional Variables
##############################################################################

variable "tags" {
  description = "A map of tags to assign to all resources created by this module."
  type        = map(string)
  default     = {}
}