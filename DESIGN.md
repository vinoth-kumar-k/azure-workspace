# Enterprise CI/CD Design for .NET Applications

## 1. Executive Summary

This document outlines the architectural design for a standardized, reusable CI/CD pipeline for the organization's .NET ecosystem (C#, VB.NET). The design leverages **GitHub Actions Reusable Workflows** to enforce governance, security, and consistency while allowing flexibility for diverse deployment targets (AKS and Virtual Machines).

## 2. Architecture Overview

The system assumes a **Hub-and-Spoke** model:
*   **Hub:** A centralized `github-workflows` repository containing the "source of truth" workflow definitions.
*   **Spoke:** Individual application repositories calling these workflows via `uses: my-org/github-workflows/...`.

### 2.1 Repository Structure (Reference)

```text
.github/
  workflows/
    # --- Reusable Workflows ---
    dotnet-ci.yml          # CI: Build, Test, Scan, Publish
    deploy-aks.yml         # CD: Deploy to Azure Kubernetes Service
    reusable-build-legacy.yml # CI: Build Legacy .NET Framework
    reusable-deploy-vm.yml    # CD: Deploy to Azure Virtual Machine (Legacy/IIS)
docker/
  Dockerfile.template      # Standard multi-stage Dockerfile
DESIGN.md                  # This document
```

## 3. Workflow Design Specifications

### 3.1 Legacy Build Workflow (`reusable-build-legacy.yml`)

**Purpose:** To handle the Build and Package phases for Legacy .NET Framework applications.

**Key Features:**
*   **Environment:** Runs on `windows-latest` to support `msbuild`.
*   **Build:** Uses `microsoft/setup-msbuild` and `nuget restore`.
*   **Artifact:** Produces a zip package of the build output (`bin/Release`).

### 3.2 CD Strategy: Containerized (AKS) (`deploy-aks.yml`)

**Purpose:** Deploys modern .NET applications to Azure Kubernetes Service.

**Flow:**
1.  **Gate:** Checks GitHub Environment protection rules (Manual Approvals).
2.  **Auth:** OIDC Login to Azure.
3.  **Context:** Sets kubeconfig for the target cluster.
4.  **Deploy:** Uses `azure/k8s-deploy` to apply manifests, swapping the image tag with the one generated in CI.
    *   *Input:* Accepts `registry-url` to support different ACRs per environment.

### 3.3 CD Strategy: Virtual Machine (`reusable-deploy-vm.yml`)

**Purpose:** Deploys legacy or non-containerized applications to Azure VMs via Azure Native Services.

**Features:**
*   **Deployment Strategies:**
    *   `run-command` (Default): Uses `az vm run-command` to execute the deployment script immediately. Best for ad-hoc deployments.
    *   `custom-script-extension`: Uses the Azure Custom Script Extension to provision the VM. Best for bootstrapping or state configuration.

**Flow:**
1.  **Artifact Staging:**
    *   Downloads the build artifacts.
    *   Uploads the package to a **Staging Azure Blob Storage** account.
    *   Generates a short-lived **SAS Token**.
2.  **Execution:**
    *   **Run Command:** Invokes the script (`scripts/vm-install.ps1`) passing the SAS URL.
    *   **Extension:** Uploads the script to Blob Storage (SAS), then configures the VM Extension to download and run it.

## 4. The "No Dockerfile" Strategy

Many legacy repositories lack container definitions. To bridge this gap without "magic" generation that is hard to debug:
1.  We provide a **Standard Dockerfile Template** (`docker/Dockerfile.template`).
2.  **Policy:** Teams migrating to AKS must copy this template to their repository root.
3.  **CI Support:** The CI workflow accepts a `build-docker: true` flag. If enabled, it attempts to build the image using the repository's Dockerfile.

## 5. Security & Governance

*   **Authentication:** All Azure interactions use **Workload Identity Federation (OIDC)**. No long-lived Service Principal secrets are stored in GitHub.
*   **Environments:** Deployments are scoped to GitHub Environments (`dev`, `stage`, `prod`) to enforce separation of duties and approval gates.
*   **Immutability:** Docker images are tagged with the specific GitVersion (not `latest`), ensuring traceability.

## 6. Usage Example

Developers simply add a file to their repo (e.g., `.github/workflows/pipeline.yml`) referencing the reusable logic:

```yaml
jobs:
  build:
    uses: my-org/workflows/.github/workflows/dotnet-ci.yml@v1
    with:
      dotnet-version: '6.0'
      build-docker: true
```

## 7. Roles & Responsibilities

*   **DevOps Architect:** Maintainer of the `github-workflows` repository.
*   **App Developers:** Consumers of the workflows; responsible for adding the `Dockerfile` if targeting AKS.
