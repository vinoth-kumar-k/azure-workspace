# Azure Workspace - Cloud Shell Setup

This repository contains Terraform code to provision the persistent storage required for Azure Cloud Shell (Bash) and configures a custom development environment with useful aliases and tools.

## Overview

Azure Cloud Shell uses an Azure Storage File Share to persist your `$HOME` directory. This project automates the creation of that infrastructure and uploads a custom `.bashrc` configuration script to the file share.

**Features:**
*   **Infrastructure as Code:** Provisions Resource Group, Storage Account, and File Share using Terraform.
*   **Custom Bash Environment:**
    *   **Aliases:** `c` (clear), `k` (kubectl), `ll` (ls -alF), `grep` (colorized).
    *   **Functions:** `kset-ns <namespace>` (alias `kset-ns`) to easily switch Kubernetes namespaces.
    *   **Tools:** Automatic installation of:
        *   `yq` (YAML processor)
        *   `fzf` (Fuzzy Finder)
        *   `kubectx` & `kubens` (Kubernetes context/namespace switchers)
*   **Logic App Alerting (Optional):** Includes a module to provision a Logic App for sending email alerts via Webhook.

## Prerequisites

*   [Terraform](https://www.terraform.io/downloads.html) installed (v1.0+).
*   [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated (`az login`).

## Deployment

1.  **Navigate to the Terraform directory:**
    ```bash
    cd terraform
    ```

2.  **Initialize Terraform:**

    *   **Local State:**
        ```bash
        terraform init
        ```

    *   **Remote State (Azure Blob Storage):**
        If you wish to store the Terraform state remotely in Azure Blob Storage, use the following command (requires an existing Storage Account and Container). This uses your current Azure CLI login credentials.

        ```bash
        terraform init \
          -backend-config="resource_group_name=<resource_group_name>" \
          -backend-config="storage_account_name=<storage_account_name>" \
          -backend-config="container_name=<container_name>" \
          -backend-config="key=terraform.tfstate"
        ```

3.  **Configure Variables:**
    Copy the example variable file and update it with your desired settings (unique storage account name, region, etc.).
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars
    ```

    **Optional Logic App:**
    To enable the Logic App for email alerts, set `logic_app_enabled = true` in your `terraform.tfvars`.

4.  **Apply Configuration:**
    ```bash
    terraform apply
    ```
    Confirm the apply to create the resources.

## Post-Deployment: Logic App Configuration

If you enabled the Logic App (`email-alert-logic-app`), it requires manual authorization for the Office 365 API Connection:
1.  Go to the Azure Portal.
2.  Find the API Connection resource created (e.g., `office365`).
3.  Authorize the connection with your Office 365 credentials.
4.  Once authorized, the Logic App will be able to send emails triggered by the Webhook.

**Usage:**
The Logic App exposes a callback URL (output as `logic_app_callback_url`). You can use this URL in your Kubernetes CronJob or `curl` to trigger an email:

```json
{
    "to_address": "recipient@example.com",
    "subject": "Alert",
    "content": "Something happened!"
}
```

## Activating the Configuration (Cloud Shell)

Once the Terraform apply is successful and you have started Azure Cloud Shell (mounting the storage account you just created):

1.  Open Azure Cloud Shell.
2.  Your persistent storage is mounted at `$HOME/clouddrive`.
3.  The custom configuration script is located at `$HOME/clouddrive/.bashrc` (uploaded by Terraform).
4.  To apply these settings automatically, add the following line to your main `~/.bashrc`:

    ```bash
    [ -f "$HOME/clouddrive/.bashrc" ] && source "$HOME/clouddrive/.bashrc"
    ```

5.  Reload your shell:
    ```bash
    source ~/.bashrc
    ```

The tools (`yq`, `fzf`, etc.) will be installed to `$HOME/bin` on the first run.
