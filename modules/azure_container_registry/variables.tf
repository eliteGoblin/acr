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
    - private_ip_address: Reserved for future use (static IP assignment requires additional networking configuration)
    - subresource_names: List of ACR subresources to connect to (default: ["registry"])
    - manual_connection: Whether the connection requires manual approval (default: false)
    
    Example:
    ```
    private_endpoints = {
      "corp-prod-acr-pe-001" = {
        subnet_id          = "/subscriptions/.../subnets/pe-subnet"
        # private_ip_address = "10.1.1.100"  # Reserved for future use
      }
      "corp-prod-acr-pe-002" = {
        subnet_id         = "/subscriptions/.../subnets/pe-subnet-2"
        subresource_names = ["registry"]
        manual_connection = false
      }
    }
    ```
    
    Note: DNS zone management is out of scope for this module.
  EOT
  type = map(object({
    subnet_id          = string
    private_ip_address = optional(string, null)
    subresource_names  = optional(list(string), ["registry"])
    manual_connection  = optional(bool, false)
  }))

  validation {
    condition     = length(var.private_endpoints) > 0
    error_message = "At least one private endpoint must be configured for secure ACR access."
  }

  validation {
    condition = alltrue([
      for pe in var.private_endpoints : alltrue([
        for subresource in pe.subresource_names : contains(["registry", "data"], subresource)
      ])
    ])
    error_message = "Private endpoint subresource_names must only contain 'registry' and/or 'data'."
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