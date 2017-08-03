#!/bin/sh

ENVIRONMENT=${ENVIRONMENT:-local}
CF_CHART_RELEASE=${CF_CHART_RELEASE:-dev}
CF_CHART_NAMESPACE=${CF_CHART_NAMESPACE:-codefresh}
DRY_RUN=${DRY_RUN:-false}
DEBUG=${DEBUG:-false}

docker run -it --rm \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  -e UPGRADE=true \
  -e DRY_RUN=${DRY_RUN} \
  -e DEBUG=${DEBUG} \
  -e CHART=codefresh \
  -e VALUES_FILES=codefresh/values.yaml,codefresh/values-dec.yaml,codefresh/regsecret-dec.yaml,codefresh/env/${ENVIRONMENT}/values-dec.yaml,codefresh/env/${ENVIRONMENT}/values.yaml \
  -e RELEASE="${CF_CHART_RELEASE}" \
  -e NAMESPACE="${CF_CHART_NAMESPACE}" \
  -e SKIP_TLS_VERIFY=true \
  -e RECREATE_PODS=true \
  -e REUSE_VALUES=true \
  -e WAIT=true \
  -e DRONE_BUILD_EVENT=push \
  -v $(PWD):/cf \
  -v ${HOME}/.kube/config:/root/.kube/config \
  -v ${HOME}/.minikube/apiserver.crt:${HOME}/.minikube/apiserver.crt \
  -v ${HOME}/.minikube/apiserver.key:${HOME}/.minikube/apiserver.key \
  -v ${HOME}/.minikube/ca.crt:${HOME}/.minikube/ca.crt \
  -w /cf \
  alexeiled/drone-helm:2.5.1