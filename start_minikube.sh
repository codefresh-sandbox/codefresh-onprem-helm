#!/bin/sh

# uncomment to enable RBAC
# RBAC="--extra-config=apiserver.Authorization.Mode=RBAC"
PROFILE=${PROFILE:-codefresh}
minikube profile ${PROFILE}

# uncomment to enable development on localhost
DEV=${DEV:-"--network-plugin=kubenet --extra-config=kubelet.PodCIDR=10.10.0.0/24 --extra-config=kubelet.NonMasqueradeCIDR=10.10.0.0/24"}

# ISO_URL=${ISO_URL:-"--iso-url https://storage.googleapis.com/minikube-builds/1658/minikube-testing.iso"}
ISO_URL=${ISO_URL:-""}

# DOCKER_OPTS=${DOCKER_OPTS:-"--docker-opt storage-driver=overlay2"}
DOCKER_OPTS=${DOCKER_OPTS:-""}

# others: v1.6.4
KUBE_VER=${KUBE_VER:-v1.7.0}

# others: xhyve
VM_DRV=${VM_DRV:-virtualbox}
# install xhive docker machine vm driver, if needed
if [[ "$VM_DRV" == "xhyve" ]]; then
  brew install docker-machine-driver-xhyve
fi

# Storage size
DISK_SIZE=${DISK_SIZE:-20g}

# CPUS to use
CPUS=${CPUS:-2}

# RAM to use
MEMORY=${MEMORY:-4096}

# Docker registry mirror: IP for VirtualBox
MIRROR=${MIRROR:-"--registry-mirror=http://localhost:15000 --mount"}

minikube start --cpus=${CPUS} --memory=${MEMORY} --vm-driver=${VM_DRV} --disk-size=${DISK_SIZE} --kubernetes-version=${KUBE_VER} ${MIRROR} ${RBAC} ${DEV} ${ISO_URL} ${DOCKER_OPTS}

# run Registry mirror mounted to local folder inside minikube
if [[ ! -z "${MIRROR}" ]]; then
  minikube ssh "docker run -d --restart=always -p 15000:5000 --name registry-mirror -v $HOME/.mirror/data:/var/lib/registry -v $HOME/.mirror/config:/etc/docker/registry registry:2"
fi
