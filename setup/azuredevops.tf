# Create ADO objects for pipeline

provider "azuredevops" {
  org_service_url = var.ado_org_service_url
  #personal_access_token = var.AZDO_PERSONAL_ACCESS_TOKEN 
}

# Create project.
resource "azuredevops_project" "project" {
  name               = local.ado_project_name
  description        = local.ado_project_description
  visibility         = local.ado_project_visibility
  version_control    = "Git"   # This will always be Git for me
  work_item_template = "Agile" # Not sure if this matters, check back later

  features = {
    # Only enable pipelines for now
    "testplans"    = "disabled"
    "artifacts"    = "disabled"
    "boards"       = "disabled"
    #"repositories" = "disabled"
    "repositories" = "enabled"   #added , but not needed as the GH repo is used and not AzDevOPs
    "pipelines"    = "enabled"
  }
}

# Service conn for azurerm 
resource "azuredevops_serviceendpoint_azurerm" "serviceendpoint_azurerm" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "atulavtx-sst2"
  description           = "Managed by Terraform"
  credentials {
    serviceprincipalid  = var.az_client_id
    serviceprincipalkey = var.az_client_secret
  }
  azurerm_spn_tenantid      = var.az_tenant
  azurerm_subscription_id   = var.az_subscription
  azurerm_subscription_name = "CSP-AVTX-apatel"
}

# GH conn - Check if ENV works ; but pull repo to project using GH pat
resource "azuredevops_serviceendpoint_github" "serviceendpoint_github" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "GH App: Azure Pipeline"    

  auth_personal {
    personal_access_token = var.ado_github_pat   #  doc suggests variable is AZDO_GITHUB_SERVICE_CONNECTION_PAT
  }
}

# Auth projects to use GH conn
resource "azuredevops_resource_authorization" "auth" {
  project_id  = azuredevops_project.project.id
  resource_id = azuredevops_serviceendpoint_github.serviceendpoint_github.id
  authorized  = true
}

# VG for pipeline, variables to use
resource "azuredevops_variable_group" "variablegroup" {
  project_id   = azuredevops_project.project.id
  name         = "adotest-vg"
  description  = "Variable group for pipelines"
  allow_access = true

  variable {
    name  = "storageaccount"
    value = azurerm_storage_account.sa.name
  }

  variable {
    name  = "container_name"
    value = var.az_container_name
  }

  variable {
    name  = "key"
    value = var.az_state_key
  }

  variable {
    name         = "sas_token"
    secret_value = data.azurerm_storage_account_sas.state.sas
    is_secret    = true
  }

  variable {
    name         = "az_client_id"
    secret_value = var.az_client_id
    is_secret    = true
  }

  variable {
    name         = "az_client_secret"
    secret_value = var.az_client_secret
    is_secret    = true
  }

  variable {
    name         = "az_subscription"
    secret_value = var.az_subscription
    is_secret    = true
  }

  variable {
    name         = "az_tenant"
    secret_value = var.az_tenant
    is_secret    = true
  }
}

# Create pipeline 
resource "azuredevops_build_definition" "pipeline_1" {

  depends_on = [azuredevops_resource_authorization.auth]
  project_id = azuredevops_project.project.id
  name       = local.ado_pipeline_name_1

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = var.ado_github_repo
    branch_name           = "main"
    yml_path              = var.ado_pipeline_yaml_path_1
    service_connection_id = azuredevops_serviceendpoint_github.serviceendpoint_github.id
  }

}

# Key Vault setup
## There needs to be a service connection to an Azure sub with the key vault
## https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/serviceendpoint_azurerm

# Key Vault task is here: https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-key-vault?view=azure-devops

