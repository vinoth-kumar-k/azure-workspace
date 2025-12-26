output "resource_group_name" {
  description = "The name of the resource group"
  value       = var.resource_group_name
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = var.storage_account_name
}

output "logic_app_callback_url" {
  description = "The HTTP Trigger callback URL for the Logic App (if enabled)"
  value       = var.logic_app_enabled ? module.logic_app_email[0].logic_app_callback_url : null
  sensitive   = true
}
