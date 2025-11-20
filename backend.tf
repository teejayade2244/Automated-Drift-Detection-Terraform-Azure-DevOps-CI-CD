terraform {
  backend "azurerm" {
    resource_group_name  = "Temitope"
    storage_account_name = "sttfstateorageacc"  
    container_name       = "tfstate"
    key                  = "drift-detection.tfstate"
  }
}