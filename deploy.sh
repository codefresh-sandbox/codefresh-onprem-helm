#!/bin/sh

# set _DEBUG to "true" to see debug logs
_log() {
  if [ "$_DEBUG" == "true" ]; then
    echo 1>&2 "$@"
  fi
}

set -e

if [ ! -z "$KUBERNETES_USER" ]; then
  echo "---> Setting up Kubernetes credentials ..."
  kubectl config set-credentials deployer --username="${KUBERNETES_USER}" --password="${KUBERNETES_PASSWORD}"
  kubectl config set-cluster foo.kubernetes.com --insecure-skip-tls-verify=true --server="${KUBERNETES_SERVER}"
  kubectl config set-context foo.kubernetes.com/deployer --user=deployer --namespace="${NAMESPACE}" --cluster=foo.kubernetes.com
  kubectl config use-context foo.kubernetes.com/deployer
fi

# set release name (default to dev)
RELEASE=${RELEASE:-dev}
echo "# Release: ${RELEASE}"

# set target namespace (default to codefresh)
NAMESPACE=${NAMESPACE:-codefresh}
echo "# Namespace: ${NAMESPACE}"

# use Codefresh version
VERSION=${VERSION}
if [ -z "$VERSION" ]; then
  echo "# Version: latest"
else
  echo "# Version: ${VERSION}"
fi

echo "---> Helm init ..."
helm init --upgrade

echo "---> Waiting Helm to be ready ..."
while true; do
  status=$(kubectl get po -l app=helm -l name=tiller --show-all=false -o=custom-columns=STATUS:.status.phase --no-headers=true -nkube-system)
  _log "Helm status = $status"
  [ "$status" = "Running" ] && break
  _log "sleeping 3 seconds ..."
  sleep 3
done

sleep 3
echo "# Helm version"
helm version

# set environment (default to local)
ENVIRONMENT=${ENVIRONMENT:-local}
echo "# Current environment: ${ENVIRONMENT}"

# decrypt *-enc.yaml files with sops
echo "---> Decrypting secrets ..."
./sops.sh -d

# add codefresh repository to helm
helm repo add cf http://codefresh-helm-charts.s3-website-us-east-1.amazonaws.com

# deploy Codefresh chart
if [ "$_DEBUG" == "true" ]; then
  debug_flag="--debug"
fi

if [ "$_DRY_RUN" == "true" ]; then
  dry_run_flag="--dry-run"
fi

# prepare version flag if needed
if [ ! -z "$VERSION" ]; then
  version_flag="--version ${VERSION}"
fi

echo "---> Help upgrade: release=${RELEASE} of Codefresh chart ver=${VERSION:-latest} to the namespace=${NAMESPACE}"
helm $debug_flag upgrade "${RELEASE}" cf/codefresh $dry_run_flag $version_flag --install --reset-values --recreate-pods --namespace "${NAMESPACE}" \
  --values "codefresh/values.yaml" \
  --values "codefresh/values-dec.yaml" \
  --values "codefresh/regsecret-dec.yaml" \
  --values "codefresh/env/${ENVIRONMENT}/values-dec.yaml" \
  --values "codefresh/env/${ENVIRONMENT}/values.yaml"