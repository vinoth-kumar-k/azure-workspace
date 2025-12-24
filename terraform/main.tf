terraform {
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
}
