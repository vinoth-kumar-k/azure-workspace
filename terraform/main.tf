terraform {
  # Remote Backend Configuration
  # This block is empty to allow partial configuration.
  # Run 'terraform init -backend-config=...' to specify the Storage Account details.
  # It will inherit the authentication from 'az login' (Azure CLI).
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "cloud_shell_storage" {
  source = "./modules/cloud-shell-storage"

  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_name = var.storage_account_name
  file_share_name      = var.file_share_name
  source_file_path     = "${path.module}/scripts/cloud_shell_bashrc"
  tags                 = var.tags
}

module "logic_app_email" {
  source = "./modules/logic-app-email"
  count  = var.logic_app_enabled ? 1 : 0

  resource_group_name = var.resource_group_name
  location            = var.location
  logic_app_name      = "email-alert-logic-app"
  tags                = var.tags
}
