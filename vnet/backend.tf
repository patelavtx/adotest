terraform {
  backend "azurerm" {
    resource_group_name  = "attila932"
    storage_account_name = "attila932"
    container_name       = "terraform-state"
    key                  = "ado.terraform.tfstate"
  }
}


#Populate from the storage created from 'azurestorage.tf' which uses sas token, but not needed as svc conn SP added.
