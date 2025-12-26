terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_logic_app_workflow" "workflow" {
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
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

# Note: Valid API connections for sending email (like Office 365) require OAuth consent
# which cannot be fully automated via Terraform.
# We define the action here assuming a connection 'office365' exists or placeholder.
# For this module to fully work, an API Connection must be created and authenticated manually
# or via a separate process, and its ID referenced here.
# Below is a conceptual definition using a standard Office 365 connection.

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
