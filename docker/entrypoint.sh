#!/bin/sh

keyfile="/root/keyfile"

if [ -f $HOME/.minikube/ca.crt ]; then
    echo "Helming to Minikube"
else
    echo "Helming to GKE"
    GCLOUD_PROJECT=${GCLOUD_PROJECT:-savvy-badge-103912}
    GCLOUD_ZONE=${GCLOUD_ZONE:-us-central1-a}
    GCLOUD_CLUSTER=${GCLOUD_CLUSTER:-gke_savvy-badge-103912_us-central1-a_cf-staging}

    # Gcloud key file is passed as base64 encoded file
    base64 -d $KEY_FILE > $keyfile

    # generate K8s config to work with cluster
    gcloud auth activate-service-account --key-file $keyfile
    gcloud container clusters get-credentials $GCLOUD_CLUSTER --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT
fi

# set release name (default to dev)	# set release name (default to dev)
RELEASE=${RELEASE:-dev}
echo "# Release: ${release}"

# set target namespace (default to cf)
NAMESPACE=${NAMESPACE:-cf}
echo "# Namespace: ${namespace}"

# use Codefresh version
VERSION=${VERSION}
if [ -z "$VERSION" ]; then
  echo "# Version: latest"
else
  echo "# Version: ${VERSION}"
  # add codefresh repository to helm
  repo_flag="--repo http://codefresh-helm-charts.s3-website-us-east-1.amazonaws.com"
  # prepare version flag
  version_flag="--version ${VERSION}"
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

# set environment (default to dynamic)
ENVIRONMENT=${ENVIRONMENT:-dynamic}
echo "# Current environment: ${ENVIRONMENT}"

# decrypt *-enc.yaml files with sops
echo "---> Decrypting secrets ..."
./sops.sh -d

# set debug flag
if [ "$DEBUG" == "true" ]; then
  debug_flag="--debug"
fi

# set wait flag
WAIT=${WAIT:-true}
if [ "$WAIT" == "true" ]; then
  wait_flag="--wait"
fi

# set timeout flag
if [ ! -z "$TIMEOUT" ]; then
  timeout_flag="--timeout $TIMEOUT"
fi

# set dry run flag
if [ "$DRY_RUN" == "true" ]; then
  dry_run_flag="--dry-run"
fi

# set reset-values flag
if [ "$RESET_VALUES" == "true" ]; then
  reset_values_flag="--reset-values"
fi

# set reuse-values flag
if [ "$REUSE_VALUES" == "true" ]; then
  reuse_values_flag="--reuse-values"
fi

# set reset-values flag
RECREATE_PODS=${RECREATE_PODS:-true}
if [ "$RECREATE_PODS" == "true" ]; then
  recreate_pods_flag="--recreate-pods"
fi

# force resource update through delete/recreate if needed
if [ "$FORCE" == "true" ]; then
  force_flag="--force"
fi

# deploy Codefresh chart
echo "---> Help upgrade: release=${RELEASE} of Codefresh chart ver=${VERSION:-latest} to the namespace=${NAMESPACE}"

helm $debug_flag upgrade "${RELEASE}" codefresh --install \
    $dry_run_flag \
    $repo_flag \
    $version_flag \
    $reuse_values_flag \
    $reset_values_flag \
    $recreate_pods_flag \
    --namespace "${NAMESPACE}" \
    $force_flag \
    $wait_flag \
    $timeout_flag \
    --values "codefresh/values.yaml" \
    --values "codefresh/values-dec.yaml" \
    --values "codefresh/regsecret-dec.yaml" \
    --values "codefresh/env/${ENVIRONMENT}/values-dec.yaml" \
    --values "codefresh/env/${ENVIRONMENT}/values.yaml"	
 