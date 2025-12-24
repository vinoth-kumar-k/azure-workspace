resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "share" {
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 6 # 6GB quota, Cloud Shell usually asks for 5GB minimum.
}

resource "azurerm_storage_share_file" "bashrc" {
  name             = ".bashrc"
  storage_share_id = azurerm_storage_share.share.id
  source           = var.source_file_path
}
