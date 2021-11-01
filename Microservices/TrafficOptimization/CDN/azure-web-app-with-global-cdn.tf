
## -----------------------------------------------------------------------------##
# This script allows provisioning a GREEN infrastructure on the Cloud Azure
# For more details, refer to Microsoft documentation.
## -----------------------------------------------------------------------------##

# Configure the Azure provider
provider "azurerm" {
  version         = ">=2.46.1"
  tenant_id       = var.tenant
  subscription_id = var.subscription
  client_id       = var.client_id
  client_secret   = var.client_secret
  features {} #This is required for v2 of the provider even if empty or plan will fail
}

# -------------------------------------------------------------------
## The variables below are read from environment variables exported on the pipeline
# -------------------------------------------------------------------
variable "tenant" {
  type = string
}
variable "subscription" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}
variable "container_registry_admin_pwd" {
  type = string
}

locals {
  location             = "northeurope"
  app_name             = "green-app-front"
  acr_repo_app_name    = "athanor-app-front"
  storage_account_name = "greenhacene"
  environment_tag      = "dev"
  application_tag      = "GREEN_APP"

  # THE ACR IS CREATED MANUALLY, BETTER TO USE THE SAME FOR ALL ENVIRONMENTS
  container_registry_name         = "acrathanordevfr001"
  container_registry_login_server = "acrathanordevfr001.azurecr.io"
}

resource "azurerm_resource_group" "rg_green_front_fr_001" {
  name     = "rg-green-front-${local.environment_tag}-fr-001"
  location = local.location
}

## -----------------------------------------------------------------------------##
# App service plan configuration to deploy/run docker images pushed to the
# ACR (Azure Container Registry)
## -----------------------------------------------------------------------------##

resource "azurerm_app_service_plan" "greenAppServicePlan" {
  name                = "appservice-plan-green-front-${local.environment_tag}-fr-001"
  location            = azurerm_resource_group.rg_green_front_fr_001.location
  resource_group_name = azurerm_resource_group.rg_green_front_fr_001.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }

  tags = {
    environment = local.environment_tag
    application = local.application_tag
  }
}

resource "azurerm_app_service" "greenAppService" {
  name                = "green-front-${local.environment_tag}-fr-001"
  location            = azurerm_resource_group.rg_green_front_fr_001.location
  resource_group_name = azurerm_resource_group.rg_green_front_fr_001.name
  app_service_plan_id = azurerm_app_service_plan.greenAppServicePlan.id

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false

    # Settings for private Container Registries
    DOCKER_REGISTRY_SERVER_URL      = "https://${local.container_registry_login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME = local.container_registry_name
    DOCKER_REGISTRY_SERVER_PASSWORD = var.container_registry_admin_pwd

  }

  # Setup connection with azure container registry for image pulling
  site_config {
    app_command_line = ""
    linux_fx_version = "DOCKER|${local.container_registry_name}.azurecr.io/${local.acr_repo_app_name}:latest"
    always_on        = "true"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    cdn         = local.environment_tag
    environment = local.environment_tag
    application = local.application_tag
  }
}

resource "azurerm_cdn_profile" "cdnGreenApp" {
  name                = "cdn-profile-app-green-dev-001"
  location            = azurerm_resource_group.rg_green_front_fr_001.location
  resource_group_name = azurerm_resource_group.rg_green_front_fr_001.name
  sku                 = "Standard_Verizon"
}

resource "azurerm_cdn_endpoint" "cdnGreenAppEndpoint" {
  depends_on = [
    azurerm_app_service.greenAppService
  ]
  name                = "cdn-endpoint-app-green-dev-001"
  profile_name        = azurerm_cdn_profile.cdnGreenApp.name
  location            = azurerm_resource_group.rg_green_front_fr_001.location
  resource_group_name = azurerm_resource_group.rg_green_front_fr_001.name
  optimization_type   = "GeneralWebDelivery"
  origin_host_header  = "${azurerm_app_service.greenAppService.name}.azurewebsites.net"

  origin {
    http_port  = "80"
    https_port = "443"
    name       = "greenAppFrontend"
    host_name  = "${azurerm_app_service.greenAppService.name}.azurewebsites.net"
  }
}

