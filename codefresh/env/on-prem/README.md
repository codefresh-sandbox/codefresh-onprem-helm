# Installation

On-prem Codefresh installations are done in two phases. First, a single-node
Kubernetes cluster is installed, then, a helm package is deployed to a working
cluster.

Both these phases are covered by the scripts in the [k8s-single-node-installer](https://github.com/codefresh-io/k8s-single-node-installer)

To install a single-node cluster, run the `installer` script.

To install the helm package into a cluster you created, run the `cf-helm` script.

# Packaging (for administrators)

How to prepare a new on-prem package.

## 1. Build, tag and push new on-prem Docker images

The images should be pushed to the `codefresh-enterprise` project.

For example, cf-ui image is at `gcr.io/codefresh-enterprise/cf-ui:onprem-v20`

## 2. Adjust the `env/on-prem/values.yml` file

Mainly, change the imageTags to the updated versions. You might need to decrypt the file with `sops` first.

Before packaging a new version, copy `env/on-prem/values.yml` instead of the main `codefresh/values.yml` file.
We are doing so to simplify on-prem installations, we want to avoid shipping a
values file along the on-prem package and instead make the on-prem values the
defaults for the package.

## 3. Package and update helm repo

```
helm dependency update codefresh/

helm package codefresh

wget http://codefresh-helm-charts.s3-website-us-east-1.amazonaws.com/index.yaml
helm repo index . --merge index.yaml --url http://codefresh-helm-charts.s3-website-us-east-1.amazonaws.com

s3cmd cp index.yaml s3://codefresh-helm-charts/
s3cmd cp <package-full-name>.tgz s3://codefresh-helm-charts/
```

