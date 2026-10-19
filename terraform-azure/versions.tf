
terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name  = "cartflow-rg"
    storage_account_name = "cartflowtfstate2026"
    container_name       = "tfstate"
    key                  = "cartflow-terraform.tfstate"

    use_azuread_auth = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}