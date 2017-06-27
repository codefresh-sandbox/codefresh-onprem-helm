#!/bin/sh

# install xhive docker machine vm driver
brew install docker-machine-driver-xhyve

# uncomment to enable RBAC
# RBAC="--extra-config=apiserver.Authorization.Mode=RBAC"

# uncomment to enable development on localhost
# DEV="--network-plugin=kubenet --extra-config=kubelet.PodCIDR=10.10.0.0/24 --extra-config=kubelet.NonMasqueradeCIDR=10.10.0.0/24"

minikube start --cpus=4 --memory=8192 --vm-driver=xhyve --disk-size=40g $RBAC $DEV
