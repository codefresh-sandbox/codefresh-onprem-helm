#!/bin/sh

# install xhive docker machine vm driver
# brew install docker-machine-driver-xhyve

# uncomment to enable RBAC
# RBAC="--extra-config=apiserver.Authorization.Mode=RBAC"

# uncomment to enable development on localhost
DEV="--network-plugin=kubenet --extra-config=kubelet.PodCIDR=10.10.0.0/24 --extra-config=kubelet.NonMasqueradeCIDR=10.10.0.0/24"

# uncoment to use v1.7.0
KUBE_VER=v1.7.0
# KUBE_VER=v1.6.4

# VM=xhyve
VM=virtualbox

# docker run -d --restart=always -p 15000:5000 --name registry-mirror -v /mirror/data:/var/lib/registry -v /mirror/config:/etc/docker/registry registry:2

# Docker registry mirror: IP for VirtualBox
RM="--registry-mirror=http://localhost:15000 --mount --mount-string=$HOME/.minikube/mirror:/mirror"

minikube start --cpus=4 --memory=8192 --vm-driver=$VM --disk-size=40g --kubernetes-version=$KUBE_VER $RM $RBAC $DEV
