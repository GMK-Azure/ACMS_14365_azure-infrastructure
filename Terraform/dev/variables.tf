variable "rg_context" {
  type = object({
    asms                = string
    location            = string
    environment         = string
    tags                = optional(map(string))
    new_resource_group = object({
      suffix = optional(string)
      tags   = optional(map(string))
    })
  })
  description = "Object containing the resource group properties"
}

variable "vnet_pattern" {
  type = object({
    suffix         = string
    hub_identifier = string
    address_prefix = list(string)
    subnets = map(object({
      address_prefix = string
      delegations = optional(list(object({
        name = string
        properties = object({
          serviceName = string
        })
      })))
      service_endpoints = optional(list(object({
        locations = list(string)
        service   = string
      })))
    }))
  })
  description = <<EOT
    Details about the Virtual Network to create.
      suffix                    - Suffix to append to the end of the Virtual Network resource name and related resources.
      hub_identifier            - Hub to peer to the Virtual Network. Possible values are listed here: https://github.com/GM-InnerSource/terraform-generic-networking-config/blob/main/docs/General%20Motors/peering.md
      address_prefix            - IP address range(s) to use for the Virtual Network.
      subnets.address_prefix    - IP address range to use for the subnet.
      subnets.delegations       - List of delegations to assign to the subnet. properties.serviceName is formatted as Microsoft.Provider/resourceType.
      subnets.service_endpoints - List of service endpoints to assign to the subnet. service is formatted as Microsoft.resourceType.
  EOT
}

variable "app_services" {
  type = map(object({
    runtime_stack                   = string
    runtime_stack_version           = string
    hostname                        = string
    }))
  description = <<EOT
    Details about the App Services to deploy. Each key in the map represents the suffix of the App Service.
      runtime_stack         - Stack that the App Service will run: dotnet, dotnetcore*, go, java, java_server^, node, php, python, ruby^ (^ Linux only | * Windows only).
      runtime_stack_version - Version of the runtime stack.
      hostname              - The desired subdomain for the App Service.
  EOT
}

variable "service_plan" {
  type = object({
    asp_suffix = string
  })
  description = <<EOT
    Details about the App Service Plan to create.
      asp_suffix - Suffix to append to the end of the App Service Plan resource name.
  EOT
}

variable "postgres" {
  type = object({
    suffix      = optional(string, null)
    create_mode = string
    databases   = list(string)
  })
  description = <<EOF
    postgres {
      suffix      = Suffix to be added on to the resources provisioned within the postgres module (Optional)
      create_mode = The create mode for the postgres server (Required)
      databases   = The list of databases to create on the postgres server (Required)
    }
  EOF
}

variable "storage_account" {
  type = object({
    suffix      = string
    access_tier = string
    containers = optional(map(object({
      container_access_type             = optional(string)
      default_encryption_scope          = optional(string)
      encryption_scope_override_enabled = optional(bool)
      metadata                          = optional(map(string))
    })), null)
  })
  description = "Object containing the storage account properties"
}

variable "servicebus_suffix" {
  type        = string
  description = "Suffix to use for the service BUS name."
  default     = null
}

variable "application_gateway" {
  type        = object({
    suffix = string
  })
  description = "suffix - Suffix to append to the end of the Application Gateway resource name."
}

# These variables containing CERTIFICATE_* will be set within the TFC runs as the variables are defined within the workspace on TFC.
variable "CERTIFICATE_ISSUER_NAME" {
  type        = string
  description = "Name of the Key Vault Certificate Issuer."
}

variable "CERTIFICATE_PROVIDER_NAME" {
  type        = string
  description = "Name of the third-party Certificate Issuer."
}

variable "CERTIFICATE_ISSUER_ORG_ID" {
  type        = string
  description = "ID of the organization as provided to the issuer."
}

variable "CERTIFICATE_ISSUER_ACCOUNT_ID" {
  type        = string
  description = "ID of the account number with the third-party Certificate Issuer."
}

variable "CERTIFICATE_ISSUER_PASSWORD" {
  type        = string
  description = "Password associated with the account and organization ID at the third-party Certificate Issuer."
  sensitive   = true
}