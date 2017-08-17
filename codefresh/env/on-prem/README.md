# Installation

How to install Codefresh' helm package on an existing Kubernetes cluster (or single-node installation).

## 1. Initialize helm

```
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.5.1-linux-amd64.tar.gz -P /tmp/
tar xvf /tmp/helm-v2.5.1-linux-amd64.tar.gz -C /tmp/
chmod +x /tmp/linux-amd64/helm
sudo mv /tmp/linux-amd64/helm /usr/local/bin/

sudo helm init
sudo helm repo add codefresh http://codefresh-helm-charts.s3-website-us-east-1.amazonaws.com/
```

## 2. Install Codefresh' chart

Substitute `name.codefresh.io` with the DNS name you will use to access Codefresh' UI.
Also, add the dockercfg (base64) and firebase secret's credentials.

```
# kubectl create namespace codefresh
helm install codefresh/codefresh \
  --name cf \
  --namespace codefresh \
  --set dockercfg=<base64-dockercfg> \
  --set firebaseSecret=<firebase-secret> \
  --set ingress.domain="name.codefresh.io" \
  --set global.appUrl="name.codefresh.io"
```

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

