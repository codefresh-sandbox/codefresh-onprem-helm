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

minikube start --cpus=4 --memory=8192 --vm-driver=$VM --disk-size=40g --kubernetes-version=$KUBE_VER $RBAC $DEV
