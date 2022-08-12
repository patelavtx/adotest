terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.2.2"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.17"

    }

    azuread = {
      source = "hashicorp/azuread"
      version = ">=2.27.0"
    }

  }
  /*
  backend "remote" {
    organization = "attilapipeline"

    workspaces {
      name = "tt-pipelines"
    }
  }
*/

  backend "azurerm" {
    resource_group_name  = "atulrg-adotest"
    storage_account_name = "adotest"
    container_name       = "adoctr"
    key                  = "adotest.terraform.tfstate"
  }
}