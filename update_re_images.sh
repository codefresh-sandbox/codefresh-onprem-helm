#!/usr/bin/env bash

<<COMMENT
Script updates runtime images from system/default-plan runtime on SAAS to codefresh/values.yaml
yq (https://github.com/mikefarah/yq/) version 4.23.1
COMMENT

set -ue

DEBUG=${DEBUG:-false}

if [ ${DEBUG} == "true" ]; then
    set -x
fi

msg() { echo -e "\e[32mINFO ---> $1\e[0m"; }
err() { echo -e "\e[31mERR ---> $1\e[0m" ; return 1; }

runtimeJson=$(mktemp)
codefresh get sys-re system/default-plan --extend -o json > $runtimeJson

RUNTIME_IMAGES=(
    ENGINE_IMAGE
    DIND_IMAGE
    CONTAINER_LOGGER_IMAGE
    DOCKER_PUSHER_IMAGE
    DOCKER_TAG_PUSHER_IMAGE
    DOCKER_PULLER_IMAGE
    DOCKER_BUILDER_IMAGE
    GIT_CLONE_IMAGE
    COMPOSE_IMAGE
    KUBE_DEPLOY
    FS_OPS_IMAGE
    TEMPLATE_ENGINE
    PIPELINE_DEBUGGER_IMAGE
)

for k in ${RUNTIME_IMAGES[@]}; do
    if [[ "$k" == "ENGINE_IMAGE" ]]; then
        image="$(jq -er .runtimeScheduler.image $runtimeJson)" 
        yq eval ".ENGINE_IMAGE = \"$image\"" -i codefresh/values.yaml
    elif [[ "$k" == "DIND_IMAGE" ]]; then
        image="$(jq -er .dockerDaemonScheduler.dindImage $runtimeJson)"
        yq eval ".DIND_IMAGE = \"$image\"" -i codefresh/values.yaml
    else
        image="$(jq -er .runtimeScheduler.envVars.$k $runtimeJson)" 
        yq eval ".\"$k\" = \"$image\"" -i codefresh/values.yaml
    fi
done

msg "The list of updated runtime images:\n"
echo -e "\e[33m$(cat codefresh/values.yaml)\e[0m"