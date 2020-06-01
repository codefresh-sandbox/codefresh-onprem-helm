#!/usr/bin/env bash

set -euo pipefail

log() { echo -e "\e[1mboldINFO [$(date +%F\ %T)] ---> $1\e[0m"; }
success() { echo -e "\e[32mSUCCESS [$(date +%F\ %T)] ---> $1\e[0m"; }
err() { echo -e "\e[31mERR [$(date +%F\ %T)] ---> $1\e[0m" ; return 1; }

CHART_PATH="codefresh/Chart.yaml"

ONPREM_MASTER_BRANCH="${ONPREM_MASTER_BRANCH:-onprem-alignment}"

# checks whether the Chart version has been updated
# comparing it with the last tag on the main onprem branch
function checkOnpremVersion() {
    log "\nChecking onprem release version"

    local last_onprem_ver=$(git describe --abbrev=0 --tags origin/${ONPREM_MASTER_BRANCH} | cut -d '-' -f2)
    local curr_onprem_ver=$(yq r ${CHART_PATH} version)

    log "Last onprem version is: ${last_onprem_ver}"
    log "Current onprem version is: ${curr_onprem_ver}"

    if $(semver-cli greater ${curr_onprem_ver} ${last_onprem_ver}); then
        success "Onprem version check passed\n"
    else
        err "Onprem version check failed. Please update the version in the Chart.yaml"
    fi

    export ONPREM_VERSION="${curr_onprem_ver}"
}

# this function double-checks whether the build is running on a branch
# that is derived from the main onprem branch
# it is important to stop the pipeline execution otherwise
function checkBranch() {
    log "Double-checking if the branch is derived from the main onprem branch \"${ONPREM_MASTER_BRANCH}\"\n"
    local prev_git_tag=$(git describe --abbrev=0 --tags ${CF_BRANCH})

    log "Previous git tag is: ${prev_git_tag}"
    log "Trying to find the same tag on the branch ${ONPREM_MASTER_BRANCH}"

    if [[ "$(git describe --abbrev=0 --tags origin/${ONPREM_MASTER_BRANCH})" != "${prev_git_tag}" ]]; then
        err "\nMatching git tag hasn't been found on the branch \"${ONPREM_MASTER_BRANCH}\". Stopping here...\n"
    fi

    success "Branch check passed\n"
}

function checkHelmRepoChannel() {
    CHANNEL=${CHANNEL:-dev}
    if [[ "${CF_BRANCH}" != "${ONPREM_MASTER_BRANCH}" ]] && [[ "${CHANNEL}" == "prod" ]]; then
        err "CHANNEL variable value can not be "prod", when building from a feature branch"
    fi
}

checkOnpremVersion
checkBranch
checkHelmRepoChannel