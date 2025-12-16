rg_context = {
  asms = "14365"
  environment = "d1"
  location = "koreacentral"
  new_resource_group = {
    suffix = "dev"
  }
}

vnet_pattern = {
  suffix = "dev"
  hub_identifier = "hubspoke.corp.koreacentral.dt1"
  address_prefix = ["100.84.64.64/26"]
  subnets = {
    serverfarm = {
      address_prefix = "100.84.64.64/27"
    },
    pe = {
      address_prefix = "100.84.64.96/28"
      service_endpoints = [
        {
          locations = ["koreacentral"]
          service   = "Microsoft.Storage"
        },
        {
          locations = ["*"],
          service   = "Microsoft.KeyVault"
        }
      ]
    },
    agw_public = {
      address_prefix = "100.84.64.112/28"
    }
  }
}

app_services = {
  "acms-api" = {
    runtime_stack  = "dotnet",
    runtime_stack_version = "8.0",
    hostname = "acms-api"
  },
  "acms-ui" = {
    runtime_stack  = "node",
    runtime_stack_version = "20-lts",
    hostname = "acms-ui"
  }
}

service_plan = {
  asp_suffix = "dev"
}

postgres = {
  suffix      = "dev"
  create_mode = "Default"
  databases = ["acms-d1-db"]
}

storage_account = {
  suffix      = "dev"
  access_tier = "Hot"
  containers = {
    "private-assets" = {
      container_access_type = "private"
    }
  }
}

servicebus_suffix = "dev"

application_gateway = {
  suffix = "dev"
}
