#!/bin/sh

# install xhive docker machine vm driver
brew install docker-machine-driver-xhyve

# uncomment to enable RBAC
# RBAC="--extra-config=apiserver.Authorization.Mode=RBAC"

minikube start --cpus=4 --memory=8192 --vm-driver=xhyve --disk-size=40g $RBAC