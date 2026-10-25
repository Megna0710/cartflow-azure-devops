# CartFlow --- Azure DevOps Project

A containerized Flask API deployed to **Azure Container Apps**, with
infrastructure managed by **Terraform**, CI/CD automated using **GitHub
Actions**, and security and monitoring capabilities integrated into the
delivery workflow.

> **Live application:**
> https://cartflow-api.thankfulforest-0f061758.centralindia.azurecontainerapps.io\
> **Health endpoint:**
> https://cartflow-api.thankfulforest-0f061758.centralindia.azurecontainerapps.io/health

![CartFlow Azure DevOps
Architecture](docs/images/02-project-architecture.png)

## Table of Contents

-   [Project Overview](#project-overview)
-   [Architecture](#architecture)
-   [Technology Stack](#technology-stack)
-   [Application Endpoints](#application-endpoints)
-   [CI/CD Workflow](#cicd-workflow)
-   [Infrastructure as Code](#infrastructure-as-code)
-   [Identity and Secrets](#identity-and-secrets)
-   [Security](#security)
-   [Monitoring and Alerting](#monitoring-and-alerting)
-   [Repository Structure](#repository-structure)
-   [Screenshots](#screenshots)
-   [Run Locally](#run-locally)
-   [Deployment and Verification](#deployment-and-verification)
-   [Key Learning Outcomes](#key-learning-outcomes)
-   [Future Improvements](#future-improvements)

## Project Overview

CartFlow is a Flask-based API used to demonstrate an end-to-end Azure
DevOps workflow. The project combines application testing, container
image creation, registry storage, cloud deployment, repeatable
infrastructure provisioning, repository security controls, and
operational monitoring.

### Goals

-   Automate application validation and deployment with GitHub Actions.
-   Package the application as a Docker image and publish it to Azure
    Container Registry (ACR).
-   Run the application in Azure Container Apps.
-   Provision and manage cloud resources with Terraform.
-   Use GitHub Actions OIDC federation to authenticate to Azure without
    storing a long-lived Azure client secret in GitHub.
-   Store Terraform remote state in Azure Blob Storage.
-   Configure Azure Key Vault for secret storage.
-   Collect Container Apps logs in Log Analytics and create an Azure
    Monitor CPU alert with email notifications.
-   Enable GitHub security features, including CodeQL, secret
    protection, push protection, and Dependabot alerts.

## Architecture

The high-level flow is:

1.  A developer commits code or opens a pull request in GitHub.
2.  GitHub Actions checks out the repository, sets up Python, installs
    dependencies, runs tests, performs configured security checks,
    builds the Docker image, and publishes it to ACR.
3.  The deployment workflow updates the Azure Container App to use the
    image from ACR.
4.  Terraform manages the Azure infrastructure and stores its state in a
    remote Azure Blob Storage backend.
5.  GitHub Actions authenticates to Azure using Microsoft Entra ID
    federated credentials (OIDC).
6.  Azure Container Apps emits console and system logs to the connected
    Log Analytics workspace.
7.  Azure Monitor evaluates the configured CPU percentage alert and uses
    the `cartflow-alerts` action group to send email notifications.

### Azure resources used

  Resource                          Name / purpose
  --------------------------------- ------------------------------
  Resource group                    `cartflow-rg`
  Azure Container App               `cartflow-api`
  Container Apps environment        `cartflow-env`
  Azure Container Registry          `cartflowmegna2026`
  Log Analytics workspace           `workspacecartflowrgb3e8`
  Azure Key Vault                   `cartflow-kv-megna-2026`
  Terraform state storage account   `cartflowtfstate2026`
  Terraform state container         `tfstate`
  Terraform state blob              `cartflow-terraform.tfstate`
  Azure Monitor CPU alert           `CartFlow-High-CPU-Alert`
  Alert action group                `cartflow-alerts`

> **Security note:** Do not commit secret values, access keys,
> connection strings, Terraform state contents, or other credentials to
> this repository. Screenshots should hide email addresses and sensitive
> identifiers where appropriate.

## Technology Stack

  -----------------------------------------------------------------------
  Area                                Technologies
  ----------------------------------- -----------------------------------
  Application                         Python, Flask

  Containerization                    Docker

  Container registry                  Azure Container Registry

  Runtime                             Azure Container Apps

  CI/CD                               GitHub Actions

  Infrastructure as Code              Terraform

  Cloud identity                      Microsoft Entra ID, federated
                                      identity / OIDC

  Secrets                             Azure Key Vault

  Remote Terraform state              Azure Blob Storage

  Logs                                Azure Container Apps logs, Azure
                                      Log Analytics

  Monitoring                          Azure Monitor metrics and alert
                                      rules

  Repository security                 CodeQL, Dependabot, secret
                                      protection, push protection
  -----------------------------------------------------------------------

## Application Endpoints

  -----------------------------------------------------------------------------------------------------------------------------------------
  Endpoint                                                                                              Purpose
  ----------------------------------------------------------------------------------------------------- -----------------------------------
  [`/`](https://cartflow-api.thankfulforest-0f061758.centralindia.azurecontainerapps.io/)               Application root

  [`/health`](https://cartflow-api.thankfulforest-0f061758.centralindia.azurecontainerapps.io/health)   Health-check response
  -----------------------------------------------------------------------------------------------------------------------------------------

The health endpoint has returned a healthy response with the API,
catalog, and orders checks marked `ok`. Re-check the live endpoint
before relying on its current availability.

## CI/CD Workflow

The application workflow is located at `.github/workflows/ci-cd.yml`.

At a high level, the workflow:

1.  Checks out the repository.
2.  Sets up Python and installs application dependencies.
3.  Runs automated tests.
4.  Builds the Docker image.
5.  Authenticates to Azure through the configured GitHub OIDC
    integration.
6.  Pushes the image to Azure Container Registry.
7.  Deploys the image to Azure Container Apps.

The repository also contains Terraform workflows:

-   `.github/workflows/terraform-ci.yml` --- Terraform checks and plan
    workflow for changes.
-   `.github/workflows/terraform-apply.yml` --- manually initiated
    Terraform apply workflow with an explicit confirmation input and
    protected GitHub environment.

The Terraform apply workflow has previously completed successfully with
no infrastructure changes required (`0 added, 0 changed, 0 destroyed`).
This indicates that the deployed resources matched the Terraform
configuration at that run; it does not guarantee that every future run
will be change-free.

## Infrastructure as Code

Terraform configuration is stored in `terraform-azure/`.

The remote backend uses Azure Blob Storage:

-   Storage account: `cartflowtfstate2026`
-   Container: `tfstate`
-   State blob: `cartflow-terraform.tfstate`

The remote state allows Terraform runs to use a shared state file rather
than relying on one developer's local state. Keep the storage account
private and protect access to the state file because Terraform state can
contain sensitive values.

Typical Terraform workflow:

1.  Review the Terraform configuration and backend settings.
2.  Run formatting and validation checks.
3.  Generate and inspect a plan.
4.  Apply only after reviewing the plan and satisfying the repository's
    approval/confirmation controls.
5.  Verify the resulting Azure resources.

Use the project's actual backend configuration and workflow instructions
when running Terraform. Do not paste state contents or secrets into
issues, logs, or the README.

## Identity and Secrets

### GitHub Actions to Azure

GitHub Actions uses Microsoft Entra ID federated credentials (OIDC) to
authenticate to Azure. This avoids needing a long-lived Azure client
secret stored as a GitHub Actions secret for that federation flow.

The app registration used for this integration is
`GitHubActions-CartFlow`. Federated credentials were configured for the
relevant GitHub workflow contexts, including the main branch, pull
requests, and Terraform workflows.

### Azure Key Vault

The Key Vault `cartflow-kv-megna-2026` contains the project secret
`cartflow-demo-message`. The secret value must not be committed to
GitHub or included in screenshots.

The existence of a secret in Key Vault does not, by itself, prove that
the running application retrieves and consumes it at runtime. Document
runtime Key Vault integration only after verifying the relevant
identity, permissions, and application/configuration code.

## Security

Security controls configured or verified for this repository include:

-   **CodeQL:** Default code-scanning configuration enabled; the setup
    run completed for Actions and Python analysis.
-   **Secret protection:** Enabled.
-   **Push protection:** Enabled to help block pushes containing
    supported secrets.
-   **Dependabot alerts:** Enabled; the captured alert page showed no
    open alerts at the time of review.
-   **GitHub Actions:** CI/CD and Terraform workflows are maintained in
    the repository.
-   **Azure OIDC:** Federated authentication is configured for GitHub
    Actions.
-   **Terraform review controls:** The apply workflow uses an explicit
    confirmation input and protected environment approval controls.

Security dashboards are point-in-time evidence. A clean scan does not
prove that the project is free of every vulnerability, and alerts can
change as code and dependencies change.

## Monitoring and Alerting

Monitoring is configured using Azure Monitor and Log Analytics.

### Log Analytics

The Container Apps environment `cartflow-env` is configured with the
`log-analytics` destination and is connected to workspace
`workspacecartflowrgb3e8`.

The following log tables were observed to contain records:

-   `ContainerAppConsoleLogs_CL` --- console output, including Flask
    startup messages and HTTP requests.
-   `ContainerAppSystemLogs_CL` --- container lifecycle events,
    including container creation and startup.

Example KQL query for recent console logs:

``` kusto
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(1h)
| project TimeGenerated, ContainerGroupName_s, Log_s
| sort by TimeGenerated desc
| take 30
```

Example query to inspect HTTP request and error text:

``` kusto
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(24h)
| where Log_s contains "HTTP/" or Log_s contains "ERROR"
| project TimeGenerated, Log_s
| sort by TimeGenerated desc
| take 50
```

Log formats depend on what the application writes to stdout/stderr. A
browser request for `/favicon.ico` returned a `404` in the captured
logs; this is commonly a missing browser icon and does not by itself
mean the API health endpoint is failing.

### CPU metric and alert

The Azure Monitor metric `CPU Usage Percentage (Preview)` is available
for `cartflow-api`. The configured alert is:

-   **Name:** `CartFlow-High-CPU-Alert`
-   **Metric:** CPU Usage Percentage (Preview) / `CpuPercentage`
-   **Aggregation:** Average
-   **Condition:** Greater than `80%`
-   **Evaluation frequency:** Every 1 minute
-   **Lookback period:** 5 minutes
-   **Severity:** 3 --- Informational
-   **Action group:** `cartflow-alerts`

The action group contains a verified email receiver named
`CartFlowEmail`. An Azure Monitor **sample static-threshold action-group
test completed successfully**, and the sample notification was received
by email.

> **Testing distinction:** The action-group test verifies the
> notification path. It does not prove that the real CartFlow CPU alert
> has fired due to CPU exceeding 80%. At the time of the captured metric
> screenshot, CPU usage was 0%.

### Monitoring follow-up

-   Consider adding an alert for replica restarts or another operational
    signal after confirming the appropriate metric is available.
-   Consider moving the Flask app from its built-in development server
    to a production WSGI server such as Gunicorn before presenting it as
    production-ready.
-   Azure Monitor alerting and Log Analytics can incur charges. Review
    current pricing and your Azure cost management settings.

## Repository Structure

The main project files include the application, Docker configuration,
GitHub Actions workflows, Terraform configuration, and documentation
screenshots. The exact tree may evolve; a representative structure is:

``` text
cartflow-azure-devops/
├── app/
│   ├── app.py
│   └── requirements.txt
├── terraform-azure/
│   └── ... Terraform configuration ...
├── .github/
│   └── workflows/
│       ├── ci-cd.yml
│       ├── terraform-ci.yml
│       └── terraform-apply.yml
├── docs/
│   └── images/
│       ├── 02-project-architecture.png
│       ├── 02-azure-container-app.png
│       └── ... screenshots 03–21 ...
├── Dockerfile
└── README.md
```

Confirm the filenames against the actual repository before committing
this README. If the Dockerfile or any workflow lives in a different
location, update this tree accordingly.

## Screenshots

Place the screenshots in `docs/images/` and use the filenames below.
Keep only screenshots that actually exist in the repository and update
the links if your names differ.

  -----------------------------------------------------------------------
  File                                Evidence
  ----------------------------------- -----------------------------------
  `02-project-architecture.png`       End-to-end architecture

  `02-azure-container-app.png`        Container App overview and
                                      application URL

  `03-container-registry.png`         ACR repository/image

  `04-cicd-pipeline.png`              Successful application CI/CD run

  `05-terraform-plan.png`             Terraform plan summary

  `06-api-health-check.png`           Health endpoint JSON response

  `07-terraform-state.png`            Terraform state blob in Azure
                                      Storage

  `08-github-oidc.png`                Entra ID federated credentials

  `09-key-vault.png`                  Key Vault secret listing (never
                                      show secret values)

  `10–15`                             Additional GitHub security and
                                      scanning evidence; align filenames
                                      with your captured screenshots

  `16-secret-protection.png`          Secret Protection and Push
                                      protection settings

  `17-cpu-metric.png`                 CPU Usage Percentage metric chart

  `18-cpu-alert-rule.png`             CPU threshold and evaluation
                                      settings

  `19-cpu-alert-enabled.png`          Enabled CartFlow CPU alert rule

  `20-alert-action-group.png`         Successful action-group test result

  `21-alert-test-email.png`           Sample Azure Monitor email received
  -----------------------------------------------------------------------

### Example screenshot embedding

``` markdown
![CartFlow CPU metric](docs/images/17-cpu-metric.png)

*Azure Monitor CPU Usage Percentage metric for the CartFlow Container App.*
```

## Run Locally

These commands are a starting point for local development. Run them from
the repository root and adapt the paths if your checkout differs.

### 1. Create and activate a virtual environment (Windows Git Bash)

``` bash
python -m venv venv
source venv/Scripts/activate
```

### 2. Install dependencies

``` bash
pip install -r app/requirements.txt
```

### 3. Run the Flask app

Use the application's documented startup command or entry point. For
example, if `app/app.py` exposes the Flask application as `app`, run:

``` bash
python app/app.py
```

### 4. Test the health endpoint

In another terminal:

``` bash
curl http://localhost:5000/health
```

Expected response should indicate a healthy status and the configured
checks. Exact fields may change with application code.

## Deployment and Verification

After a workflow run, verify the deployment rather than relying only on
a green GitHub Actions status:

1.  Confirm the application workflow completed successfully.
2.  Check that the expected image tag exists in ACR.
3.  Confirm the `cartflow-api` Container App revision is
    healthy/running.
4.  Open the live `/health` endpoint.
5.  Inspect console and system logs in Log Analytics.
6.  Confirm the CPU alert rule is enabled and its action group is
    attached.
7.  Review GitHub security alerts and dependency updates periodically.

## Key Learning Outcomes

This project demonstrates practical experience with:

-   Building and deploying a containerized Python API.
-   Creating CI/CD workflows with GitHub Actions.
-   Publishing container images to Azure Container Registry.
-   Deploying workloads to Azure Container Apps.
-   Managing cloud infrastructure with Terraform and remote state.
-   Configuring GitHub OIDC federation with Microsoft Entra ID.
-   Storing secrets in Azure Key Vault.
-   Enabling code scanning and secret-protection features in GitHub.
-   Querying application and system logs using KQL.
-   Configuring Azure Monitor metric alerts and email action groups.

## Future Improvements

-   Run Flask behind Gunicorn or another production WSGI server.
-   Add a container replica restart alert after validating the available
    metric and dimensions.
-   Add an alert for failed health checks or elevated HTTP 5xx responses
    if the telemetry supports it.
-   Add a dashboard that combines CPU, memory, request, and replica
    metrics.
-   Add a documented test strategy for application endpoints and
    deployment smoke tests.
-   Review Azure resource costs and remove unused resources when the
    project is not being demonstrated.
-   Keep dependencies updated and review CodeQL and Dependabot findings
    regularly.

------------------------------------------------------------------------

## Author

**Megna Pradeep**

-   GitHub: [Megna0710](https://github.com/Megna0710)
-   Project repository:
    [cartflow-azure-devops](https://github.com/Megna0710/cartflow-azure-devops)

------------------------------------------------------------------------

*This README documents the configuration and test results observed
during project development. Re-check live endpoints, cloud resource
settings, workflow filenames, and screenshot paths before publishing
changes.*
