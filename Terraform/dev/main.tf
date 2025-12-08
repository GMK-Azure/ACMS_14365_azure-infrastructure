# Resource Group
module "rg_context" {
  source      = "app.terraform.io/GM-CCoE-PROD/rg-context/azurerm"
  version     = "2.1.2"
  asms        = var.rg_context.asms
  location    = var.rg_context.location
  environment = var.rg_context.environment
  tags        = var.rg_context.tags
  new_resource_group = var.rg_context.new_resource_group
}

# removed {
# from = module.inf_key_vault
#   lifecycle {
#     destroy = false
#   }
# }

# Key Vault - Application
module "app_key_vault" {
  source     = "app.terraform.io/GM-CCoE-PROD/key-vault/azurerm"
  version    = "3.2.3"
  context    = module.rg_context.context
  suffix = "d01"
  vault_type = "app"

  private_network_config = {
    private_endpoint_subnet_id    = module.vnet_pattern.subnets["pe"].id
    application_security_group_id = module.vnet_pattern.application_security_groups["key_vault_app"].id
  }
}


# Key Vault - Infrastructure
module "inf_key_vault" {
  source     = "app.terraform.io/GM-CCoE-PROD/key-vault/azurerm"
  version    = "3.2.3"
  context    = module.rg_context.context
  suffix = "d01"
  vault_type = "inf"
  leveraged_resources = ["app_service"]


  certificate_issuer_config = {
    certificate_issuer_name          = var.CERTIFICATE_ISSUER_NAME
    certificate_issuer_provider_name = var.CERTIFICATE_PROVIDER_NAME
    certificate_issuer_org_id        = var.CERTIFICATE_ISSUER_ORG_ID
    certificate_issuer_account_id    = var.CERTIFICATE_ISSUER_ACCOUNT_ID
    certificate_issuer_password      = var.CERTIFICATE_ISSUER_PASSWORD
  }

  certificates = [
    for service in var.app_services : {
      hostname = service.hostname
    }
  ]

  private_network_config = {
    private_endpoint_subnet_id    = module.vnet_pattern.subnets["pe"].id
    application_security_group_id = module.vnet_pattern.application_security_groups["key_vault_inf"].id
  }

  network_acls_virtual_network_subnet_ids = [module.vnet_pattern.subnets["agw_public"].id, module.vnet_pattern.subnets["pe"].id]
}


#Virtual Network
module "vnet_pattern" {
  source  = "git@github.com:GM-InnerSource/terraform-azurerm-virtual-network-pattern.git?ref=feature%2Fkorea-central-network"
  providers = {
    azurerm                      = azurerm
    azurerm.network_subscription = azurerm.network_subscription
  }
  context        = module.rg_context.context
  suffix         = var.vnet_pattern.suffix
  hub_identifier = var.vnet_pattern.hub_identifier
  vnet = {
    address_space               = var.vnet_pattern.address_prefix
    application_security_groups = ["app_service", "key_vault_app", "key_vault_inf", "postgres", "storage", "redis", "servicebus"]
    subnets                     = var.vnet_pattern.subnets
  }
}

#App Service
module "app_service" {
  source  = "app.terraform.io/GM-CCoE-PROD/app-service/azurerm"
  version = "4.2.2"
  for_each = var.app_services
  providers = {
    azurerm                      = azurerm
    azurerm.network_subscription = azurerm.network_subscription
  }
  context               = module.rg_context.context
  suffix                = each.key
  runtime_stack         = each.value.runtime_stack
  runtime_stack_version = each.value.runtime_stack_version
  os_type               = module.service_plan.service_plan_os_type
  private_network_config = {
    resource_subnet_id            = module.vnet_pattern.subnets["serverfarm"].id
    private_endpoint_subnet_id    = module.vnet_pattern.subnets["pe"].id
    application_security_group_id = module.vnet_pattern.application_security_groups["app_service"].id
  }
  app_service_plan_id = module.service_plan.service_plan_id
}

#App Service Plan
module "service_plan" {
  source     = "app.terraform.io/GM-CCoE-PROD/service-plan/azurerm"
  version    = "3.1.1"
  context    = module.rg_context.context
  asp_suffix = var.service_plan.asp_suffix
}


# Postgres Flexible Server
module "postgres" {
  source      = "app.terraform.io/GM-CCoE-PROD/postgresql-flexible-server/azurerm"
  version     = "2.2.0"
  context     = module.rg_context.context
  suffix      = var.postgres.suffix
  create_mode = var.postgres.create_mode
  # databases   = var.postgres.databases
  # NOTE: Databases are no longer created through Terraform. For more information, see the post provisioning guide, which needs to be run after your schema is created.
  # https://github.com/GM-InnerSource/terraform-azurerm-postgresql-flexible-server/blob/main/README.md
  app_key_vault_id                       = module.app_key_vault.id
  postgres_application_security_group_id = module.vnet_pattern.application_security_groups["postgres"].id
  private_endpoint_subnet_id             = module.vnet_pattern.subnets["pe"].id
}

