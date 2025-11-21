#!/bin/bash

# --- 1. Run Terraform Plan ---
# The 'set +e' command prevents the script from exiting immediately if 'terraform plan' 
# returns a non-zero exit code (0 for no change, 2 for drift, 1 for error).
set +e
terraform plan -detailed-exitcode -input=false -out=tfplan -lock-timeout=300s
PLAN_EXIT_CODE=$?
set -e # Restore default behavior

echo "Terraform plan command returned exit code: $PLAN_EXIT_CODE"

# --- 2. Analyze Exit Code and Set Pipeline Status ---
case $PLAN_EXIT_CODE in
  0)
    echo "✅ No changes. Infrastructure is up-to-date."
    ;;
  1)
    echo "❌ Terraform plan failed with errors (Exit Code 1)"
    echo "##vso[task.logissue type=error]Terraform plan failed"
    # Complete the job as failed if validation/plan fails
    echo "##vso[task.complete result=Failed;]Plan failed"
    exit 1
    ;;
  2)
    echo "⚠️  Drift detected! Infrastructure changes found (Exit Code 2)."
    # Generate human-readable drift report for publishing
    terraform show tfplan > drift-report.txt
    echo "Drift report generated: drift-report.txt"
    echo "##vso[task.logissue type=warning]Configuration drift detected in Azure infrastructure"
    # Set job result to SucceededWithIssues to flag the drift but allow Notification stage to run
    echo "##vso[task.complete result=SucceededWithIssues;]Drift detected"
    ;;
  *)
    echo "❓ Unexpected exit code: $PLAN_EXIT_CODE"
    echo "##vso[task.complete result=Failed;]Unexpected exit code"
    exit 1
    ;;
esac

# --- 3. Set Output Variable for Notification Stage ---
echo "##vso[task.setvariable variable=planExitCode;isOutput=true]$PLAN_EXIT_CODE"