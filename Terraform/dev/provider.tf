terraform {
  # Uncomment cloud{} if you are using one of the GitHub workflow templates with a cli driven workspace
  # cloud {}

  required_version = "~> 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
   features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  storage_use_azuread = true
}

provider "azurerm" {
  features {}
  alias                           = "network_subscription"
  subscription_id                 = "e06b3992-dbb3-45e8-bd7a-b8b557bb8c94"
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}

provider "azapi" {
  use_msi = true
}