#Storage Account
module "storage_account" {
  source      = "app.terraform.io/GM-CCoE-PROD/storage-account/azurerm"
  version     = "3.9.0"
  is_hns_enabled  =true
  sftp_enabled     =true
  context     = module.rg_context.context
  suffix      = var.storage_account.suffix
  access_tier = var.storage_account.access_tier
  containers  = var.storage_account.containers

  public_network_access_enabled = true
  private_network_config = {
    application_security_group_id = module.vnet_pattern.application_security_groups["storage"].id
    private_endpoint_subnet_id    = module.vnet_pattern.subnets["pe"].id
  }
}

# Redis cache
module "redis_cache" {
  source  = "app.terraform.io/GM-CCoE-PROD/redis-cache/azurerm"
  version = "1.1.0"
  context = module.rg_context.context
  redis_version       = "6"
  authentication_type = "access_key"
  private_network_config = {
    application_security_group_id = module.vnet_pattern.application_security_groups["redis"].id
    private_endpoint_subnet_id    = module.vnet_pattern.subnets["pe"].id
  }
}

# Azure Service Bus
module "servicebus_namespace" {
  source  = "git@github.com:GM-InnerSource/terraform-azurerm-servicebus.git?ref=1.0.0"
  context = module.rg_context.context
  suffix  = var.servicebus_suffix
  servicebus_namespace = {
    sku                          = "Premium" # allowed SKU values: 'Premium' , 'Standard', or 'Basic' .
    capacity                     = 1         # For 'Premium' SKU, 'capacity' must be one of [1, 2, 4, 8, 16]. For 'Basic' or 'Standard' SKUs, 'capacity' must be 0.
    premium_messaging_partitions = 1         # For 'Premium' SKU, 'premium_messaging_partitions' must be one of [1, 2, 4]. For 'Basic' or 'Standard' SKUs, 'premium_messaging_partitions' must be 0.
  }
  # private endpoint only supported for 'Premium' SKU
  private_network_config = {
    private_endpoint_subnet_id    = module.vnet_pattern.subnets["pe"].id
    application_security_group_id = module.vnet_pattern.application_security_groups["servicebus"].id
  }

  servicebus_queues = [{
    name = "email-queue"
  }, {
    name = "eval-universe-queue"
  }]

  # Topics & subscriptions only supported for 'Premium' and 'Standard'  SKUs
  # servicebus_topics = [
  #   {
  #     name = "t1"
  #     subscription = [
  #       {
  #         name = "sub1"
  #       }
  #     ]
  #   }
  # ]
}

# Application Gateway
module "application_gateway" {
  source  = "git@github.com:GM-InnerSource/terraform-azurerm-application-gateway.git?ref=feature%2Fkorea-central-network"
  providers = {
    azurerm                      = azurerm
    azurerm.network_subscription = azurerm.network_subscription
  }

  context = module.rg_context.context
  suffix  = var.application_gateway.suffix

  hub_identifier = var.vnet_pattern.hub_identifier
  public_ip_id   = module.vnet_pattern.public_ips["agw_public"].id

  virtual_network_id = module.vnet_pattern.id

  agw_subnet = {
    id             = module.vnet_pattern.subnets["agw_public"].id
    address_prefix = var.vnet_pattern.subnets["agw_public"].address_prefix
  }

  frontend_ip_configuration = "public"

  # map key value should be the same as the name of the application, map key will match between the backend_properties, frontend_properties and request routing rules.
  backend_properties = merge(
    {
      for app_name, app_config in var.app_services :
      "${app_name}-public" => {
        backend_http_settings = {
          host_name = module.app_service[app_name].app_default_hostname
        }
        probe = {
          pick_host_name_from_backend_http_settings = true
        }
      }
  })

  frontend_properties = merge(
    {
      for app_name, app_config in var.app_services :
      "${app_name}-public" => {
        hostname      = app_config.hostname
        listener_type = "public"
        tls_certificate = {
          keyvault_name         = module.inf_key_vault.name
          keyvault_id           = module.inf_key_vault.id
          versionless_secret_id = module.inf_key_vault.certificates[app_config.hostname]["versionless_secret_id"]
        }
      }
    }
  )

  backend_address_pools = {
    for app_name, app_config in var.app_services :
    "${app_name}-backend-pool" => {
      fqdns = [module.app_service[app_name].app_default_hostname]
    }
  }

  # override otherwise use defaults
  request_routing_rules = merge(
    {
      for app_name, app_config in var.app_services :
      "${app_name}-public" => {
        backend_address_pool_name = "${app_name}-backend-pool"
        backend_properties_name   = "${app_name}-public"
        frontend_properties_name  = "${app_name}-public"
      }
    }
  )

  # Default owasp rule group override
  # These rules are set in place to allow browsers that hit the endpoints through the AGW with GM cookies
  # (the cookies used follow a pattern of the 'REQUEST-942-APPLICATION-ATTACK-SQLI' rules that will block requests)
  owasp_rule_group_override = [
    {
      rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
      rules = [
        {
          id      = "942430"
          enabled = false
        },
        {
          id      = "942440"
          enabled = false
        },
        {
          id      = "942450"
          enabled = false
        }
      ]
    }
  ]
}
