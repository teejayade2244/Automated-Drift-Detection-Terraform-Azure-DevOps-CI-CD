# Automated Drift Detection — Terraform + Azure DevOps CI/CD

A small, practical pipeline that automatically detects configuration drift between Terraform configuration and real Azure infrastructure and notifies engineers when differences are found.

This repository contains an Azure DevOps pipeline that:
- Runs Terraform commands (init, validate, plan) against a target Azure environment,
- Evaluates the Terraform plan exit code to determine if drift exists,
- Produces a machine- and human-readable drift report,
- Publishes the plan and report as pipeline artifacts, and
- Sends notifications (e.g., Slack) when drift is detected.

Why this matters
- Configuration drift occurs when manual changes or out-of-band automation change deployed infrastructure so it no longer matches IaC definitions.
- Early detection prevents configuration rot, security drift, failed redeploys, and surprises during maintenance.
- Automating detection in CI ensures continuous verification of infrastructure compliance to the declared Terraform state.

High-level architecture / flow
1. Azure DevOps pipeline is triggered (manual, scheduled, or on repo changes).
2. Pipeline checks out the repo and sets up tooling (Azure CLI, Terraform).
3. Pipeline authenticates to Azure with a Service Principal (stored as a secure variable / service connection).
4. Terraform init & validate ensure backend and config are ready.
5. Terraform plan is executed and saved to a plan file (tfplan).
6. Pipeline reads the Terraform plan exit code:
   - Exit code 0: no changes detected (infrastructure matches configuration).
   - Exit code 2: plan has changes -> drift detected.
7. When drift is detected:
   - A drift report (drift-report.txt) is generated and published as an artifact.
   - Notifications are sent (Slack or other configured channels) with a summary and link to full artifact/log.
8. Pipeline completes and stores artifacts for auditing.

Key pipeline stages (as implemented)
- Install, Init, Validate: install Azure CLI/Terraform, run `terraform init` and `terraform validate`.
- Terraform Plan & Analyze Exit Code: run `terraform plan -out=tfplan` and examine the exit code; save plan as artifact.
- Publish Terraform Plan: publish the tfplan and human-readable logs.
- Publish Drift Report: create and publish a short drift-report.txt summarizing what changed.
- Send Notifications: post alerts to Slack (or other) including run link and summary.

Terraform behavior & exit codes
- terraform plan returns:
  - 0 when no changes are required (no drift).
  - 2 when there are changes (drift or pending changes).
  - Other non-zero codes indicate errors.
- The pipeline uses these exit codes to gate notifications and artifact publishing.

What the repository contains (important files)
- azure-pipelines.yml (or equivalent pipeline script) — the CI pipeline definition executed by Azure DevOps.
- scripts/
  - detect-drift.sh (or similar) — wrapper script that runs Terraform plan, interprets exit codes, writes drift-report.txt and returns appropriate exit status to pipeline.
- terraform/ (or modules/)
  - main.tf, variables.tf, backend.tf — example Terraform configuration used in the demo.
- docs/ or screenshots/ — pipeline run screenshots demonstrating both "no drift" and "drift detected" runs (optional).
- README.md — this file.

Prerequisites
- Azure subscription with sufficient permissions to query the resources in scope.
- An Azure Service Principal with Contributor (or specific read/list) access to the resource groups/subscriptions you want to scan.
- Azure DevOps project with a pipeline and secure variables/Service Connections configured for the SP credentials.
- Terraform installed in the pipeline agent (the pipeline includes steps to install it).

Quick setup (high-level)
1. Create an Azure Service Principal and give it required permissions:
   - az ad sp create-for-rbac --name "tf-drift-bot" --role Contributor --scopes /subscriptions/<SUBSCRIPTION-ID>
   - Save appId, password, tenant, subscription.
2. In Azure DevOps:
   - Create a Service Connection or set secure pipeline variables for AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID.
   - If using Slack notifications, create an Incoming Webhook and save the URL as a secure variable.
3. Update pipeline YAML to point to the correct Terraform working directory and backend (if using remote state).
4. Run the pipeline manually or schedule it.

Interpreting pipeline results
- Success + message "No changes. Your infrastructure matches the configuration." → No drift.
- Non-zero plan exit code with message "Drift detected! Infrastructure changes found (Exit Code 2)" → Drift exists. Open the drift-report.txt artifact and pipeline logs to inspect the specific diffs. The pipeline will publish the tfplan and the human-readable plan output.
- For errors (other exit codes) check logs on the failing step (permission, backend, or syntax issues).

Example commands used by the pipeline
- az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
- terraform init -backend-config="..." 
- terraform validate
- terraform plan -out=tfplan
- terraform show -no-color tfplan > plan.txt

Notifications
- The project includes a notification step that sends:
  - A summary message (pipeline run id, result, drift/no-drift).
  - A link to the pipeline run and the drift-report artifact.
- Slack webhooks are used in the example; you can replace with Teams, email, or custom webhooks.

Best practices & considerations
- Use read-only or least privilege roles where possible — if the pipeline only needs to detect drift, it does not require permission to modify resources.
- Use remote state (e.g., Azure Storage backend) to prevent state inconsistencies.
- Run drift detection on a schedule (e.g., daily) to catch changes early.
- Keep secrets in Azure DevOps secure variables or Key Vault.
- Review drift diffs carefully — some changes might be intentional (patches, autoscaling) and should be reconciled in IaC.

Troubleshooting tips
- Authentication failures: verify Service Principal credentials and that the SP has access to the target subscription/resource group.
- Backend errors: ensure backend configuration (storage account, container, key) exists and the SP can access it.
- Terraform errors: run the same commands locally with the same credentials to replicate and debug.

Extending this project
- Add auto-remediation (careful — ideally gated to approval) to enforce the IaC state.
- Integrate richer reporting or a dashboard.
- Add GitOps integration: open a PR with suggested Terraform changes rather than applying automatically.
- Add more notification sinks (email, Teams, PagerDuty).


