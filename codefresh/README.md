## Codefresh On-Premises

![Version: 2.0.0-alpha.3](https://img.shields.io/badge/Version-2.0.0--alpha.3-informational?style=flat-square) ![AppVersion: 2.0.0](https://img.shields.io/badge/AppVersion-2.0.0-informational?style=flat-square)

## Prerequisites

- Kubernetes 1.22+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure
- GCR Service Account JSON `sa.json` (provided by Codefresh, contact support@codefresh.io)
- Firebase url and secret
- Valid TLS certificates for Ingress

## Get Repo Info and Pull Chart

```console
helm repo add codefresh http://chartmuseum.codefresh.io/codefresh
helm repo update
```

## Install Chart

**Important:** only helm 3.8.0+ is supported

Edit default `values.yaml` or create empty `my-values.yaml`

- Pass `sa.json` (as a single line) to `.Values.imageCredentials.password`

```yaml
# -- Credentials for Image Pull Secret object
imageCredentials:
  registry: gcr.io
  username: _json_key
  password: '{ "type": "service_account", "project_id": "codefresh-enterprise", "private_key_id": ... }'
```

- Specify `.Values.global.appUrl`, `.Values.global.firebaseUrl` and `.Values.global.firebaseSecret`

```yaml
global:
  # -- Application root url. Will be used in Ingress as hostname
  appUrl: onprem.mydomain.com

  # -- Firebase URL for logs streaming.
  firebaseUrl: <>
  # -- Firebase Secret.
  firebaseSecret: <>
```

- Specify `.Values.ingress.tls.cert` and `.Values.ingress.tls.key` OR `.Values.ingress.tls.existingSecret`

```yaml
ingress:
  # -- Enable the Ingress
  enabled: true
  # -- Set the ingressClass that is used for the ingress.
  # Default `nginx-codefresh` is created from `ingress-nginx` controller subchart
  ingressClassName: nginx-codefresh
  tls:
    # -- Enable TLS
    enabled: true
    # -- Default secret name to be created with provided `cert` and `key` below
    secretName: "star.codefresh.io"
    # -- Certificate (base64 encoded)
    cert: ""
    # -- Private key (base64 encoded)
    key: ""
    # -- Existing `kubernetes.io/tls` type secret with TLS certificates (keys: `tls.crt`, `tls.key`)
    existingSecret: ""
```

**Important:** use `cf` as Release Name at the moment

- Install the chart

```console
helm upgrade --install cf codefresh/codefresh \
    -f my-values.yaml \
    --namespace codefresh \
    --create-namespace \
    --debug \
    --wait \
    --timeout 15m
```

## Migrating from 1.4.x onprem

TODO

## Configuration

TODO

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| argo-hub-platform | object | See below | argo-hub-platform |
| argo-platform | object | See below | argo-platform |
| builder | object | `{"enabled":true}` | builder |
| cf-broadcaster | object | See below | broadcaster |
| cf-platform-analytics-etlstarter | object | See below | etl-starter |
| cf-platform-analytics-platform | object | See below | platform-analytics |
| cfapi | object | See below | cf-api |
| cfapi-admin.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-admin.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-admin.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-admin.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-admin.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-admin.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-admin.<<.enabled | bool | `true` |  |
| cfapi-admin.enabled | bool | `false` |  |
| cfapi-buildmanager.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-buildmanager.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-buildmanager.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-buildmanager.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-buildmanager.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-buildmanager.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-buildmanager.<<.enabled | bool | `true` |  |
| cfapi-buildmanager.enabled | bool | `false` |  |
| cfapi-cacheevictmanager.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-cacheevictmanager.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-cacheevictmanager.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-cacheevictmanager.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-cacheevictmanager.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-cacheevictmanager.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-cacheevictmanager.<<.enabled | bool | `true` |  |
| cfapi-cacheevictmanager.enabled | bool | `false` |  |
| cfapi-downloadlogmanager.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-downloadlogmanager.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-downloadlogmanager.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-downloadlogmanager.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-downloadlogmanager.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-downloadlogmanager.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-downloadlogmanager.<<.enabled | bool | `true` |  |
| cfapi-downloadlogmanager.enabled | bool | `false` |  |
| cfapi-endpoints.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-endpoints.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-endpoints.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-endpoints.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-endpoints.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-endpoints.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-endpoints.<<.enabled | bool | `true` |  |
| cfapi-endpoints.enabled | bool | `false` |  |
| cfapi-environments.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-environments.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-environments.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-environments.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-environments.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-environments.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-environments.<<.enabled | bool | `true` |  |
| cfapi-environments.enabled | bool | `false` |  |
| cfapi-eventsmanagersubscriptions.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-eventsmanagersubscriptions.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-eventsmanagersubscriptions.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-eventsmanagersubscriptions.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-eventsmanagersubscriptions.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-eventsmanagersubscriptions.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-eventsmanagersubscriptions.<<.enabled | bool | `true` |  |
| cfapi-eventsmanagersubscriptions.enabled | bool | `false` |  |
| cfapi-gitops-resource-receiver.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-gitops-resource-receiver.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-gitops-resource-receiver.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-gitops-resource-receiver.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-gitops-resource-receiver.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-gitops-resource-receiver.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-gitops-resource-receiver.<<.enabled | bool | `true` |  |
| cfapi-gitops-resource-receiver.enabled | bool | `false` |  |
| cfapi-internal.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-internal.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-internal.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-internal.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-internal.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-internal.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-internal.<<.enabled | bool | `true` |  |
| cfapi-internal.enabled | bool | `false` |  |
| cfapi-kubernetes-endpoints.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-kubernetes-endpoints.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-kubernetes-endpoints.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-kubernetes-endpoints.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-kubernetes-endpoints.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-kubernetes-endpoints.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-kubernetes-endpoints.<<.enabled | bool | `true` |  |
| cfapi-kubernetes-endpoints.enabled | bool | `false` |  |
| cfapi-kubernetesresourcemonitor.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-kubernetesresourcemonitor.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-kubernetesresourcemonitor.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-kubernetesresourcemonitor.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-kubernetesresourcemonitor.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-kubernetesresourcemonitor.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-kubernetesresourcemonitor.<<.enabled | bool | `true` |  |
| cfapi-kubernetesresourcemonitor.enabled | bool | `false` |  |
| cfapi-sso-group-synchronizer.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-sso-group-synchronizer.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-sso-group-synchronizer.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-sso-group-synchronizer.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-sso-group-synchronizer.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-sso-group-synchronizer.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-sso-group-synchronizer.<<.enabled | bool | `true` |  |
| cfapi-sso-group-synchronizer.enabled | bool | `false` |  |
| cfapi-teams.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-teams.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-teams.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-teams.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-teams.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-teams.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-teams.<<.enabled | bool | `true` |  |
| cfapi-teams.enabled | bool | `false` |  |
| cfapi-terminators.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-terminators.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-terminators.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-terminators.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-terminators.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-terminators.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-terminators.<<.enabled | bool | `true` |  |
| cfapi-terminators.enabled | bool | `false` |  |
| cfapi-test-reporting.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-test-reporting.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-test-reporting.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-test-reporting.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-test-reporting.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-test-reporting.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-test-reporting.<<.enabled | bool | `true` |  |
| cfapi-test-reporting.enabled | bool | `false` |  |
| cfapi-ws.<<.container.env.AUDIT_AUTO_CREATE_DB | bool | `true` |  |
| cfapi-ws.<<.container.env.GITHUB_API_PATH_PREFIX | string | `"/api/v3"` |  |
| cfapi-ws.<<.container.env.LOGGER_LEVEL | string | `"debug"` |  |
| cfapi-ws.<<.container.env.ON_PREMISE | bool | `true` |  |
| cfapi-ws.<<.container.env.RUNTIME_MONGO_DB | string | `"codefresh"` |  |
| cfapi-ws.<<.container.image.registry | string | `"gcr.io/codefresh-enterprise"` |  |
| cfapi-ws.<<.enabled | bool | `true` |  |
| cfapi-ws.enabled | bool | `false` |  |
| cfsign | object | See below | tls-sign |
| cfui | object | See below | cf-ui |
| charts-manager | object | See below | charts-manager |
| cluster-providers | object | See below | cluster-providers |
| codefresh-tunnel-server | object | See below | codefresh-tunnel-server Don't enable! Not supported at the moment. |
| consul | object | See below | consul |
| context-manager | object | See below | context-manager |
| cronus | object | See below | cronus |
| dockerconfigjson | object | `{}` | DEPRECATED - Use `.imageCredentials` instead dockerconfig (for `kcfi` tool backward compatibility) for Image Pull Secret. Obtain GCR Service Account JSON (sa.json) at support@codefresh.io ```shell GCR_SA_KEY_B64=$(cat sa.json | base64) DOCKER_CFG_VAR=$(echo -n "_json_key:$(echo ${GCR_SA_KEY_B64} | base64 -d)" | base64 | tr -d '\n') ``` E.g.: dockerconfigjson:   auths:     gcr.io:       auth: <DOCKER_CFG_VAR> |
| gencerts | object | See below | Job to generate internal runtime secrets. Required at first install. |
| gitops-dashboard-manager | object | See below | gitops-dashboard-manager |
| global | object | See below | Global parameters |
| global.appProtocol | string | `"https"` | Application protocol. |
| global.appUrl | string | `"onprem.codefresh.local"` | Application root url. Will be used in Ingress objects as hostname |
| global.broadcasterPort | int | `80` | Default broadcaster service port. |
| global.broadcasterService | string | `"cf-broadcaster"` | Default broadcaster service name. |
| global.builderService | string | `"builder"` | Default builder service name. |
| global.certsJobs | bool | `false` | DEPRECATED - Use `.Values.gencerts` Generate self-signed certificates for internal runtime. Used in on-prem environments. |
| global.cfapiEndpointsService | string | `"cfapi"` | Default API endpoints service name |
| global.cfapiInternalPort | int | `3000` | Default API service port. |
| global.cfapiService | string | `"cfapi"` | Default API service name. |
| global.cfk8smonitorService | string | `"k8s-monitor"` | Default k8s-monitor service name. |
| global.chartsManagerPort | int | `9000` | Default chart-manager service port. |
| global.chartsManagerService | string | `"charts-manager"` | Default charts-manager service name. |
| global.clusterProvidersPort | int | `9000` | Default cluster-providers service port. |
| global.clusterProvidersService | string | `"cluster-providers"` | Default cluster-providers service name. |
| global.codefresh | string | `"codefresh"` | Keep `codefresh` as default! Global codefresh chart name. All subcharts use this name to access secrets and configmaps. |
| global.consulHttpPort | int | `8500` | Default Consul service port. |
| global.consulService | string | `"consul-headless"` | Default Consul service name. |
| global.contextManagerPort | int | `9000` | Default context-manager service port. |
| global.contextManagerService | string | `"context-manager"` | Default context-manager service name. |
| global.dnsService | string | `"kube-dns"` | Definitions to set up internal-gateway nginx resolver |
| global.env | object | `{}` | Global Env vars |
| global.firebaseSecret | string | `""` | Firebase Secret. |
| global.firebaseUrl | string | `"https://codefresh-on-prem.firebaseio.com/on-prem"` | Firebase URL for logs streaming. |
| global.gitopsDashboardManagerDatabase | string | `"pipeline-manager"` | Default gitops-dashboarad-manager db collection. |
| global.gitopsDashboardManagerPort | int | `9000` | Default gitops-dashboarad-manager service port. |
| global.gitopsDashboardManagerService | string | `"gitops-dashboard-manager"` | Default gitops-dashboarad-manager service name. |
| global.helmRepoManagerService | string | `"helm-repo-manager"` | Default helm-repo-manager service name. |
| global.hermesService | string | `"hermes"` | Default hermes service name. |
| global.imagePullSecrets | list | `[]` | Global Docker registry secret names as array |
| global.imageRegistry | string | `""` | Global Docker image registry |
| global.kubeIntegrationPort | int | `9000` | Default kube-integration service port. |
| global.kubeIntegrationService | string | `"kube-integration"` | Default kube-integration service name. |
| global.mongoURI | string | `"mongodb://cfuser:mTiXcU2wafr9@cf-mongodb:27017/?authSource=admin"` | Default Internal MongoDB URI (from bitnami/mongodb subchart). Change if you use external MongoDB. See "External MongoDB" example below. |
| global.mongodbDatabase | string | `"codefresh"` | Default MongoDB database name. |
| global.mongodbRootPassword | string | `"XT9nmM8dZD"` | Root password required for seed jobs. |
| global.mongodbRootUser | string | `"root"` | Root user required for seed jobs. |
| global.natsPort | int | `4222` | Default nats service port. |
| global.natsService | string | `"nats"` | Default nats service name. |
| global.onprem | bool | `true` | Keep `true` as default! |
| global.pipelineManagerPort | int | `9000` | Default pipeline-manager service port. |
| global.pipelineManagerService | string | `"pipeline-manager"` | Default pipeline-manager service name. |
| global.platformAnalyticsPort | int | `80` | Default platform-analytics service port. |
| global.platformAnalyticsService | string | `"platform-analytics"` | Default platform-analytics service name. |
| global.postgresDatabase | string | `"codefresh"` | Default Postgresql database name (from bitnami/postgresql subchart). Change if you use external PostreSQL. See "External Postgresql" example below. |
| global.postgresHostname | string | `""` | Set External Postgresql service address. Takes precedence over `global.postgresService`. See "External Postgresql" example below. |
| global.postgresPassword | string | `"eC9arYka4ZbH"` | Default Postgresql password (from bitnami/postgresql subchart). Change if you use external PostreSQL. See "External Postgresql" example below. |
| global.postgresPort | int | `5432` | Default Postgresql port number (from bitnami/postgresql subchart). Change if you use external PostreSQL. See "External Postgresql" example below. |
| global.postgresService | string | `"postgresql"` | Default Internal Postgresql service address (from bitnami/postgresql subchart). Change if you use external PostreSQL. See "External Postgresql" example below. |
| global.postgresUser | string | `"postgres"` | Default Postgresql username (from bitnami/postgresql subchart). Change if you use external PostreSQL. See "External Postgresql" example below. |
| global.privateRegistry | bool | `false` | DEPRECATED - Use `.Values.global.imageRegistry` instead |
| global.rabbitService | string | `"rabbitmq"` | Default Internal RabbitMQ service address (from bitnami/rabbitmq subchart). |
| global.rabbitmqHostname | string | `""` | Set External RabbitMQ service address. Takes precedence over `global.rabbitService`. See "External RabbitMQ" example below. |
| global.rabbitmqPassword | string | `"cVz9ZdJKYm7u"` | Default RabbitMQ password (from bitnami/rabbitmq subchart). Change if you use external RabbitMQ. See "External RabbitMQ" example below. |
| global.rabbitmqUsername | string | `"user"` | Default RabbitMQ username (from bitnami/rabbitmq subchart). Change if you use external RabbitMQ. See "External RabbitMQ" example below. |
| global.redisPassword | string | `"hoC9szf7NtrU"` | Default Redis password (from bitnami/redis subchart). Change if you use external Redis. See "External Redis" example below. |
| global.redisPort | int | `6379` | Default Internal Redis service port (from bitnami/redis subchart). Change if you use external Redis. See "External Redis" example below. |
| global.redisService | string | `"redis-master"` | Default Internal Redis service address (from bitnami/redis subchart). |
| global.redisUrl | string | `""` | Set External Redis service address. Takes precedence over `global.redisService` |
| global.runnerService | string | `"runner"` | Default runner service name. |
| global.runtimeEnvironmentManagerPort | int | `80` | Default runtime-environment-manager service port. |
| global.runtimeEnvironmentManagerService | string | `"runtime-environment-manager"` | Default runtime-environment-manager service name. |
| global.runtimeMongoDb | string | `"codefresh"` | Default Internal MongoDB database name |
| global.runtimeMongoURI | string | `"mongodb://cfuser:mTiXcU2wafr9@cf-mongodb:27017/?authSource=admin"` | Default Internal MongoDB URI |
| global.runtimeRedisDb | string | `"1"` | Default Redis keyspace number. |
| global.runtimeRedisHost | string | `"cf-redis-master"` | Default Internal Redis service address (from bitnami/redis subchart). |
| global.runtimeRedisPassword | string | `"hoC9szf7NtrU"` | Default Redis password. |
| global.runtimeRedisPort | string | `"6379"` | Default Redis port number. |
| global.seedJobs | bool | `false` | DEPRECATED - Use `.Values.seed.mongoSeedJob` and `.Values.seed.postgresSeedJob` and instead Instantiate databases with seed data. Used in on-prem environments. |
| global.storageClass | string | `""` | Global StorageClass for Persistent Volume(s) |
| global.tlsSignPort | int | `4999` | Default tls-sign service port. |
| global.tlsSignService | string | `"cfsign"` | Default tls-sign service name. |
| helm-repo-manager | object | See below | helm-repo-manager |
| hermes | object | See below | hermes |
| hooks | object | `{"affinity":{},"enabled":true,"image":{"registry":"docker.io","repository":"bitnami/mongodb","tag":4.2},"nodeSelector":{},"podSecurityContext":{},"resources":{},"tolerations":[]}` | Pre/post-upgrade Job hooks. Updates images in `system/default` runtime. |
| imageCredentials | object | `{}` | Credentials for Image Pull Secret object |
| ingress | object | `{"annotations":{"nginx.ingress.kubernetes.io/configuration-snippet":"more_set_headers \"X-Request-ID: $request_id\";\nproxy_set_header X-Request-ID $request_id;\n","nginx.ingress.kubernetes.io/service-upstream":"true","nginx.ingress.kubernetes.io/ssl-redirect":"false","nginx.org/redirect-to-https":"false"},"enabled":true,"ingressClassName":"nginx-codefresh","services":{"cfapi":["/api/","/ws"],"cfui":["/"],"nomios":["/nomios/"]},"tls":{"cert":"","enabled":false,"existingSecret":"","key":"","secretName":"star.codefresh.io"}}` | Ingress |
| ingress-nginx | object | See below | ingress-nginx |
| ingress.annotations | object | See below | Set annotations for ingress. |
| ingress.enabled | bool | `true` | Enable the Ingress |
| ingress.ingressClassName | string | `"nginx-codefresh"` | Set the ingressClass that is used for the ingress. Default `nginx-codefresh` is created from `ingress-nginx` controller subchart |
| ingress.services | object | See below | Default services and corresponding paths |
| ingress.tls.cert | string | `""` | Certificate (base64 encoded) |
| ingress.tls.enabled | bool | `false` | Enable TLS |
| ingress.tls.existingSecret | string | `""` | Existing `kubernetes.io/tls` type secret with TLS certificates (keys: `tls.crt`, `tls.key`) |
| ingress.tls.key | string | `""` | Private key (base64 encoded) |
| ingress.tls.secretName | string | `"star.codefresh.io"` | Default secret name to be created with provided `cert` and `key` below |
| internal-gateway | object | See below | internal-gateway |
| internal-gateway.libraryMode | bool | `true` | Do not change this value! Breaks chart logic |
| k8s-monitor | object | See below | k8s-monitor |
| kube-integration | object | See below | kube-integration |
| mongodb | object | See below | mongodb |
| nats | object | See below | nats |
| nomios | object | See below | nomios |
| pipeline-manager | object | See below | pipeline-manager |
| postgresql | object | See below | postgresql |
| rabbitmq | object | See below | rabbitmq |
| redis | object | See below | redis |
| runtime-environment-manager | object | See below | runtime-environment-manager |
| runtimeImages | object | See below | runtimeImages |
| seed | object | See below | Seed jobs |
| seed.enabled | bool | `true` | Disable all seed jobs |
| seed.mongoSeedJob | object | See below | Mongo Seed Job. Required at first install. Seeds the required data (default idp/user/account), creates cfuser and required databases. |
| seed.postgresSeedJob | object | See below | Postgres Seed Job. Required at first install. Creates required user and databases. |
| tasker-kubernetes | object | `{"container":{"image":{"registry":"gcr.io/codefresh-enterprise"}},"enabled":true}` | tasker-kubernetes |
| webTLS | object | `{"cert":"","enabled":false,"key":"","secretName":"star.codefresh.io"}` | DEPRECATED - Use `.Values.ingress.tls` instead TLS secret for Ingress |