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
    deploy-vm.yml          # CD: Deploy to Azure Virtual Machine (Legacy/IIS)
docker/
  Dockerfile.template      # Standard multi-stage Dockerfile
DESIGN.md                  # This document
```

## 3. Workflow Design Specifications

### 3.1 Universal CI Workflow (`dotnet-ci.yml`)

**Purpose:** To handle the Build, Test, and Package phases for any .NET application (Core or Framework).

**Key Features:**
*   **Dynamic Runners:** Supports `ubuntu-latest` for .NET Core and `windows-latest` for legacy .NET Framework applications via the `runs-on` input.
*   **Automated Versioning:** Integrates **GitVersion** to automatically determine Semantic Versioning (SemVer) based on the git history, tagging assemblies and Docker images consistently.
*   **Artifact Generation:** Produces generic zip artifacts for VM deployment and Docker images for container deployment.
*   **Security:** Implements **OIDC (OpenID Connect)** for passwordless authentication to Azure resources (ACR).

### 3.2 CD Strategy: Containerized (AKS) (`deploy-aks.yml`)

**Purpose:** Deploys modern .NET applications to Azure Kubernetes Service.

**Flow:**
1.  **Gate:** Checks GitHub Environment protection rules (Manual Approvals).
2.  **Auth:** OIDC Login to Azure.
3.  **Context:** Sets kubeconfig for the target cluster.
4.  **Deploy:** Uses `azure/k8s-deploy` to apply manifests, swapping the image tag with the one generated in CI.

### 3.3 CD Strategy: Virtual Machine (`deploy-vm.yml`)

**Purpose:** Deploys legacy or non-containerized applications to Azure VMs (e.g., IIS web apps, Windows Services).

**Flow:**
1.  **Artifact Retrieval:** Downloads the build artifacts from the CI run.
2.  **Execution:** Uses **Azure Run Command** (`az vm run-command`) to trigger a deployment script resident on the VM or in the repo.
    *   *Decision:* We delegate the specific installation logic (e.g., "Stop IIS", "Copy Files", "Start IIS") to a PowerShell script (`vm-deploy.ps1`) to keep the pipeline generic.

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
