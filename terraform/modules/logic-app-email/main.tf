terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

# 1. Get the Managed API for Office 365
data "azurerm_managed_api" "office365" {
  name     = "office365"
  location = var.location
}

# 2. Create the API Connection
resource "azurerm_api_connection" "office365" {
  name                = "office365-connection"
  resource_group_name = var.resource_group_name
  managed_api_id      = data.azurerm_managed_api.office365.id
  display_name        = "Office 365 Connection"
  tags                = var.tags
}

resource "azurerm_logic_app_workflow" "workflow" {
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # 3. Define the Parameters to link the Connection
  parameters = {
    "$connections" = jsonencode({
      office365 = {
        connectionId   = azurerm_api_connection.office365.id
        connectionName = azurerm_api_connection.office365.name
        id             = data.azurerm_managed_api.office365.id
      }
    })
  }
}

resource "azurerm_logic_app_trigger_http_request" "trigger" {
  name         = "webhook-trigger"
  logic_app_id = azurerm_logic_app_workflow.workflow.id

  schema = <<SCHEMA
{
    "type": "object",
    "properties": {
        "to_address": {
            "type": "string"
        },
        "subject": {
            "type": "string"
        },
        "content": {
            "type": "string"
        }
    }
}
SCHEMA
}

resource "azurerm_logic_app_action_custom" "send_email" {
  name         = "send-email"
  logic_app_id = azurerm_logic_app_workflow.workflow.id

  body = <<BODY
{
    "description": "Send an email",
    "inputs": {
        "body": {
            "Body": "@{triggerBody()?['content']}",
            "Subject": "@{triggerBody()?['subject']}",
            "To": "@{triggerBody()?['to_address']}"
        },
        "host": {
            "connection": {
                "name": "@parameters('$connections')['office365']['connectionId']"
            }
        },
        "method": "post",
        "path": "/v2/Mail"
    },
    "runAfter": {},
    "type": "ApiConnection"
}
BODY
}
