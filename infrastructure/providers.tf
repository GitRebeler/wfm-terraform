terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.4"

    }
  }
  backend "azurerm" {
    subscription_id      = "f784c856-2e5c-447e-a838-88cbe8650f5f"
    resource_group_name  = "mgt-dev-use-IAC-01-rg"
    storage_account_name = "mgtdevuse01sa"
    container_name       = "terraform"
    key                  = "dev.wfm.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
  }
  # subscription_id            = "194a41a1-5592-4d4f-a8db-9eba93938aa2"
  # environment                = "public"
  # use_msi                    = false
  # use_cli                    = true
  # use_oidc                   = false
  # skip_provider_registration = true
}
