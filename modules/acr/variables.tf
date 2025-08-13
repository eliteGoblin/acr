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
    Map of private endpoints to create for the ACR. Each private endpoint requires:
    - subnet_id: The ID of the subnet where the private endpoint will be created
    - subresource_names: List of ACR subresources to connect to (default: ["registry"])
    - manual_connection: Whether the connection requires manual approval (default: false)
    
    Example:
    ```
    private_endpoints = {
      spoke1 = {
        subnet_id = "/subscriptions/.../subnets/pe-subnet"
      }
      spoke2 = {
        subnet_id         = "/subscriptions/.../subnets/pe-subnet-2"
        subresource_names = ["registry"]
        manual_connection = false
      }
    }
    ```
  EOT
  type = map(object({
    subnet_id         = string
    subresource_names = optional(list(string), ["registry"])
    manual_connection = optional(bool, false)
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
}

##############################################################################
# Optional Variables
##############################################################################

variable "private_dns_zone_ids" {
  description = <<-EOT
    List of existing Private DNS zone IDs to associate with the private endpoints.
    These zones should be pre-existing in your environment and linked to the appropriate VNets.
    Typically includes the privatelink.azurecr.io zone ID.
  EOT
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to all resources created by this module."
  type        = map(string)
  default     = {}
}