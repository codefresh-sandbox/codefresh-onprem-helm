#!/bin/bash

set -euo pipefail

log() { echo -e "\e[1mboldINFO [$(date +%F\ %T)] ---> $1\e[0m"; }
success() { echo -e "\e[32mSUCCESS [$(date +%F\ %T)] ---> $1\e[0m"; }
err() { echo -e "\e[31mERR [$(date +%F\ %T)] ---> $1\e[0m" ; return 1; }

SKIP_EMPTY=false
CACHE_DIR=${CACHE_DIR:-/codefresh/volume/trivy_cache}
SCAN_REPORT_FILE=${SCAN_REPORT_FILE:-/codefresh/volume/scan_report}

function scan_image() {
    local image=$1
    local object=$(trivy -q --cache-dir ${CACHE_DIR} image -f json --severity HIGH,CRITICAL --ignore-unfixed ${image} | sed 's|null|\[\]|')
    count=$( echo $object | jq .Results | jq length)
    for ((i = 0 ; i < $count ; i++)); do
    local vuln_length=$(echo $object | jq .Results | jq -r --arg index "${i}" '.[($index|tonumber)].Vulnerabilities | length')
    if [[ "$vuln_length" -eq "0" ]] && [[ "$SKIP_EMPTY" == "true" ]]; then
        continue
    fi
    echo -e "\n"Target: $(echo $object | jq .Results | jq -r --arg index "${i}" '.[($index|tonumber)].Target')
    echo "..."
    echo $object | jq .Results | jq -r --arg index "${i}" '.[($index|tonumber)].Vulnerabilities[] | "\(.PkgName) \(.VulnerabilityID) \(.Severity)"' | column -t | sort -k3
    done
}

function scan_images() {
    for i in $(cat $1); do
        scan_image $i | tee -a ${SCAN_REPORT_FILE}
    done
}

function generate_report() {
    # a few images, which trivy can not handle because of
    # old manifest format or old docker registry API version should be excluded
    local excluded_imgs=()

    ! rm ${SCAN_REPORT_FILE} 2>/dev/null

    local excluded_img_list=$(mktemp)

    for i in ${excluded_imgs[@]}; do
        echo $i >> $excluded_img_list
    done

    local final_img_list=$(mktemp)

    grep -v -f $excluded_img_list ${IMG_LIST_FILE} > $final_img_list
    
    log "The following images will be scanned:\n"
    cat $final_img_list

    # we need to perform separate scans per docker registry
    # because trivy can use only one registry authentication data at a time
    local img_list_gcr=$(mktemp)
    local img_list_non_gcr=$(mktemp)

    cat $final_img_list | grep gcr > $img_list_gcr
    cat $final_img_list | grep -v gcr > $img_list_non_gcr

    scan_images $img_list_gcr

    # unset the trivy registry authentication vars so that
    # trivy doesn't attempt to authenticate against dockerhub with gcr creds
    # and could scan the rest dockerhub public images
    unset TRIVY_USERNAME TRIVY_PASSWORD
    scan_images $img_list_non_gcr

    success "The security report file has been successfully created: ${SCAN_REPORT_FILE}"
}

generate_report