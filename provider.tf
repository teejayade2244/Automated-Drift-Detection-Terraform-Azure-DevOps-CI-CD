terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.52.0"
    }
  }
}


provider "azurerm" {
  features {}
  subscription_id = "56ff181a-280b-469d-95a9-0fdd3fc839e0"
}
