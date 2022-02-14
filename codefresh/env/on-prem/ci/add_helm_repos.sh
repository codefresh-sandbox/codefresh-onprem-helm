#!/bin/sh

# array syntax is not used here because /bin/sh doesn't support it
repos="
    cluster-providers
    kube-integration
    charts-manager
    mailer
    payments
    cfsign
    segment-reporter
    salesforce-reporter
    tasker-kubernetes
    context-manager
    pipeline-manager
    gitops-dashboard-manager
    cfapi
    cfui
    onboarding-status
    runtime-environment-manager
    cf-broadcaster
    helm-repo-manager
    hermes
    nomios
    cronus
    k8s-monitor
"
for r in $repos; do
    helm repo add $r http://chartmuseum.codefresh.io/$r
    helm repo add $r-dev http://chartmuseum-dev.codefresh.io/$r
done
