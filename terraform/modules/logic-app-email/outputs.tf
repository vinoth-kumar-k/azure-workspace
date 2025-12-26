output "logic_app_id" {
  value = azurerm_logic_app_workflow.workflow.id
}

output "logic_app_callback_url" {
  value     = azurerm_logic_app_trigger_http_request.trigger.callback_url
  sensitive = true
}
