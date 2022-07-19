### How to build CF onprem chart locally

```shell
helm dependency update codefresh --debug
helm package codefresh
```

### How to install CF onprem chart locally

See [kcfi README.md](https://github.com/codefresh-io/kcfi#example---codefresh-onprem-installation)

or with HELM:

- obtain GCR Service Account JSON and Firebase secret from Codefresh:
```shell
DOCKER_CFG_VAR=$(echo -n "_json_key:$(echo ${GCR_SA_KEY_B64} | base64 -d)" | base64 | tr -d '\n')
REGISTRY="gcr.io"
VALUES_MAIN="values-main.yaml"
CF_APP_HOST="myonprem.local"
```

- feed them into `values.yaml`:

```shell
cat <<EOF > ${VALUES_MAIN}
global:
  appProtocol: https
  appUrl: ${CF_APP_HOST}
  seedJobs: true
  certsJobs: true

firebaseSecret: ${FIREBASE_SECRET}

dockerconfigjson:
  auths:
    ${REGISTRY}:
      auth: ${DOCKER_CFG_VAR}
EOF
```

```shell
helm repo add codefresh-onprem-prod http://charts.codefresh.io/prod
helm pull codefresh-onprem-prod/codefresh
helm upgrade --install cf codefresh-onprem-prod/codefresh -f values-main.yaml --create-namespace --namespace codefresh --debug
```

### Additional docs
[Codefresh On-Premises](https://codefresh.io/docs/docs/administration/codefresh-on-prem/)