provider "azurerm" {
  features {
  }
  subscription_id            = "194a41a1-5592-4d4f-a8db-9eba93938aa2"
  environment                = "public"
  use_msi                    = false
  use_cli                    = true
  use_oidc                   = false
  skip_provider_registration = true
}
