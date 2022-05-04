#!/bin/sh

# array syntax is not used here because /bin/sh doesn't support it
repos="
    cluster-providers
    kube-integration
    charts-manager
    cfsign
    tasker-kubernetes
    context-manager
    pipeline-manager
    gitops-dashboard-manager
    cfapi
    cfui
    runtime-environment-manager
    cf-broadcaster
    helm-repo-manager
    hermes
    nomios
    cronus
    k8s-monitor
    argo-platform
"
for r in $repos; do
    helm repo add $r http://chartmuseum.codefresh.io/$r
    helm repo add $r-dev http://chartmuseum-dev.codefresh.io/$r
done

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx