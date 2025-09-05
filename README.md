## Codefresh On-Premises

![Version: 2.8.0](https://img.shields.io/badge/Version-2.8.0-informational?style=flat-square) ![AppVersion: 2.7.0](https://img.shields.io/badge/AppVersion-2.7.0-informational?style=flat-square)

Helm chart for deploying [Codefresh On-Premises](https://codefresh.io/docs/docs/getting-started/intro-to-codefresh/) to Kubernetes.

## Table of Content

- [Prerequisites](#prerequisites)
- [Get Repo Info](#get-repo-info)
- [Install Chart](#install-chart)
- [Chart Configuration](#chart-configuration)
  - [Persistent services](#persistent-services)
  - [Configuring external services](#configuring-external-services)
    - [External MongoDB](#external-mongodb)
    - [External MongoDB with MTLS](#external-mongodb-with-mtls)
    - [External PostgresSQL](#external-postgressql)
    - [External Redis](#external-redis)
    - [External Redis with MTLS](#external-redis-with-mtls)
    - [External RabbitMQ](#external-rabbitmq)
  - [Configuring Ingress-NGINX](#configuring-ingress-nginx)
    - [ELB with SSL Termination (Classic Load Balancer)](#elb-with-ssl-termination-classic-load-balancer)
    - [NLB (Network Load Balancer)](#nlb-network-load-balancer)
  - [Configuration with ALB (Application Load Balancer)](#configuration-with-alb-application-load-balancer)
  - [Configuration with Private Registry](#configuration-with-private-registry)
  - [Configuration with multi-role CF-API](#configuration-with-multi-role-cf-api)
  - [Indexes in MongoDB](#indexes-in-mongodb)
  - [High Availability](#high-availability)
  - [Mounting private CA certs](#mounting-private-ca-certs)
- [Installing on OpenShift](#installing-on-openshift)
- [Firebase Configuration](#firebase-configuration)
- [Additional configuration](#additional-configuration)
  - [Retention policy for builds and logs](#retention-policy-for-builds-and-logs)
  - [Projects pipelines limit](#projects-pipelines-limit)
  - [Enable session cookie](#enable-session-cookie)
  - [X-Frame-Options response header](#x-frame-options-response-header)
  - [Image digests in containers](#image-digests-in-containers)
- [Configuring OIDC Provider](#configuring-oidc-provider)
- [Upgrading](#upgrading)
  - [To 2.0.0](#to-2-0-0)
  - [To 2.0.12](#to-2-0-12)
  - [To 2.0.17](#to-2-0-17)
  - [To 2.1.0](#to-2-1-0)
  - [To 2.1.7](#to-2-1-7)
  - [To 2.2.0](#to-2-2-0)
  - [To 2.3.0](#to-2-3-0)
  - [To 2.4.0](#to-2-4-0)
  - [To 2.5.0](#to-2-5-0)
  - [To 2.6.0](#to-2-6-0)
  - [To 2.7.0](#to-2-7-0)
  - [To 2.8.0](#to-2-8-0)
- [Rollback](#rollback)
- [Troubleshooting](#troubleshooting)
- [Values](#values)

⚠️⚠️⚠️
> Since version 2.1.7 chart is pushed **only** to OCI registry at `oci://quay.io/codefresh/codefresh`

> Versions prior to 2.1.7 are still available in ChartMuseum at `http://chartmuseum.codefresh.io/codefresh`

## Prerequisites

- Kubernetes **>= 1.28 && <= 1.32** (Supported versions mean that installation passed for the versions listed; however, it **may** work on older k8s versions as well)
- Helm **3.8.0+**
- PV provisioner support in the underlying infrastructure (with [resizing](https://kubernetes.io/blog/2018/07/12/resizing-persistent-volumes-using-kubernetes/) available)
- Minimal 4vCPU and 8Gi Memory available in the cluster (for production usage the recommended minimal cluster capacity is at least 12vCPUs and 36Gi Memory)
- GCR Service Account JSON `sa.json` (provided by Codefresh, contact support@codefresh.io)
- Firebase [Realtime Database URL](https://firebase.google.com/docs/database/web/start#create_a_database) with [legacy token](https://firebase.google.com/docs/database/rest/auth#legacy_tokens). See [Firebase Configuration](#firebase-configuration)
- Valid TLS certificates for Ingress
- When [external](#external-postgressql) PostgreSQL is used, `pg_cron` and `pg_partman` extensions **must be enabled** for [analytics](https://codefresh.io/docs/docs/dashboards/home-dashboard/#pipelines-dashboard) to work (see [AWS RDS example](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL_pg_cron.html#PostgreSQL_pg_cron.enable))

## Get Repo Info

```console
helm show all oci://quay.io/codefresh/codefresh
```
See [Use OCI-based registries](https://helm.sh/docs/topics/registries/)

## Install Chart

**Important:** only helm 3.8.0+ is supported

**Important:** Read about [Indexes in MongoDB](#indexes-in-mongodb) before installation

Edit default `values.yaml` or create empty `cf-values.yaml`

- Pass `sa.json` (as a single line) to `.Values.imageCredentials.password`

```yaml
# -- Credentials for Image Pull Secret object
imageCredentials:
  registry: us-docker.pkg.dev
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
  # -- Firebase URL for logs streaming from existing secret
  firebaseUrlSecretKeyRef: {}
  # E.g.
  # firebaseUrlSecretKeyRef:
  #   name: my-secret
  #   key: firebase-url

  # -- Firebase Secret.
  firebaseSecret: <>
  # -- Firebase Secret from existing secret
  firebaseSecretSecretKeyRef: {}
  # E.g.
  # firebaseSecretSecretKeyRef:
  #   name: my-secret
  #   key: firebase-secret

  env:
    MONGOOSE_AUTO_INDEX: "true"
    MONGO_AUTOMATIC_INDEX_CREATION: "true"

```

- Specify `.Values.ingress.tls.cert` and `.Values.ingress.tls.key` OR `.Values.ingress.tls.existingSecret`

```yaml
ingress:
  # -- Enable the Ingress
  enabled: true
  # -- Set the ingressClass that is used for the ingress.
  # Default `nginx-codefresh` is created from `ingress-nginx` controller subchart
  # If you specify a different ingress class, disable `ingress-nginx` subchart (see below)
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

ingress-nginx:
  # -- Enable ingress-nginx controller
  enabled: true
```

- *Or specify your own `.Values.ingress.ingressClassName` (disable built-in ingress-nginx subchart)*

```yaml
ingress:
  # -- Enable the Ingress
  enabled: true
  # -- Set the ingressClass that is used for the ingress.
  ingressClassName: nginx

ingress-nginx:
  # -- Disable ingress-nginx controller
  enabled: false
```

- Install the chart

```console
  helm upgrade --install cf oci://quay.io/codefresh/codefresh \
      -f cf-values.yaml \
      --namespace codefresh \
      --create-namespace \
      --debug \
      --wait \
      --timeout 15m
  ```

## Chart Configuration

See [Customizing the Chart Before Installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with detailed comments, visit the chart's [values.yaml](./values.yaml), or run these configuration commands:

```console
helm show values codefresh/codefresh
```

### Persistent services

The following table displays the list of **persistent** services created as part of the on-premises installation:

| Database      | Purpose | Required version     |
| :---        | :----   |  :--- |
| MongoDB      | Stores all account data (account settings, users, projects, pipelines, builds etc.)       | 7.x   |
| Postgresql   | Stores data about events for the account (pipeline updates, deletes, etc.). The audit log uses the data from this database.        | 17.x      |
| Redis   | Used for caching, and as a key-value store for cron trigger manager.        | 7.0.x      |
| RabbitMQ  | Used for message queueing.        | 4.0.x      |

> Running on netfs (nfs, cifs) is not recommended.

> Docker daemon (`cf-builder` stateful set) can be run on block storage only.

All of them can be externalized. See the next sections.

### Configuring external services

The chart contains required dependencies for the corresponding services
- [bitnami/mongodb](https://github.com/bitnami/charts/tree/main/bitnami/mongodb)
- [bitnami/postgresql](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)
- [bitnami/redis](https://github.com/bitnami/charts/tree/main/bitnami/redis)
- [bitnami/rabbitmq](https://github.com/bitnami/charts/tree/main/bitnami/rabbitmq)

However, you might need to use external services like [MongoDB Atlas Database](https://www.mongodb.com/atlas/database) or [Amazon RDS for PostgreSQL](https://aws.amazon.com/rds/postgresql/). In order to use them, adjust the values accordingly:

#### External MongoDB

```yaml
seed:
  mongoSeedJob:
    # -- Enable mongo seed job. Seeds the required data (default idp/user/account), creates cfuser and required databases.
    enabled: true
    # -- Root user in plain text (required ONLY for seed job!).
    mongodbRootUser: "root"
    # -- Root user from existing secret
    mongodbRootUserSecretKeyRef: {}
    # E.g.
    # mongodbRootUserSecretKeyRef:
    #   name: my-secret
    #   key: mongodb-root-user

    # -- Root password in plain text (required ONLY for seed job!).
    mongodbRootPassword: "password"
    # -- Root password from existing secret
    mongodbRootPasswordSecretKeyRef: {}
    # E.g.
    # mongodbRootPasswordSecretKeyRef:
    #   name: my-secret
    #   key: mongodb-root-password

global:
  # -- LEGACY (but still supported) - Use `.global.mongodbProtocol` + `.global.mongodbUser/mongodbUserSecretKeyRef` + `.global.mongodbPassword/mongodbPasswordSecretKeyRef` + `.global.mongodbHost/mongodbHostSecretKeyRef` + `.global.mongodbOptions` instead
  # Default MongoDB URI. Will be used by ALL services to communicate with MongoDB.
  # Ref: https://www.mongodb.com/docs/manual/reference/connection-string/
  # Note! `defaultauthdb` is omitted on purpose (i.e. mongodb://.../[defaultauthdb]).
  mongoURI: ""
  # E.g.
  # mongoURI: "mongodb://cfuser:mTiXcU2wafr9@cf-mongodb:27017/"

  # -- Set mongodb protocol (`mongodb` / `mongodb+srv`)
  mongodbProtocol: mongodb
  # -- Set mongodb user in plain text
  mongodbUser: "cfuser"
  # -- Set mongodb user from existing secret
  mongodbUserSecretKeyRef: {}
  # E.g.
  # mongodbUserSecretKeyRef:
  #   name: my-secret
  #   key: mongodb-user

  # -- Set mongodb password in plain text
  mongodbPassword: "password"
  # -- Set mongodb password from existing secret
  mongodbPasswordSecretKeyRef: {}
  # E.g.
  # mongodbPasswordSecretKeyRef:
  #   name: my-secret
  #   key: mongodb-password

  # -- Set mongodb host in plain text
  mongodbHost: "my-mongodb.prod.svc.cluster.local:27017"
  # -- Set mongodb host from existing secret
  mongodbHostSecretKeyRef: {}
  # E.g.
  # mongodbHostSecretKeyRef:
  #   name: my-secret
  #   key: monogdb-host

  # -- Set mongodb connection string options
  # Ref: https://www.mongodb.com/docs/manual/reference/connection-string/#connection-string-options
  mongodbOptions: "retryWrites=true"

mongodb:
  # -- Disable mongodb subchart installation
  enabled: false
```

#### External MongoDB with MTLS

In order to use MTLS (Mutual TLS) for MongoDB, you need:

* Create a K8S secret that contains the certificate (certificate file and private key).
  The K8S secret should have one `ca.pem` key.
```console
cat cert.crt > ca.pem
cat cert.key >> ca.pem
kubectl create secret generic my-mongodb-tls --from-file=ca.pem
```

*  Add `.Values.global.volumes` and `.Values.global.volumeMounts` to mount the secret into all the services.
```yaml
global:
  volumes:
    mongodb-tls:
      enabled: true
      type: secret
      nameOverride: my-mongodb-tls
      optional: true

  volumeMounts:
    mongodb-tls:
      path:
      - mountPath: /etc/ssl/mongodb/ca.pem
        subPath: ca.pem

  env:
    MONGODB_SSL_ENABLED: true
    MTLS_CERT_PATH: /etc/ssl/mongodb/ca.pem
    RUNTIME_MTLS_CERT_PATH: /etc/ssl/mongodb/ca.pem
    RUNTIME_MONGO_TLS: "true"
    # Set these env vars to 'false' if self-signed certificate is used to avoid x509 errors
    RUNTIME_MONGO_TLS_VALIDATE: "false"
    MONGO_MTLS_VALIDATE: "false"
```

#### External PostgresSQL

```yaml
seed:
  postgresSeedJob:
    # -- Enable postgres seed job. Creates required user and databases.
    enabled: true
    # -- (optional) "postgres" admin user in plain text (required ONLY for seed job!)
    # Must be a privileged user allowed to create databases and grant roles.
    # If omitted, username and password from `.Values.global.postgresUser/postgresPassword` will be used.
    postgresUser: "postgres"
    # -- (optional) "postgres" admin user from exising secret
    postgresUserSecretKeyRef: {}
    # E.g.
    # postgresUserSecretKeyRef:
    #   name: my-secret
    #   key: postgres-user

    # -- (optional) Password for "postgres" admin user (required ONLY for seed job!)
    postgresPassword: "password"
    # -- (optional) Password for "postgres" admin user from existing secret
    postgresPasswordSecretKeyRef: {}
    # E.g.
    # postgresPasswordSecretKeyRef:
    #   name: my-secret
    #   key: postgres-password

global:
  # -- Set postgres user in plain text
  postgresUser: cf_user
  # -- Set postgres user from existing secret
  postgresUserSecretKeyRef: {}
  # E.g.
  # postgresUserSecretKeyRef:
  #   name: my-secret
  #   key: postgres-user

  # -- Set postgres password in plain text
  postgresPassword: password
  # -- Set postgres password from existing secret
  postgresPasswordSecretKeyRef: {}
  # E.g.
  # postgresPasswordSecretKeyRef:
  #   name: my-secret
  #   key: postgres-password

  # -- Set postgres service address in plain text.
  postgresHostname: "my-postgres.domain.us-east-1.rds.amazonaws.com"
  # -- Set postgres service from existing secret
  postgresHostnameSecretKeyRef: {}
  # E.g.
  # postgresHostnameSecretKeyRef:
  #   name: my-secret
  #   key: postgres-hostname

  # -- Set postgres port number
  postgresPort: 5432

postgresql:
  # -- Disable postgresql subchart installation
  enabled: false
```

#### External Redis

```yaml
global:
  # -- Set redis password in plain text
  redisPassword: password
  # -- Set redis service port
  redisPort: 6379
  # -- Set redis password from existing secret
  redisPasswordSecretKeyRef: {}
  # E.g.
  # redisPasswordSecretKeyRef:
  #   name: my-secret
  #   key: redis-password

  # -- Set redis hostname in plain text. Takes precedence over `global.redisService`!
  redisUrl: "my-redis.namespace.svc.cluster.local"
  # -- Set redis hostname from existing secret.
  redisUrlSecretKeyRef: {}
  # E.g.
  # redisUrlSecretKeyRef:
  #   name: my-secret
  #   key: redis-url

redis:
  # -- Disable redis subchart installation
  enabled: false

```

> If ElastiCache is used, set `REDIS_TLS` to `true` in `.Values.global.env`

```
global:
  env:
    REDIS_TLS: true
```

#### External Redis with MTLS

In order to use [MTLS (Mutual TLS) for Redis](https://redis.io/docs/management/security/encryption/), you need:

* Create a K8S secret that contains the certificate (ca, certificate and private key).
```console
cat ca.crt tls.crt > tls.crt
kubectl create secret tls my-redis-tls --cert=tls.crt --key=tls.key --dry-run=client -o yaml | kubectl apply -f -
```

*  Add `.Values.global.volumes` and `.Values.global.volumeMounts` to mount the secret into all the services.
```yaml
global:
  volumes:
    redis-tls:
      enabled: true
      type: secret
      # Existing secret with TLS certificates (keys: `ca.crt` , `tls.crt`, `tls.key`)
      nameOverride: my-redis-tls
      optional: true

  volumeMounts:
    redis-tls:
      path:
      - mountPath: /etc/ssl/redis

  env:
    REDIS_TLS: true
    REDIS_CA_PATH: /etc/ssl/redis/ca.crt
    REDIS_CLIENT_CERT_PATH : /etc/ssl/redis/tls.crt
    REDIS_CLIENT_KEY_PATH: /etc/ssl/redis/tls.key
    # Set these env vars like that if self-signed certificate is used to avoid x509 errors
    REDIS_REJECT_UNAUTHORIZED: false
    REDIS_TLS_SKIP_VERIFY: true
```

#### External RabbitMQ

```yaml
global:
  # -- Set rabbitmq protocol (`amqp/amqps`)
  rabbitmqProtocol: amqp
  # -- Set rabbitmq username in plain text
  rabbitmqUsername: user
  # -- Set rabbitmq username from existing secret
  rabbitmqUsernameSecretKeyRef: {}
  # E.g.
  # rabbitmqUsernameSecretKeyRef:
  #   name: my-secret
  #   key: rabbitmq-username

  # -- Set rabbitmq password in plain text
  rabbitmqPassword: password
  # -- Set rabbitmq password from existing secret
  rabbitmqPasswordSecretKeyRef: {}
  # E.g.
  # rabbitmqPasswordSecretKeyRef:
  #   name: my-secret
  #   key: rabbitmq-password

  # -- Set rabbitmq service address in plain text. Takes precedence over `global.rabbitService`!
  rabbitmqHostname: "my-rabbitmq.namespace.svc.cluster.local:5672"
  # -- Set rabbitmq service address from existing secret.
  rabbitmqHostnameSecretKeyRef: {}
  # E.g.
  # rabbitmqHostnameSecretKeyRef:
  #   name: my-secret
  #   key: rabbitmq-hostname

rabbitmq:
  # -- Disable rabbitmq subchart installation
  enabled: false
```

### Configuring Ingress-NGINX

The chart deploys the [ingress-nginx](https://github.com/kubernetes/ingress-nginx/tree/main) and exposes controller behind a Service of `Type=LoadBalancer`

All installation options for `ingress-nginx` are described at [Configuration](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx#configuration)

Relevant examples for Codefesh are below:

#### ELB with SSL Termination (Classic Load Balancer)

*certificate provided from ACM*

```yaml
ingress-nginx:
  controller:
    service:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
        service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
        service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '3600'
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: < CERTIFICATE ARN >
      targetPorts:
        http: http
        https: http

# -- Ingress
ingress:
  tls:
    # -- Disable TLS
    enabled: false
```

#### NLB (Network Load Balancer)

*certificate provided as base64 string or as exisiting k8s secret*

```yaml
ingress-nginx:
  controller:
    service:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: nlb
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
        service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '3600'
        service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: 'true'

# -- Ingress
ingress:
  tls:
    # -- Enable TLS
    enabled: true
    # -- Default secret name to be created with provided `cert` and `key` below
    secretName: "star.codefresh.io"
    # -- Certificate (base64 encoded)
    cert: "LS0tLS1CRUdJTiBDRVJ...."
    # -- Private key (base64 encoded)
    key: "LS0tLS1CRUdJTiBSU0E..."
    # -- Existing `kubernetes.io/tls` type secret with TLS certificates (keys: `tls.crt`, `tls.key`)
    existingSecret: ""
```

### Configuration with ALB (Application Load Balancer)

*[Application Load Balancer](https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller) should be deployed to the cluster*

```yaml
ingress-nginx:
  # -- Disable ingress-nginx subchart installation
  enabled: false

ingress:
  # -- ALB contoller ingress class
  ingressClassName: alb
  annotations:
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig":{ "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/certificate-arn: <ARN>
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/success-codes: 200,404
    alb.ingress.kubernetes.io/target-type: ip
 services:
    # For ALB /* asterisk is required in path
    internal-gateway:
      - /*

```

### Configuration with Private Registry

If you install/upgrade Codefresh on an air-gapped environment without access to public registries (i.e. `quay.io`/`docker.io`) or Codefresh Enterprise registry at `gcr.io`, you will have to mirror the images to your organization’s container registry.

- Obtain [image list](https://github.com/codefresh-io/onprem-images/tree/master/releases) for specific release

- [Push images](https://github.com/codefresh-io/onprem-images/blob/master/push-to-registry.sh) to private docker registry

- Specify image registry in values

```yaml
global:
  imageRegistry: myregistry.domain.com

```

There are 3 types of images, with the values above in rendered manifests images will be converted as follows:

**non-Codefresh** like:

```yaml
bitnami/mongo:4.2
registry.k8s.io/ingress-nginx/controller:v1.4.0
postgres:13
```
converted to:
```yaml
myregistry.domain.com/bitnami/mongodb:4.2
myregistry.domain.com/ingress-nginx/controller:v1.2.0
myregistry.domain.com/postgres:13
```

Codefresh **public** images like:
```yaml
quay.io/codefresh/dind:20.10.13-1.25.2
quay.io/codefresh/engine:1.147.8
quay.io/codefresh/cf-docker-builder:1.1.14
```
converted to:
```yaml
myregistry.domain.com/codefresh/dind:20.10.13-1.25.2
myregistry.domain.com/codefresh/engine:1.147.8
myregistry.domain.com/codefresh/cf-docker-builder:1.1.14
```

Codefresh **private** images like:
```yaml
gcr.io/codefresh-enterprise/codefresh/cf-api:21.153.6
gcr.io/codefresh-enterprise/codefresh/cf-ui:14.69.38
gcr.io/codefresh-enterprise/codefresh/pipeline-manager:3.121.7
```
converted to:

```yaml
myregistry.domain.com/codefresh/cf-api:21.153.6
myregistry.domain.com/codefresh/cf-ui:14.69.38
myregistry.domain.com/codefresh/pipeline-manager:3.121.7
```

Use the example below to override repository for all templates:

```yaml

global:
  imagePullSecrets:
    - cf-registry

ingress-nginx:
  controller:
    image:
      registry: myregistry.domain.com
      image: codefresh/controller

mongodb:
  image:
    repository: codefresh/mongodb

postgresql:
  image:
    repository: codefresh/postgresql

consul:
  image:
    repository: codefresh/consul

redis:
  image:
    repository: codefresh/redis

rabbitmq:
  image:
    repository: codefresh/rabbitmq

nats:
  image:
    repository: codefresh/nats

builder:
  container:
    image:
      repository: codefresh/docker

runner:
  container:
    image:
      repository: codefresh/docker

internal-gateway:
  container:
    image:
      repository: codefresh/nginx-unprivileged

helm-repo-manager:
  chartmuseum:
    image:
      repository: myregistry.domain.com/codefresh/chartmuseum

cf-platform-analytics-platform:
  redis:
    image:
      repository: codefresh/redis
```

### Configuration with multi-role CF-API

The chart installs cf-api as a single deployment. Though, at a larger scale, we do recommend to split cf-api to multiple roles (one deployment per role) as follows:

```yaml

global:
  # -- Change internal cfapi service address
  cfapiService: cfapi-internal
  # -- Change endpoints cfapi service address
  cfapiEndpointsService: cfapi-endpoints

cfapi: &cf-api
  # -- Disable default cfapi deployment
  enabled: false
  # -- (optional) Enable the autoscaler
  # The value will be merged into each cfapi role. So you can specify it once.
  hpa:
    enabled: true
# Enable cf-api roles
cfapi-auth:
  <<: *cf-api
  enabled: true
cfapi-internal:
  <<: *cf-api
  enabled: true
cfapi-ws:
  <<: *cf-api
  enabled: true
cfapi-admin:
  <<: *cf-api
  enabled: true
cfapi-endpoints:
  <<: *cf-api
  enabled: true
cfapi-terminators:
  <<: *cf-api
  enabled: true
cfapi-sso-group-synchronizer:
  <<: *cf-api
  enabled: true
cfapi-buildmanager:
  <<: *cf-api
  enabled: true
cfapi-cacheevictmanager:
  <<: *cf-api
  enabled: true
cfapi-eventsmanagersubscriptions:
  <<: *cf-api
  enabled: true
cfapi-kubernetesresourcemonitor:
  <<: *cf-api
  enabled: true
cfapi-environments:
  <<: *cf-api
  enabled: true
cfapi-gitops-resource-receiver:
  <<: *cf-api
  enabled: true
cfapi-downloadlogmanager:
  <<: *cf-api
  enabled: true
cfapi-teams:
  <<: *cf-api
  enabled: true
cfapi-kubernetes-endpoints:
  <<: *cf-api
  enabled: true
cfapi-test-reporting:
  <<: *cf-api
  enabled: true
```

⚠️ ⚠️ ⚠️
### Indexes in MongoDB
⚠️ ⚠️ ⚠️

Indexes in MongoDB are essential for efficient query performance, especially as your data grows. Without proper indexes, MongoDB must perform full collection scans to find matching documents, which can significantly slow down operations and increase resource usage. For production environments, ensuring that all frequently queried fields are indexed is vital to maintain optimal performance and scalability.

Auto-index creation in MongoDB is disabled by default in Codefresh On-Prem to prevent unexpected performance issues in production environments during upgrades. When enabled, MongoDB will automatically create indexes for fields used in queries, which can lead to high CPU and disk usage, increased I/O, and potential service disruptions—especially on large datasets. By requiring manual index management, administrators can plan index creation during maintenance windows, ensuring system stability and predictable performance before upgrading Codefresh On-Prem.

It is critical to ensure that your MongoDB indexes are always aligned with the latest recommended state for your Codefresh On-Prem version. Outdated or missing indexes can lead to degraded performance, slow queries, and increased resource consumption. Always review release notes and update or create indexes as specified during upgrades or when new collections/fields are introduced. Regularly auditing and maintaining your indexes helps ensure optimal system reliability and scalability.

The indexes list is located at the [codefresh-io/codefresh-onprem-helm](https://github.com/codefresh-io/codefresh-onprem-helm/tree/onprem-2.8.0/indexes) repository.
The indexes are stored in JSON files with keys and options specified.

The directory structure is:

```console
codefresh-onprem-helm
├── indexes
│   ├── <DB_NAME> # MongoDB database name
│   │   ├── <COLLECTION_NAME>.json # MongoDB indexes for the specified collection
```

#### Enabling auto-index creation

For first-time installations, you **must** enable auto-index creation by setting the following values:

```yaml
global:
  env:
    MONGOOSE_AUTO_INDEX: "true"
    MONGO_AUTOMATIC_INDEX_CREATION: "true"
```

You **should** disable it for the next upgrades by setting these variables to `false`:

```yaml
global:
  env:
    MONGOOSE_AUTO_INDEX: "false"
    MONGO_AUTOMATIC_INDEX_CREATION: "false"
```

#### Creating Indexes manually

> **Note!** If you have a large amount of MongoDB data, it is recommended to create indexes manually. Enabling auto-index creation can cause performance degradation during the index creation process with large datasets.

Depending on your MongoDB service (e.g., Atlas, self-hosted), you can create indexes using the MongoDB shell or the Atlas UI.

Ref:
- [Create an Index in Atlas DB](https://www.mongodb.com/docs/atlas/atlas-ui/indexes/#create-an-index)
- [Create an Index with mongosh](https://www.mongodb.com/docs/manual/reference/method/db.collection.createIndex/)

### High Availability

The chart installs the non-HA version of Codefresh by default. If you want to run Codefresh in HA mode, use the example values below.

> **Note!** `cronus` is not supported in HA mode, otherwise builds with CRON triggers will be duplicated

`values.yaml`
```yaml
cfapi:
  hpa:
    enabled: true
    # These are the defaults for all Codefresh subcharts
    # minReplicas: 2
    # maxReplicas: 10
    # targetCPUUtilizationPercentage: 70

argo-platform:
  abac:
    hpa:
      enabled: true

  analytics-reporter:
    hpa:
      enabled: true

  api-events:
    hpa:
      enabled: true

  api-graphql:
    hpa:
      enabled: true

  audit:
    hpa:
      enabled: true

  cron-executor:
    hpa:
      enabled: true

  event-handler:
    hpa:
      enabled: true

  ui:
    hpa:
      enabled: true

cfui:
  hpa:
    enabled: true

internal-gateway:
  hpa:
    enabled: true

cf-broadcaster:
  hpa:
    enabled: true

cf-platform-analytics-platform:
  hpa:
    enabled: true

charts-manager:
  hpa:
    enabled: true

cluster-providers:
  hpa:
    enabled: true

context-manager:
  hpa:
    enabled: true

gitops-dashboard-manager:
  hpa:
    enabled: true

helm-repo-manager:
  hpa:
    enabled: true

hermes:
  hpa:
    enabled: true

k8s-monitor:
  hpa:
    enabled: true

kube-integration:
  hpa:
    enabled: true

nomios:
  hpa:
    enabled: true

pipeline-manager:
  hpa:
    enabled: true

runtime-environment-manager:
  hpa:
    enabled: true

tasker-kubernetes:
  hpa:
    enabled: true

```

For infra services (MongoDB, PostgreSQL, RabbitMQ, Redis, Consul, Nats, Ingress-NGINX) from built-in Bitnami charts you can use the following example:

> **Note!** Use [topologySpreadConstraints](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/#spread-constraints-for-pods) for better resiliency

`values.yaml`
```yaml
global:
  postgresService: postgresql-ha-pgpool
  mongodbHost: cf-mongodb-0,cf-mongodb-1,cf-mongodb-2  # Replace `cf` with your Helm Release name
  mongodbOptions: replicaSet=rs0&retryWrites=true
  redisUrl: cf-redis-ha-haproxy

builder:
  controller:
    replicas: 3

consul:
  replicaCount: 3

cfsign:
  controller:
    replicas: 3
  persistence:
    certs-data:
      enabled: false
  volumes:
    certs-data:
      type: emptyDir
  initContainers:
    volume-permissions:
      enabled: false

ingress-nginx:
  controller:
    autoscaling:
      enabled: true

mongodb:
  architecture: replicaset
  replicaCount: 3
  externalAccess:
    enabled: true
    service:
      type: ClusterIP

nats:
  replicaCount: 3

postgresql:
  enabled: false

postgresql-ha:
  enabled: true
  volumePermissions:
    enabled: true

rabbitmq:
  replicaCount: 3

redis:
  enabled: false

redis-ha:
  enabled: true
```

### Mounting private CA certs

```yaml
global:
  env:
    NODE_EXTRA_CA_CERTS: /etc/ssl/custom/ca.crt

  volumes:
    custom-ca:
      enabled: true
      type: secret
      existingName: my-custom-ca-cert # exisiting K8s secret object with the CA cert
      optional: true

  volumeMounts:
    custom-ca:
      path:
      - mountPath: /etc/ssl/custom/ca.crt
        subPath: ca.crt
```

## Installing on OpenShift

To deploy Codefresh On-Prem on OpenShift use the following values example:

```yaml
ingress:
  ingressClassName: openshift-default

global:
  dnsService: dns-default
  dnsNamespace: openshift-dns
  clusterDomain: cluster.local

# Requires privileged SCC.
builder:
  enabled: false

cfapi:
  podSecurityContext:
    enabled: false

cf-platform-analytics-platform:
  redis:
    master:
      podSecurityContext:
        enabled: false
      containerSecurityContext:
        enabled: false

cfsign:
  podSecurityContext:
    enabled: false
  initContainers:
    volume-permissions:
      enabled: false

cfui:
  podSecurityContext:
    enabled: false

internal-gateway:
  podSecurityContext:
    enabled: false

helm-repo-manager:
  chartmuseum:
    securityContext:
      enabled: false

consul:
  podSecurityContext:
    enabled: false
  containerSecurityContext:
    enabled: false

cronus:
  podSecurityContext:
    enabled: false

ingress-nginx:
  enabled: false

mongodb:
  podSecurityContext:
    enabled: false
  containerSecurityContext:
    enabled: false

postgresql:
  primary:
    podSecurityContext:
      enabled: false
    containerSecurityContext:
      enabled: false

redis:
  master:
    podSecurityContext:
      enabled: false
    containerSecurityContext:
      enabled: false

rabbitmq:
  podSecurityContext:
    enabled: false
  containerSecurityContext:
    enabled: false

# Requires privileged SCC.
runner:
  enabled: false
```

## Firebase Configuration

As outlined in [prerequisites](#prerequisites), it's required to set up a Firebase database for builds logs streaming:

- [Create a Database](https://firebase.google.com/docs/database/web/start#create_a_database).
- Create a [Legacy token](https://firebase.google.com/docs/database/rest/auth#legacy_tokens) for authentication.
- Set the following rules for the database:
```json
{
   "rules": {
       "build-logs": {
           "$jobId":{
               ".read": "!root.child('production/build-logs/'+$jobId).exists() || (auth != null && auth.admin == true) || (auth == null && data.child('visibility').exists() && data.child('visibility').val() == 'public') || ( auth != null && data.child('accountId').exists() && auth.accountId == data.child('accountId').val() )",
               ".write": "auth != null && data.child('accountId').exists() && auth.accountId == data.child('accountId').val()"
           }
       },
       "environment-logs": {
           "$environmentId":{
               ".read": "!root.child('production/environment-logs/'+$environmentId).exists() || ( auth != null && data.child('accountId').exists() && auth.accountId == data.child('accountId').val() )",
               ".write": "auth != null && data.child('accountId').exists() && auth.accountId == data.child('accountId').val()"
           }
       }
   }
}
```

However, if you're in an air-gapped environment, you can omit this prerequisite and use a built-in logging system (i.e. `OfflineLogging` feature-flag).
See [feature management](https://codefresh.io/docs/docs/installation/on-premises/on-prem-feature-management)

## Additional configuration

### Retention policy for builds and logs

With this method, Codefresh by default deletes builds older than six months.

The retention mechanism removes data from the following collections: `workflowproccesses`, `workflowrequests`, `workflowrevisions`

```yaml
cfapi:
  env:
    # Determines if automatic build deletion through the Cron job is enabled.
    RETENTION_POLICY_IS_ENABLED: true
    # The maximum number of builds to delete by a single Cron job. To avoid database issues, especially when there are large numbers of old builds, we recommend deleting them in small chunks. You can gradually increase the number after verifying that performance is not affected.
    RETENTION_POLICY_BUILDS_TO_DELETE: 50
    # The number of days for which to retain builds. Builds older than the defined retention period are deleted.
    RETENTION_POLICY_DAYS: 180
```

### Retention policy for builds and logs
> Configuration for Codefresh On-Prem >= 2.x

> Previous configuration example (i.e. `RETENTION_POLICY_IS_ENABLED=true` ) is also supported in Codefresh On-Prem >= 2.x

**For existing environments, for the retention mechanism to work, you must first drop the `created ` index in `workflowprocesses` collection. This requires a maintenance window that depends on the number of builds.**

```yaml
cfapi:
  env:
    # Determines if automatic build deletion is enabled.
    TTL_RETENTION_POLICY_IS_ENABLED: true
    # The number of days for which to retain builds, and can be between 30 (minimum) and 365 (maximum). Builds older than the defined retention period are deleted.
    TTL_RETENTION_POLICY_IN_DAYS: 180
```

### Projects pipelines limit

```yaml
cfapi:
  env:
    # Determines project's pipelines limit (default: 500)
    PROJECT_PIPELINES_LIMIT: 500
```

### Enable session cookie

```yaml
cfapi:
  env:
    # Generate a unique session cookie (cf-uuid) on each login
    DISABLE_CONCURRENT_SESSIONS: true
    # Customize cookie domain
    CF_UUID_COOKIE_DOMAIN: .mydomain.com
```

> **Note!** Ingress host for [gitops-runtime](https://artifacthub.io/packages/helm/codefresh-gitops-runtime/gitops-runtime) and ingress host for control plane must share the same root domain (i.e. `onprem.mydomain.com` and `runtime.mydomain.com`)

### X-Frame-Options response header

```yaml
cfapi:
  env:
    # Set value to the `X-Frame-Options` response header. Control the restrictions of embedding Codefresh page into the iframes.
    # Possible values: sameorigin(default) / deny
    FRAME_OPTIONS: sameorigin

cfui:
  env:
    FRAME_OPTIONS: sameorigin
```

Read more about header at https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options.

### Configure CSP (Content Security Policy)

`CONTENT_SECURITY_POLICY` is the string describing content policies. Use semi-colons to separate between policies. `CONTENT_SECURITY_POLICY_REPORT_TO` is a comma-separated list of JSON objects. Each object must have a name and an array of endpoints that receive the incoming CSP reports.

For detailed information, see the [Content Security Policy article on MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP).

```yaml
cfui:
  env:
    CONTENT_SECURITY_POLICY: "<YOUR SECURITY POLICIES>"
    CONTENT_SECURITY_POLICY_REPORT_ONLY: "default-src 'self'; font-src 'self'
      https://fonts.gstatic.com; script-src 'self' https://unpkg.com https://js.stripe.com;
      style-src 'self' https://fonts.googleapis.com; 'unsafe-eval' 'unsafe-inline'"
    CONTENT_SECURITY_POLICY_REPORT_TO: "<LIST OF ENDPOINTS AS JSON OBJECTS>"
```

### x-hub-signature-256 signature for GitHub AE

For detailed information, see the [Securing your webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks/securing-your-webhooks) and [Webhooks](https://docs.github.com/en/github-ae@latest/rest/webhooks).

```
cfapi:
  env:
    USE_SHA256_GITHUB_SIGNATURE: "true"
```

### Image digests in containers

In Codefresh On-Prem 2.6.x all Codefresh owner microservices include image digests in the default subchart values.

For example, default values for `cfapi` might look like this:

```yaml
container:
  image:
    registry: us-docker.pkg.dev/codefresh-enterprise/gcr.io
    repository: codefresh/cf-api
    tag: 21.268.1
    digest: "sha256:bae42f8efc18facc2bf93690fce4ab03ef9607cec4443fada48292d1be12f5f8"
    pullPolicy: IfNotPresent
```

this resulting in the following image reference in the pod spec:

```yaml
spec:
  containers:
    - name: cfapi
      image: us-docker.pkg.dev/codefresh-enterprise/gcr.io/codefresh/cf-api:21.268.1@sha256:bae42f8efc18facc2bf93690fce4ab03ef9607cec4443fada48292d1be12f5f8
```

> **Note!** When the `digest` is providerd, the `tag` is ignored! You can omit digest and use tag only like the following `values.yaml` example:

```yaml
cfapi:
  container:
    image:
      tag: 21.268.1
      # -- Set empty tag for digest
      digest: ""
```

## Configuring OIDC Provider

OpenID Connect (OIDC) allows Codefresh Builds to access resources in your cloud provider (such as AWS, Azure, GCP), without needing to store cloud credentials as long-lived pipeline secret variables.

### Enabling the OIDC Provider in Codefresh On-Prem

#### Prerequisites:

- DNS name for OIDC Provider
- Valid TLS certificates for Ingress
- K8S secret containing JWKS (JSON Web Key Sets). Can be generated at [mkjwk.org](https://mkjwk.org/)
- K8S secret containing Cliend ID (public identifier for app) and Client Secret (application password; cryptographically strong random string)

> **NOTE!** In production usage use [External Secrets Operator](https://external-secrets.io/latest/) or [HashiCorp Vault](https://developer.hashicorp.com/vault/docs/platform/k8s) to create secrets. The following example uses `kubectl` for brevity.

For JWKS use **Public and Private Keypair Set** (if generated at [mkjwk.org](https://mkjwk.org/)), for example:

`cf-oidc-provider-jwks.json`:
```json
{
    "keys": [
        {
            "p": "...",
            "kty": "RSA",
            "q": "...",
            "d": "...",
            "e": "AQAB",
            "use": "sig",
            "qi": "...",
            "dp": "...",
            "alg": "RS256",
            "dq": "...",
            "n": "..."
        }
    ]
}
```

```console
# Creating secret containing JWKS.
# The secret KEY is `cf-oidc-provider-jwks.json`. It then referenced in `OIDC_JWKS_PRIVATE_KEYS_PATH` environment variable in `cf-oidc-provider`.
# The secret NAME is referenced in `.volumes.jwks-file.nameOverride` (volumeMount is configured in the chart already)
kubectl create secret generic cf-oidc-provider-jwks \
  --from-file=cf-oidc-provider-jwks.json \
  -n $NAMESPACE

# Creating secret containing Client ID and Client Secret
# Secret NAME is `cf-oidc-provider-client-secret`.
# It then referenced in `OIDC_CF_PLATFORM_CLIENT_ID` and `OIDC_CF_PLATFORM_CLIENT_SECRET` environment variables in `cf-oidc-provider`
# and in `OIDC_PROVIDER_CLIENT_ID` and `OIDC_PROVIDER_CLIENT_SECRET` in `cfapi`.
kubectl create secret generic cf-oidc-provider-client-secret \
  --from-literal=client-id=codefresh \
  --from-literal=client-secret='verysecureclientsecret' \
  -n $NAMESPACE
```

`values.yaml`
```yaml
global:
  # -- Set OIDC Provider URL
  oidcProviderService: "oidc.mydomain.com"
  # -- Default OIDC Provider service client ID in plain text.
  # Optional! If specified here, no need to specify CLIENT_ID/CLIENT_SECRET env vars in cfapi and cf-oidc-provider below.
  oidcProviderClientId: null
  # -- Default OIDC Provider service client secret in plain text.
  # Optional! If specified here, no need to specify CLIENT_ID/CLIENT_SECRET env vars in cfapi and cf-oidc-provider below.
  oidcProviderClientSecret: null

cfapi:
  # -- Set additional variables for cfapi
  # Reference a secret containing Client ID and Client Secret
  env:
    OIDC_PROVIDER_CLIENT_ID:
      valueFrom:
        secretKeyRef:
          name: cf-oidc-provider-client-secret
          key: client-id
    OIDC_PROVIDER_CLIENT_SECRET:
      valueFrom:
        secretKeyRef:
          name: cf-oidc-provider-client-secret
          key: client-secret

cf-oidc-provider:
  # -- Enable OIDC Provider
  enabled: true

  container:
    env:
      OIDC_JWKS_PRIVATE_KEYS_PATH: /secrets/jwks/cf-oidc-provider-jwks.json
      # -- Reference a secret containing Client ID and Client Secret
      OIDC_CF_PLATFORM_CLIENT_ID:
        valueFrom:
          secretKeyRef:
            name: cf-oidc-provider-client-secret
            key: client-id
      OIDC_CF_PLATFORM_CLIENT_SECRET:
        valueFrom:
          secretKeyRef:
            name: cf-oidc-provider-client-secret
            key: client-secret

  volumes:
    jwks-file:
      enabled: true
      type: secret
      # -- Secret name containing JWKS
      nameOverride: "cf-oidc-provider-jwks"
      optional: false

  ingress:
    main:
      # -- Enable ingress for OIDC Provider
      enabled: true
      annotations: {}
      # -- Set ingress class name
      ingressClassName: ""
      hosts:
        # -- Set OIDC Provider URL
      - host: "oidc.mydomain.com"
        paths:
        - path: /
        # For ALB (Application Load Balancer) /* asterisk is required in path
        # e.g.
        # - path: /*
      tls: []
```

Deploy HELM chart with new `values.yaml`

Use https://oidc.mydomain.com/.well-known/openid-configuration to verify OIDC Provider configuration

### Adding the identity provider in AWS

To add Codefresh OIDC provider to IAM, see the [AWS documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- For the **provider URL**: Use `.Values.global.oidcProviderService` value with `https://` prefix (i.e. https://oidc.mydomain.com)
- For the **Audienece**: Use `.Values.global.appUrl` value with `https://` prefix (i.e. https://onprem.mydomain.com)

#### Configuring the role and trust policy

To configure the role and trust in IAM, see [AWS documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)

Edit the trust policy to add the sub field to the validation conditions. For example, use `StringLike` to allow only builds from specific pipeline to assume a role in AWS.
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/oidc.mydomain.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.mydomain.com:aud": "https://onprem.mydomain.com"
                },
                "StringLike": {
                    "oidc.mydomain.com:sub": "account:64884faac2751b77ca7ab324:pipeline:64f7232ab698cfcb95d93cef:*"
                }
            }
        }
    ]
}
```

To see all the claims supported by Codefresh OIDC provider, see `claims_supported` entries at https://oidc.mydomain.com/.well-known/openid-configuration
```json
"claims_supported": [
  "sub",
  "account_id",
  "account_name",
  "pipeline_id",
  "pipeline_name",
  "workflow_id",
  "initiator",
  "scm_user_name",
  "scm_repo_url",
  "scm_ref",
  "scm_pull_request_target_branch",
  "sid",
  "auth_time",
  "iss"
]
```

#### Using OIDC in Codefresh Builds

Use [obtain-oidc-id-token](https://github.com/codefresh-io/steps/blob/822afc0a9a128384e76459c6573628020a2cf404/incubating/obtain-oidc-id-token/step.yaml#L27-L58) and [aws-sts-assume-role-with-web-identity](https://github.com/codefresh-io/steps/blob/822afc0a9a128384e76459c6573628020a2cf404/incubating/aws-sts-assume-role-with-web-identity/step.yaml#L29-L63) steps to exchange the OIDC token (JWT) for a cloud access token.

## Upgrading

### To 2-0-0

This major chart version change (v1.4.X -> v2.0.0) contains some **incompatible breaking change needing manual actions**.

**Before applying the upgrade, read through this section!**

#### ⚠️ New Services

Codefesh 2.0 chart includes additional dependent microservices (charts):
- `argo-platform`: Main Codefresh GitOps module.
- `internal-gateway`: NGINX that proxies requests to the correct components (api-graphql, api-events, ui).
- `argo-hub-platform`: Service for Argo Workflow templates.
- `platform-analytics` and `etl-starter`: Service for [Pipelines dasboard](https://codefresh.io/docs/docs/dashboards/home-dashboard/#pipelines-dashboard)

These services require additional databases in MongoDB (`audit`/`read-models`/`platform-analytics-postgres`) and in Postgresql (`analytics` and `analytics_pre_aggregations`)
The helm chart is configured to re-run seed jobs to create necessary databases and users during the upgrade.

```yaml
seed:
  # -- Enable all seed jobs
  enabled: true
```

#### ⚠️ New MongoDB Indexes

Starting from version 2.0.0, two new MongoDB indexes have been added that are vital for optimizing database queries and enhancing overall system performance. It is crucial to create these indexes before performing the upgrade to avoid any potential performance degradation.

- `account_1_annotations.key_1_annotations.value_1` (db: `codefresh`; collection: `annotations`)
```json
{
    "account" : 1,
    "annotations.key" : 1,
    "annotations.value" : 1
}
```

- `accountId_1_entityType_1_entityId_1` (db: `codefresh`; collection: `workflowprocesses`)

```json
{
    "accountId" : 1,
    "entityType" : 1,
    "entityId" : 1
}
```

To prevent potential performance degradation during the upgrade, it is important to schedule a maintenance window during a period of low activity or minimal user impact and create the indexes mentioned above before initiating the upgrade process. By proactively creating these indexes, you can avoid the application automatically creating them during the upgrade and ensure a smooth transition with optimized performance.

**Index Creation**

If you're hosting MongoDB on [Atlas](https://www.mongodb.com/atlas/database), use the following [Create, View, Drop, and Hide Indexes](https://www.mongodb.com/docs/atlas/atlas-ui/indexes/) guide to create indexes mentioned above. It's important to create them in a rolling fashion (i.e. **Build index via rolling process** checkbox enabled) in produciton environment.

For self-hosted MongoDB, see the following instruction:

- Connect to the MongoDB server using the [mongosh](https://www.mongodb.com/docs/mongodb-shell/install/) shell. Open your terminal or command prompt and run the following command, replacing <connection_string> with the appropriate MongoDB connection string for your server:
```console
mongosh "<connection_string>"
```

- Once connected, switch to the `codefresh` database where the index will be located using the `use` command.
```console
use codefresh
```

- To create the indexes, use the createIndex() method. The createIndex() method should be executed on the db object.
```console
db.workflowprocesses.createIndex({ account: 1, 'annotations.key': 1, 'annotations.value': 1 }, { name: 'account_1_annotations.key_1_annotations.value_1', sparse: true, background: true })
```

```console
db.annotations.createIndex({ accountId: 1, entityType: 1, entityId: 1 }, { name: 'accountId_1_entityType_1_entityId_1', background: true })
```
After executing the createIndex() command, you should see a result indicating the successful creation of the index.

#### ⚠️ [Kcfi](https://github.com/codefresh-io/kcfi) Deprecation

This major release deprecates [kcfi](https://github.com/codefresh-io/kcfi) installer. The recommended way to install Codefresh On-Prem is **Helm**.
Due to that, Kcfi `config.yaml` will not be compatible for Helm-based installation.
You still can reuse the same `config.yaml` for the Helm chart, but you need to remove (or update) the following sections.

* `.Values.metadata` is deprecated. Remove it from `config.yaml`

*1.4.x `config.yaml`*
```yaml
metadata:
  kind: codefresh
  installer:
    type: helm
    helm:
      chart: codefresh
      repoUrl: http://chartmuseum.codefresh.io/codefresh
      version: 1.4.x
```

* `.Values.kubernetes` is deprecated. Remove it from `config.yaml`

*1.4.x `config.yaml`*
```yaml
kubernetes:
  namespace: codefresh
  context: context-name
```

* `.Values.tls` (`.Values.webTLS`) is moved under `.Values.ingress.tls`. Remove `.Values.tls` from `config.yaml` afterwards.

  See full [values.yaml](./values.yaml#L92).

*1.4.x `config.yaml`*
```yaml
tls:
  selfSigned: false
  cert: certs/certificate.crt
  key: certs/private.key
```

*2.0.0 `config.yaml`*
```yaml
# -- Ingress
ingress:
  # -- Enable the Ingress
  enabled: true
  # -- Set the ingressClass that is used for the ingress.
  ingressClassName: nginx-codefresh
  tls:
    # -- Enable TLS
    enabled: true
    # -- Default secret name to be created with provided `cert` and `key` below
    secretName: "star.codefresh.io"
    # -- Certificate (base64 encoded)
    cert: "LS0tLS1CRUdJTiBDRVJ...."
    # -- Private key (base64 encoded)
    key: "LS0tLS1CRUdJTiBSU0E..."
    # -- Existing `kubernetes.io/tls` type secret with TLS certificates (keys: `tls.crt`, `tls.key`)
    existingSecret: ""
```

* `.Values.images` is deprecated.  Remove `.Values.images` from `config.yaml`.

  - `.Values.images.codefreshRegistrySa` is changed to `.Values.imageCredentials`

  - `.Values.privateRegistry.address` is changed to `.Values.global.imageRegistry` (no trailing slash `/` at the end)

  See full `values.yaml` [here](./values.yaml#L2) and [here](./values.yaml#L143).

*1.4.x `config.yaml`*
```yaml
images:
  codefreshRegistrySa: sa.json
  usePrivateRegistry: true
  privateRegistry:
    address: myprivateregistry.domain
    username: username
    password: password
```

*2.0.0 `config.yaml`*
```yaml
# -- Credentials for Image Pull Secret object
imageCredentials: {}
# Pass sa.json (as a single line). Obtain GCR Service Account JSON (sa.json) at support@codefresh.io
# E.g.:
# imageCredentials:
#   registry: gcr.io
#   username: _json_key
#   password: '{ "type": "service_account", "project_id": "codefresh-enterprise", "private_key_id": ... }'
```

*2.0.0 `config.yaml`*
```yaml
global:
  # -- Global Docker image registry
  imageRegistry: "myprivateregistry.domain"
```

* `.Values.dbinfra` is deprecated. Remove it from `config.yaml`

*1.4.x `config.yaml`*
```yaml
dbinfra:
  enabled: false
```

* `.Values.firebaseUrl` and `.Values.firebaseSecret` is moved under `.Values.global`

*1.4.x `config.yaml`*
```yaml
firebaseUrl: <url>
firebaseSecret: <secret>
newrelicLicenseKey: <key>
```

*2.0.0 `config.yaml`*
```yaml
global:
  # -- Firebase URL for logs streaming.
  firebaseUrl: ""
  # -- Firebase Secret.
  firebaseSecret: ""
  # -- New Relic Key
  newrelicLicenseKey: ""
```

* `.Values.global.certsJobs` and `.Values.global.seedJobs` is deprecated. Use `.Values.seed.mongoSeedJob` and `.Values.seed.postgresSeedJob`.

  See full [values.yaml](./values.yaml#L42).

*1.4.x `config.yaml`*
```yaml
global:
  certsJobs: true
  seedJobs: true
```

*2.0.0 `config.yaml`*
```yaml
seed:
  # -- Enable all seed jobs
  enabled: true
  # -- Mongo Seed Job. Required at first install. Seeds the required data (default idp/user/account), creates cfuser and required databases.
  # @default -- See below
  mongoSeedJob:
    enabled: true
  # -- Postgres Seed Job. Required at first install. Creates required user and databases.
  # @default -- See below
  postgresSeedJob:
    enabled: true
```

#### ⚠️ Migration to [Library Charts](https://helm.sh/docs/topics/library_charts/)

All Codefresh subchart templates (i.e. `cfapi`, `cfui`, `pipeline-manager`, `context-manager`, etc) have been migrated to use Helm [library charts](https://helm.sh/docs/topics/library_charts/).
That allows unifying the values structure across all Codefresh-owned charts. However, there are some **immutable** fields in the old charts which cannot be upgraded during a regular `helm upgrade`, and require additional manual actions.

Run the following commands before appying the upgrade.

* Delete `cf-runner` and `cf-builder` stateful sets.

```console
kubectl delete sts cf-runner --namespace $NAMESPACE
kubectl delete sts cf-builder --namespace $NAMESPACE
```

* Delete all jobs

```console
kubectl delete job --namespace $NAMESPACE -l release=cf
```

* In `values.yaml`/`config.yaml` remove `.Values.nomios.ingress` section if you have it

```yaml
nomios:
  # Remove ingress section
  ingress:
    ...
```

### To 2.0.12

#### ⚠️ Legacy ChartMuseum subchart deprecation

Due to deprecation of legacy ChartMuseum subchart in favor of upstream [chartmuseum](https://github.com/chartmuseum/charts/tree/main/src/chartmuseum), you need to remove the old deployment before the upgrade due to **immutable** `matchLabels` field change in the deployment spec.

```console
kubectl delete deploy cf-chartmuseum --namespace $NAMESPACE
```

#### ⚠️ Affected values

- If you have `.persistence.enabled=true` defined and NOT `.persistence.existingClaim` like:

```yaml
helm-repo-manager:
  chartmuseum:
    persistence:
      enabled: true
```
then you **have to backup** the content of old PVC (mounted as `/storage` in the old deployment) **before the upgrade**!

```shell
POD_NAME=$(kubectl get pod -l app=chartmuseum -n $NAMESPACE --no-headers -o custom-columns=":metadata.name")
kubectl cp -n $NAMESPACE $POD_NAME:/storage $(pwd)/storage
```

**After the upgrade**, restore the content into new deployment:
```shell
POD_NAME=$(kubectl get pod -l app.kubernetes.io/name=chartmuseum -n $NAMESPACE --no-headers -o custom-columns=":metadata.name")
kubectl cp -n $NAMESPACE $(pwd)/storage $POD_NAME:/storage
```

- If you have `.persistence.existingClaim` defined, you can keep it as is:
```yaml
helm-repo-manager:
  chartmuseum:
    existingClaim: my-claim-name
```

- If you have `.Values.global.imageRegistry` specified, it **won't be** applied for the new chartmuseum subchart. Add image registry explicitly for the subchart as follows

```yaml
global:
  imageRegistry: myregistry.domain.com

helm-repo-manager:
  chartmuseum:
    image:
      repository: myregistry.domain.com/codefresh/chartmuseum
```

### To 2-0-17

#### ⚠️ Affected values

Values structure for argo-platform images has been changed.
Added `registry` to align with the rest of the services.

> values for <= v2.0.16
```yaml
argo-platform:
  api-graphql:
    image:
      repository: gcr.io/codefresh-enterprise/codefresh-io/argo-platform-api-graphql
  abac:
    image:
      repository: gcr.io/codefresh-enterprise/codefresh-io/argo-platform-abac
  analytics-reporter:
    image:
      repository: gcr.io/codefresh-enterprise/codefresh-io/argo-platform-analytics-reporter
  api-events:
    image:
      repository: gcr.io/codefresh-enterprise/codefresh-io/argo-platform-api-events
  audit:
    image:
      repository: gcr.io/codefresh-enterprise/codefresh-io/argo-platform-audit
  cron-executor:
    image:
      repository: gcr.io/codefresh-enterprise/codefresh-io/argo-platform-cron-executor
  event-handler:
    image:
      repository: gcr.io/codefresh-enterprise/codefresh-io/argo-platform-event-handler
  ui:
    image:
      repository: gcr.io/codefresh-enterprise/codefresh-io/argo-platform-ui
```

> values for >= v2.0.17

```yaml
argo-platform:
  api-graphql:
    image:
      registry: gcr.io/codefresh-enterprise
      repository: codefresh-io/argo-platform-api-graphql
  abac:
    image:
      registry: gcr.io/codefresh-enterprise
      repository: codefresh-io/argo-platform-abac
  analytics-reporter:
    image:
      registry: gcr.io/codefresh-enterprise
      repository: codefresh-io/argo-platform-analytics-reporter
  api-events:
    image:
      registry: gcr.io/codefresh-enterprise
      repository: codefresh-io/argo-platform-api-events
  audit:
    image:
      registry: gcr.io/codefresh-enterprise
      repository: codefresh-io/argo-platform-audit
  cron-executor:
    image:
      registry: gcr.io/codefresh-enterprise
      repository: codefresh-io/argo-platform-cron-executor
  event-handler:
    image:
      registry: gcr.io/codefresh-enterprise
      repository: codefresh-io/argo-platform-event-handler
  ui:
    image:
      registry: gcr.io/codefresh-enterprise
      repository: codefresh-io/argo-platform-ui
```

### To 2-1-0

### [What's new in 2.1.x](https://codefresh.io/docs/docs/whats-new/on-prem-release-notes/#on-premises-version-21)

#### Affected values:

- [Legacy ChartMuseum subchart deprecation](#to-2-0-12)
- [Argo-Platform images values structure change](#to-2-0-17)
- **Changed** default ingress paths. All paths point to `internal-gateway` now. **Remove any overrides at `.Values.ingress.services`!** (updated example for ALB)
- **Deprecated** `global.mongoURI`. **Supported for backward compatibility!**
- **Added** `global.mongodbProtocol` / `global.mongodbUser` / `global.mongodbPassword` / `global.mongodbHost` / `global.mongodbOptions`
- **Added** `global.mongodbUserSecretKeyRef` / `global.mongodbPasswordSecretKeyRef` / `global.mongodbHostSecretKeyRef`
- **Added** `seed.mongoSeedJob.mongodbRootUserSecretKeyRef` / `seed.mongoSeedJob.mongodbRootPasswordSecretKeyRef`
- **Added** `seed.postgresSeedJob.postgresUserSecretKeyRef` / `seed.postgresSeedJob.postgresPasswordSecretKeyRef`
- **Added** `global.firebaseUrlSecretKeyRef` / `global.firebaseSecretSecretKeyRef`
- **Added** `global.postgresUserSecretKeyRef` / `global.postgresPasswordSecretKeyRef` / `global.postgresHostnameSecretKeyRef`
- **Added** `global.rabbitmqUsernameSecretKeyRef` / `global.rabbitmqPasswordSecretKeyRef` / `global.rabbitmqHostnameSecretKeyRef`
- **Added** `global.redisPasswordSecretKeyRef` / `global.redisUrlSecretKeyRef`

- **Removed** `global.runtimeMongoURI` (defaults to `global.mongoURI` or `global.mongodbHost`/`global.mongodbHostSecretKeyRef`/etc like values)
- **Removed** `global.runtimeMongoDb` (defaults to `global.mongodbDatabase`)
- **Removed** `global.runtimeRedisHost` (defaults to `global.redisUrl`/`global.redisUrlSecretKeyRef` or `global.redisService`)
- **Removed** `global.runtimeRedisPort` (defaults to `global.redisPort`)
- **Removed** `global.runtimeRedisPassword` (defaults to `global.redisPassword`/`global.redisPasswordSecretKeyRef`)
- **Removed** `global.runtimeRedisDb` (defaults to values below)

```yaml
cfapi:
  env:
    RUNTIME_REDIS_DB: 0

cf-broadcaster:
  env:
    REDIS_DB: 0
```

### To 2-1-7

⚠️⚠️⚠️
> Since version 2.1.7 chart is pushed **only** to OCI registry at `oci://quay.io/codefresh/codefresh`

> Versions prior to 2.1.7 are still available in ChartMuseum at `http://chartmuseum.codefresh.io/codefresh`

### To 2-2-0

### [What's new in 2.2.x](https://codefresh.io/docs/docs/whats-new/on-prem-release-notes/#on-premises-version-22)

#### MongoDB 5.x

Codefresh On-Prem 2.2.x uses MongoDB 5.x (4.x is still supported). If you run external MongoDB, it is **highly** recommended to upgrade it to 5.x after upgrading Codefresh On-Prem to 2.2.x.

#### Redis HA

> If you run external Redis, this is not applicable to you.

Codefresh On-Prem 2.2.x adds (not replaces!) an **optional** Redis-HA (master/slave configuration with Sentinel sidecars for failover management) instead of a single Redis instance.
To enable it, see the following values:

```yaml
global:
  redisUrl: cf-redis-ha-haproxy # Replace `cf` with your Helm release name

# -- Disable standalone Redis instance
redis:
  enabled: false

# -- Enable Redis HA
redis-ha:
  enabled: true
```

### To 2-3-0

### [What's new in 2.3.x](https://codefresh.io/docs/docs/whats-new/on-prem-release-notes/#on-premises-version-23)

⚠️ This major release changes default registry for Codefresh **private** images from GCR (`gcr.io`) to GAR (`us-docker.pkg.dev`)

Update `.Values.imageCredentials.registry` to `us-docker.pkg.dev` if it's explicitly set to `gcr.io` in your values file.

Default `.Values.imageCredentials` for Onprem **v2.2.x and below**
```yaml
imageCredentials:
  registry: gcr.io
  username: _json_key
  password: <YOUR_SERVICE_ACCOUNT_JSON_HERE>
```

Default `.Values.imageCredentials` for Onprem **v2.3.x and above**
```yaml
imageCredentials:
  registry: us-docker.pkg.dev
  username: _json_key
  password: <YOUR_SERVICE_ACCOUNT_JSON_HERE>
```

## Rollback

Use `helm history` to determine which release has worked, then use `helm rollback` to perform a rollback

> When rollback from 2.x prune these resources due to immutabled fields changes

```console
kubectl delete sts cf-runner --namespace $NAMESPACE
kubectl delete sts cf-builder --namespace $NAMESPACE
kubectl delete deploy cf-chartmuseum --namespace $NAMESPACE
kubectl delete job --namespace $NAMESPACE -l release=$RELEASE_NAME
```

```console
helm rollback $RELEASE_NAME $RELEASE_NUMBER \
    --namespace $NAMESPACE \
    --debug \
    --wait
```

### To 2-4-0

### [What's new in 2.4.x](https://codefresh.io/docs/docs/whats-new/on-prem-release-notes/#on-premises-version-24)

#### New cfapi-auth role

New `cfapi-auth` role is introduced in 2.4.x.

If you run onprem with [multi-role cfapi configuration](#configuration-with-multi-role-cf-api), make sure to **enable** `cfapi-auth` role:

```yaml
cfapi-auth:
  <<: *cf-api
  enabled: true
```

#### Default SYSTEM_TYPE for acccounts

Since 2.4.x, `SYSTEM_TYPE` is changed to `PROJECT_ONE` by default.

If you want to preserve original `CLASSIC` values, update cfapi environment variables:

```yaml
cfapi:
  container:
    env:
      DEFAULT_SYSTEM_TYPE: CLASSIC
```

### To 2-5-0

### [What's new in 2.5.x](https://codefresh.io/docs/docs/whats-new/on-prem-release-notes/#on-premises-version-25)

### To 2-6-0

### [What's new in 2.6.x](https://codefresh.io/docs/docs/whats-new/on-prem-release-notes/#on-premises-version-26)

#### Affected values

[Image digests in containers](#image-digests-in-containers)

#### Auto-index creation in MongoDB

[Auto-index creation in MongoDB](#auto-index-creation-in-mongodb)

### To 2-7-0

### [What's new in 2.7.x](https://codefresh.io/docs/docs/whats-new/on-prem-release-notes/#on-premises-version-27)

#### Affected values

- Added option to provide global `tolerations`/`nodeSelector`/`affinity` for all Codefresh subcharts
> **Note!** These global settings will not be applied to Bitnami subcharts (e.g. `mongodb`, `redis`, `rabbitmq`, `postgres`. etc)

```yaml
global:
  tolerations:
    - key: "key"
      operator: "Equal"
      value: "value"
      effect: "NoSchedule"

  nodeSelector:
    key: "value"

  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: "key"
                operator: "In"
                values:
                  - "value"
```

### To 2-8-0

### [What's new in 2.8.x](https://codefresh.io/docs/docs/whats-new/on-prem-release-notes/#on-premises-version-28)

### ⚠️ ⚠️ ⚠️ Breaking changes. Read before upgrading!

### MongoDB update

Default MongoDB image is changed from 6.x to 7.x.

If you run external MongoDB (i.e. [Atlas](https://cloud.mongodb.com)), it is **required** to upgrade it to 7.x after upgrading Codefresh On-Prem to 2.8.x.

For backward compatibility (in case you need to rollback to 6.x), you can set [`featureCompatibilityVersion`](https://www.mongodb.com/docs/v6.0/reference/command/setFeatureCompatibilityVersion/) to `6.0` in your values file.

```yaml
mongodb:
  migration:
    enabled: true
    featureCompatibilityVersion: "6.0"
```

### PostgreSQL update

Default PostgreSQL image is changed from 13.x to 17.x

If you run external PostgreSQL, follow the [official instructions](https://www.postgresql.org/docs/17/upgrading.html) to upgrade to 17.x.

⚠️ ⚠️ ⚠️ If you run built-in PostgreSQL `bitnami/postgresql` subchart, direct upgrade is not supported. You need to backup your data, delete the old PostgreSQL StatefulSet with PVCs and restore the data into a new PostgreSQL StatefulSet.

```console
PGUSER=postgres
PGHOST=cf-postgresql
PGPORT=5432
PGPASSWORD=postgres
BACKUP_DIR=/tmp/pg_backup
BACKUP_SQL=backup.sql
TIMESTAMP=$(date +%Y%m%d%H%M%S)
NAMESPACE=codefresh

# Backup PostgreSQL data
pg_dumpall --verbose > "$BACKUP_DIR/$BACKUP_SQL.$TIMESTAMP" 2>> "$LOG_FILE"

# Delete old PostgreSQL StatefulSet
STS_NAME=$(kubectl get sts -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')
PVC_NAME=$(kubectl get pvc -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')

kubectl delete sts $STS_NAME -n $NAMESPACE
kubectl delete pvc $PVC_NAME -n $NAMESPACE

# Perform Codefresh On-Prem upgrade to 2.8.x

# Restore PostgreSQL data
psql -U -f "$BACKUP_DIR/$BACKUP_SQL.$TIMESTAMP" >> "$LOG_FILE" 2>&1
```

### RabbitMQ update

Default RabbitMQ image is changed from 3.x to 4.x

####  Affected values

- Added option to provide `.Values.global.tolerations`/`.Values.global.nodeSelector`/`.Values.global.affinity` for all Codefresh subcharts

- Changed default location for public images from `quay.io/codefresh` to `us-docker.pkg.dev/codefresh-inc/public-gcr-io/codefresh`

- `.Values.hooks` was splitted into `.Values.hooks.mongodb` and `.Values.hooks.consul`

## Troubleshooting

### Error: Failed to validate connection to Docker daemon; caused by Error: certificate has expired

Builds are stuck in pending with `Error: Failed to validate connection to Docker daemon; caused by Error: certificate has expired`

**Reason:** Runtime certificates have expiried.

To check if runtime internal CA expired:

```console
kubectl -n $NAMESPACE get secret/cf-codefresh-certs-client -o jsonpath="{.data['ca\.pem']}" | base64 -d | openssl x509 -enddate -noout
```

**Resolution:** Replace internal CA and re-issue dind certs for runtime

- Delete k8s secret with expired certificate
```console
kubectl -n $NAMESPACE delete secret cf-codefresh-certs-client
```

- Set `.Values.global.gencerts.enabled=true` (`.Values.global.certsJob=true` for onprem < 2.x version)

```yaml
# -- Job to generate internal runtime secrets.
# @default -- See below
gencerts:
  enabled: true
```

- Upgrade Codefresh On-Prem Helm release. It will recreate `cf-codefresh-certs-client` secret
```console
helm upgrade --install cf codefresh/codefresh \
    -f cf-values.yaml \
    --namespace codefresh \
    --create-namespace \
    --debug \
    --wait \
    --timeout 15m
```

- Restart `cfapi` and `cfsign` deployments

```console
kubectl -n $NAMESPACE rollout restart deployment/cf-cfapi
kubectl -n $NAMESPACE rollout restart deployment/cf-cfsign
```

**Case A:** Codefresh Runner installed with HELM chart ([charts/cf-runtime](https://github.com/codefresh-io/venona/tree/release-1.0/charts/cf-runtime))

Re-apply the `cf-runtime` helm chart. Post-upgrade `gencerts-dind` helm hook will regenerate the dind certificates using a new CA.

**Case B:** Codefresh Runner installed with legacy CLI ([codefresh runner init](https://codefresh-io.github.io/cli/runner/init/))

Delete `codefresh-certs-server` k8s secret and run [./configure-dind-certs.sh](https://github.com/codefresh-io/venona/blob/release-1.0/charts/cf-runtime/files/configure-dind-certs.sh) in your runtime namespace.

```console
kubectl -n $NAMESPACE delete secret codefresh-certs-server
./configure-dind-certs.sh -n $RUNTIME_NAMESPACE https://$CODEFRESH_HOST $CODEFRESH_API_TOKEN
```

### Consul Error: Refusing to rejoin cluster because the server has been offline for more than the configured server_rejoin_age_max

After platform upgrade, Consul fails with the error `refusing to rejoin cluster because the server has been offline for more than the configured server_rejoin_age_max - consider wiping your data dir`. There is [known issue](https://github.com/hashicorp/consul/issues/20722) of **hashicorp/consul** behaviour. Try to wipe out or delete the consul PV with config data and restart Consul StatefulSet.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| argo-hub-platform | object | See below | argo-hub-platform |
| argo-platform | object | See below | argo-platform |
| argo-platform.abac | object | See below | abac |
| argo-platform.analytics-reporter | object | See below | analytics-reporter |
| argo-platform.anchors | object | See below | Anchors |
| argo-platform.api-events | object | See below | api-events |
| argo-platform.api-graphql | object | See below | api-graphql All other services under `.Values.argo-platform` follows the same values structure. |
| argo-platform.api-graphql.affinity | object | `{}` | Set pod's affinity |
| argo-platform.api-graphql.env | object | See below | Env vars |
| argo-platform.api-graphql.hpa | object | `{"enabled":false}` | HPA |
| argo-platform.api-graphql.hpa.enabled | bool | `false` | Enable autoscaler |
| argo-platform.api-graphql.image | object | `{"registry":"us-docker.pkg.dev/codefresh-enterprise/gcr.io","repository":"codefresh-io/argo-platform-api-graphql"}` | Image |
| argo-platform.api-graphql.image.registry | string | `"us-docker.pkg.dev/codefresh-enterprise/gcr.io"` | Registry |
| argo-platform.api-graphql.image.repository | string | `"codefresh-io/argo-platform-api-graphql"` | Repository |
| argo-platform.api-graphql.kind | string | `"Deployment"` | Controller kind. Currently, only `Deployment` is supported |
| argo-platform.api-graphql.pdb | object | `{"enabled":false}` | PDB |
| argo-platform.api-graphql.pdb.enabled | bool | `false` | Enable pod disruption budget |
| argo-platform.api-graphql.podAnnotations | object | `{"checksum/secret":"{{ include (print $.Template.BasePath \"/api-graphql/secret.yaml\") . | sha256sum }}"}` | Set pod's annotations |
| argo-platform.api-graphql.resources | object | See below | Resource limits and requests |
| argo-platform.api-graphql.secrets | object | See below | Secrets |
| argo-platform.api-graphql.tolerations | list | `[]` | Set pod's tolerations |
| argo-platform.argocd-hooks | object | See below | argocd-hooks Don't enable! Not used in onprem! |
| argo-platform.audit | object | See below | audit |
| argo-platform.broadcaster | object | See below | broadcaster |
| argo-platform.cron-executor | object | See below | cron-executor |
| argo-platform.event-handler | object | See below | event-handler |
| argo-platform.promotion-orchestrator | object | See below | promotion-orchestrator |
| argo-platform.runtime-manager | object | See below | runtime-manager Don't enable! Not used in onprem! |
| argo-platform.runtime-monitor | object | See below | runtime-monitor Don't enable! Not used in onprem! |
| argo-platform.ui | object | See below | ui |
| argo-platform.useExternalSecret | bool | `false` | Use regular k8s secret object. Keep `false`! |
| builder | object | `{"affinity":{},"container":{"image":{"registry":"docker.io","repository":"library/docker","tag":"28.0-dind"}},"enabled":true,"imagePullSecrets":[],"initContainers":{"register":{"image":{"registry":"us-docker.pkg.dev/codefresh-inc/public-gcr-io","repository":"codefresh/curl","tag":"8.11.1"}}},"nodeSelector":{},"podSecurityContext":{},"resources":{},"tolerations":[]}` | builder |
| cf-broadcaster | object | See below | broadcaster |
| cf-oidc-provider | object | See below | cf-oidc-provider |
| cf-platform-analytics-etlstarter | object | See below | etl-starter |
| cf-platform-analytics-etlstarter.redis.enabled | bool | `false` | Disable redis subchart |
| cf-platform-analytics-etlstarter.system-etl-postgres | object | `{"container":{"env":{"BLUE_GREEN_ENABLED":true}},"controller":{"cronjob":{"ttlSecondsAfterFinished":300}},"enabled":true}` | Only postgres ETL should be running in onprem |
| cf-platform-analytics-platform | object | See below | platform-analytics |
| cfapi | object | `{"affinity":{},"container":{"env":{"AUDIT_AUTO_CREATE_DB":true,"DEFAULT_SYSTEM_TYPE":"PROJECT_ONE","GITHUB_API_PATH_PREFIX":"/api/v3","LOGGER_LEVEL":"debug","OIDC_PROVIDER_PORT":"{{ .Values.global.oidcProviderPort }}","OIDC_PROVIDER_PROTOCOL":"{{ .Values.global.oidcProviderProtocol }}","OIDC_PROVIDER_TOKEN_ENDPOINT":"{{ .Values.global.oidcProviderTokenEndpoint }}","OIDC_PROVIDER_URI":"{{ .Values.global.oidcProviderService }}","ON_PREMISE":true,"RUNTIME_MONGO_DB":"codefresh","RUNTIME_REDIS_DB":0},"image":{"registry":"us-docker.pkg.dev/codefresh-enterprise/gcr.io","repository":"codefresh/cf-api"}},"controller":{"replicas":2},"enabled":true,"hpa":{"enabled":false,"maxReplicas":10,"minReplicas":2,"targetCPUUtilizationPercentage":70},"imagePullSecrets":[],"nodeSelector":{},"pdb":{"enabled":false,"minAvailable":"50%"},"podSecurityContext":{},"resources":{"limits":{},"requests":{"cpu":"200m","memory":"256Mi"}},"secrets":{"secret":{"enabled":true,"stringData":{"OIDC_PROVIDER_CLIENT_ID":"{{ .Values.global.oidcProviderClientId }}","OIDC_PROVIDER_CLIENT_SECRET":"{{ .Values.global.oidcProviderClientSecret }}"},"type":"Opaque"}},"tolerations":[]}` | cf-api |
| cfapi-internal.<<.affinity | object | `{}` | Affinity configuration |
| cfapi-internal.<<.container | object | `{"env":{"AUDIT_AUTO_CREATE_DB":true,"DEFAULT_SYSTEM_TYPE":"PROJECT_ONE","GITHUB_API_PATH_PREFIX":"/api/v3","LOGGER_LEVEL":"debug","OIDC_PROVIDER_PORT":"{{ .Values.global.oidcProviderPort }}","OIDC_PROVIDER_PROTOCOL":"{{ .Values.global.oidcProviderProtocol }}","OIDC_PROVIDER_TOKEN_ENDPOINT":"{{ .Values.global.oidcProviderTokenEndpoint }}","OIDC_PROVIDER_URI":"{{ .Values.global.oidcProviderService }}","ON_PREMISE":true,"RUNTIME_MONGO_DB":"codefresh","RUNTIME_REDIS_DB":0},"image":{"registry":"us-docker.pkg.dev/codefresh-enterprise/gcr.io","repository":"codefresh/cf-api"}}` | Container configuration |
| cfapi-internal.<<.container.env | object | See below | Env vars |
| cfapi-internal.<<.container.image | object | `{"registry":"us-docker.pkg.dev/codefresh-enterprise/gcr.io","repository":"codefresh/cf-api"}` | Image |
| cfapi-internal.<<.container.image.registry | string | `"us-docker.pkg.dev/codefresh-enterprise/gcr.io"` | Registry prefix |
| cfapi-internal.<<.container.image.repository | string | `"codefresh/cf-api"` | Repository |
| cfapi-internal.<<.controller | object | `{"replicas":2}` | Controller configuration |
| cfapi-internal.<<.controller.replicas | int | `2` | Replicas number |
| cfapi-internal.<<.enabled | bool | `true` | Enable cf-api |
| cfapi-internal.<<.hpa | object | `{"enabled":false,"maxReplicas":10,"minReplicas":2,"targetCPUUtilizationPercentage":70}` | Autoscaler configuration |
| cfapi-internal.<<.hpa.enabled | bool | `false` | Enable HPA |
| cfapi-internal.<<.hpa.maxReplicas | int | `10` | Maximum number of replicas |
| cfapi-internal.<<.hpa.minReplicas | int | `2` | Minimum number of replicas |
| cfapi-internal.<<.hpa.targetCPUUtilizationPercentage | int | `70` | Average CPU utilization percentage |
| cfapi-internal.<<.imagePullSecrets | list | `[]` | Image pull secrets |
| cfapi-internal.<<.nodeSelector | object | `{}` | Node selector configuration |
| cfapi-internal.<<.pdb | object | `{"enabled":false,"minAvailable":"50%"}` | Pod disruption budget configuration |
| cfapi-internal.<<.pdb.enabled | bool | `false` | Enable PDB |
| cfapi-internal.<<.pdb.minAvailable | string | `"50%"` | Minimum number of replicas in percentage |
| cfapi-internal.<<.podSecurityContext | object | `{}` | Pod security context configuration |
| cfapi-internal.<<.resources | object | `{"limits":{},"requests":{"cpu":"200m","memory":"256Mi"}}` | Resource requests and limits |
| cfapi-internal.<<.secrets | object | `{"secret":{"enabled":true,"stringData":{"OIDC_PROVIDER_CLIENT_ID":"{{ .Values.global.oidcProviderClientId }}","OIDC_PROVIDER_CLIENT_SECRET":"{{ .Values.global.oidcProviderClientSecret }}"},"type":"Opaque"}}` | Secrets configuration |
| cfapi-internal.<<.tolerations | list | `[]` | Tolerations configuration |
| cfapi-internal.enabled | bool | `false` |  |
| cfapi.affinity | object | `{}` | Affinity configuration |
| cfapi.container | object | `{"env":{"AUDIT_AUTO_CREATE_DB":true,"DEFAULT_SYSTEM_TYPE":"PROJECT_ONE","GITHUB_API_PATH_PREFIX":"/api/v3","LOGGER_LEVEL":"debug","OIDC_PROVIDER_PORT":"{{ .Values.global.oidcProviderPort }}","OIDC_PROVIDER_PROTOCOL":"{{ .Values.global.oidcProviderProtocol }}","OIDC_PROVIDER_TOKEN_ENDPOINT":"{{ .Values.global.oidcProviderTokenEndpoint }}","OIDC_PROVIDER_URI":"{{ .Values.global.oidcProviderService }}","ON_PREMISE":true,"RUNTIME_MONGO_DB":"codefresh","RUNTIME_REDIS_DB":0},"image":{"registry":"us-docker.pkg.dev/codefresh-enterprise/gcr.io","repository":"codefresh/cf-api"}}` | Container configuration |
| cfapi.container.env | object | See below | Env vars |
| cfapi.container.image | object | `{"registry":"us-docker.pkg.dev/codefresh-enterprise/gcr.io","repository":"codefresh/cf-api"}` | Image |
| cfapi.container.image.registry | string | `"us-docker.pkg.dev/codefresh-enterprise/gcr.io"` | Registry prefix |
| cfapi.container.image.repository | string | `"codefresh/cf-api"` | Repository |
| cfapi.controller | object | `{"replicas":2}` | Controller configuration |
| cfapi.controller.replicas | int | `2` | Replicas number |
| cfapi.enabled | bool | `true` | Enable cf-api |
| cfapi.hpa | object | `{"enabled":false,"maxReplicas":10,"minReplicas":2,"targetCPUUtilizationPercentage":70}` | Autoscaler configuration |
| cfapi.hpa.enabled | bool | `false` | Enable HPA |
| cfapi.hpa.maxReplicas | int | `10` | Maximum number of replicas |
| cfapi.hpa.minReplicas | int | `2` | Minimum number of replicas |
| cfapi.hpa.targetCPUUtilizationPercentage | int | `70` | Average CPU utilization percentage |
| cfapi.imagePullSecrets | list | `[]` | Image pull secrets |
| cfapi.nodeSelector | object | `{}` | Node selector configuration |
| cfapi.pdb | object | `{"enabled":false,"minAvailable":"50%"}` | Pod disruption budget configuration |
| cfapi.pdb.enabled | bool | `false` | Enable PDB |
| cfapi.pdb.minAvailable | string | `"50%"` | Minimum number of replicas in percentage |
| cfapi.podSecurityContext | object | `{}` | Pod security context configuration |
| cfapi.resources | object | `{"limits":{},"requests":{"cpu":"200m","memory":"256Mi"}}` | Resource requests and limits |
| cfapi.secrets | object | `{"secret":{"enabled":true,"stringData":{"OIDC_PROVIDER_CLIENT_ID":"{{ .Values.global.oidcProviderClientId }}","OIDC_PROVIDER_CLIENT_SECRET":"{{ .Values.global.oidcProviderClientSecret }}"},"type":"Opaque"}}` | Secrets configuration |
| cfapi.tolerations | list | `[]` | Tolerations configuration |
| cfsign | object | See below | tls-sign |
| cfui | object | See below | cf-ui |
| charts-manager | object | See below | charts-manager |
| ci.enabled | bool | `false` |  |
| cluster-providers | object | See below | cluster-providers |
| consul | object | See below | consul Ref: https://github.com/bitnami/charts/blob/main/bitnami/consul/values.yaml |
| context-manager | object | See below | context-manager |
| cronus | object | See below | cronus |
| developmentChart | bool | `false` |  |
| dockerconfigjson | object | `{}` | DEPRECATED - Use `.imageCredentials` instead dockerconfig (for `kcfi` tool backward compatibility) for Image Pull Secret. Obtain GCR Service Account JSON (sa.json) at support@codefresh.io ```shell GCR_SA_KEY_B64=$(cat sa.json | base64) DOCKER_CFG_VAR=$(echo -n "_json_key:$(echo ${GCR_SA_KEY_B64} | base64 -d)" | base64 | tr -d '\n') ``` E.g.: dockerconfigjson:   auths:     gcr.io:       auth: <DOCKER_CFG_VAR> |
| gencerts | object | See below | Job to generate internal runtime secrets. Required at first install. |
| gitops-dashboard-manager | object | See below | gitops-dashboard-manager |
| global | object | See below | Global parameters |
| global.affinity | object | `{}` | Global affinity constraints Apply affinity to all Codefresh subcharts. Will not be applied on Bitnami subcharts. |
| global.appProtocol | string | `"https"` | Application protocol. |
| global.appUrl | string | `"onprem.codefresh.local"` | Application root url. Will be used in Ingress objects as hostname |
| global.broadcasterPort | int | `80` | Default broadcaster service port. |
| global.broadcasterService | string | `"cf-broadcaster"` | Default broadcaster service name. |
| global.builderService | string | `"builder"` | Default builder service name. |
| global.cfapiEndpointsService | string | `"cfapi"` | Default API endpoints service name |
| global.cfapiInternalPort | int | `3000` | Default API service port. |
| global.cfapiService | string | `"cfapi"` | Default API service name. |
| global.cfk8smonitorService | string | `"k8s-monitor"` | Default k8s-monitor service name. |
| global.chartsManagerPort | int | `9000` | Default chart-manager service port. |
| global.chartsManagerService | string | `"charts-manager"` | Default charts-manager service name. |
| global.clusterProvidersPort | int | `9000` | Default cluster-providers service port. |
| global.clusterProvidersService | string | `"cluster-providers"` | Default cluster-providers service name. |
| global.codefresh | string | `"codefresh"` | LEGACY - Keep as is! Used for subcharts to access external secrets and configmaps. |
| global.consulHttpPort | int | `8500` | Default Consul service port. |
| global.consulService | string | `"consul-headless"` | Default Consul service name. |
| global.contextManagerPort | int | `9000` | Default context-manager service port. |
| global.contextManagerService | string | `"context-manager"` | Default context-manager service name. |
| global.dnsService | string | `"kube-dns"` | Definitions for internal-gateway nginx resolver |
| global.env | object | `{}` | Global Env vars |
| global.firebaseSecret | string | `""` | Firebase Secret in plain text |
| global.firebaseSecretSecretKeyRef | object | `{}` | Firebase Secret from existing secret |
| global.firebaseUrl | string | `"https://codefresh-on-prem.firebaseio.com/on-prem"` | Firebase URL for logs streaming in plain text |
| global.firebaseUrlSecretKeyRef | object | `{}` | Firebase URL for logs streaming from existing secret |
| global.gitopsDashboardManagerDatabase | string | `"pipeline-manager"` | Default gitops-dashboarad-manager db collection. |
| global.gitopsDashboardManagerPort | int | `9000` | Default gitops-dashboarad-manager service port. |
| global.gitopsDashboardManagerService | string | `"gitops-dashboard-manager"` | Default gitops-dashboarad-manager service name. |
| global.helmRepoManagerService | string | `"helm-repo-manager"` | Default helm-repo-manager service name. |
| global.hermesService | string | `"hermes"` | Default hermes service name. |
| global.imagePullSecrets | list | `["codefresh-registry"]` | Global Docker registry secret names as array |
| global.imageRegistry | string | `""` | Global Docker image registry |
| global.kubeIntegrationPort | int | `9000` | Default kube-integration service port. |
| global.kubeIntegrationService | string | `"kube-integration"` | Default kube-integration service name. |
| global.mongoURI | string | `""` | LEGACY (but still supported) - Use `.global.mongodbProtocol` + `.global.mongodbUser/mongodbUserSecretKeyRef` + `.global.mongodbPassword/mongodbPasswordSecretKeyRef` + `.global.mongodbHost/mongodbHostSecretKeyRef` + `.global.mongodbOptions` instead Default MongoDB URI. Will be used by ALL services to communicate with MongoDB. Ref: https://www.mongodb.com/docs/manual/reference/connection-string/ Note! `defaultauthdb` is omitted on purpose (i.e. mongodb://.../[defaultauthdb]). |
| global.mongodbDatabase | string | `"codefresh"` | Default MongoDB database name. Don't change! |
| global.mongodbHost | string | `"cf-mongodb"` | Set mongodb host in plain text |
| global.mongodbHostSecretKeyRef | object | `{}` | Set mongodb host from existing secret |
| global.mongodbOptions | string | `"retryWrites=true"` | Set mongodb connection string options Ref: https://www.mongodb.com/docs/manual/reference/connection-string/#connection-string-options |
| global.mongodbPassword | string | `"mTiXcU2wafr9"` | Set mongodb password in plain text |
| global.mongodbPasswordSecretKeyRef | object | `{}` | Set mongodb password from existing secret |
| global.mongodbProtocol | string | `"mongodb"` | Set mongodb protocol (`mongodb` / `mongodb+srv`) |
| global.mongodbRootUser | string | `""` | DEPRECATED Use `.Values.seed.mongoSeedJob` instead. |
| global.mongodbUser | string | `"cfuser"` | Set mongodb user in plain text |
| global.mongodbUserSecretKeyRef | object | `{}` | Set mongodb user from existing secret |
| global.natsPort | int | `4222` | Default nats service port. |
| global.natsService | string | `"nats"` | Default nats service name. |
| global.newrelicLicenseKey | string | `""` | New Relic Key |
| global.nodeSelector | object | `{}` | Global nodeSelector constraints Apply nodeSelector to all Codefresh subcharts. Will not be applied on Bitnami subcharts. |
| global.oidcProviderClientId | string | `nil` | Default OIDC Provider service client ID in plain text. |
| global.oidcProviderClientSecret | string | `nil` | Default OIDC Provider service client secret in plain text. |
| global.oidcProviderPort | int | `443` | Default OIDC Provider service port. |
| global.oidcProviderProtocol | string | `"https"` | Default OIDC Provider service protocol. |
| global.oidcProviderService | string | `""` | Default OIDC Provider service name (Provider URL). |
| global.oidcProviderTokenEndpoint | string | `"/token"` | Default OIDC Provider service token endpoint. |
| global.pipelineManagerPort | int | `9000` | Default pipeline-manager service port. |
| global.pipelineManagerService | string | `"pipeline-manager"` | Default pipeline-manager service name. |
| global.platformAnalyticsPort | int | `80` | Default platform-analytics service port. |
| global.platformAnalyticsService | string | `"platform-analytics"` | Default platform-analytics service name. |
| global.postgresDatabase | string | `"codefresh"` | Set postgres database name |
| global.postgresHostname | string | `""` | Set postgres service address in plain text. Takes precedence over `global.postgresService`! |
| global.postgresHostnameSecretKeyRef | object | `{}` | Set postgres service from existing secret |
| global.postgresPassword | string | `"eC9arYka4ZbH"` | Set postgres password in plain text |
| global.postgresPasswordSecretKeyRef | object | `{}` | Set postgres password from existing secret |
| global.postgresPort | int | `5432` | Set postgres port number |
| global.postgresService | string | `"postgresql"` | Default internal postgresql service address from bitnami/postgresql subchart |
| global.postgresUser | string | `"postgres"` | Set postgres user in plain text |
| global.postgresUserSecretKeyRef | object | `{}` | Set postgres user from existing secret |
| global.rabbitService | string | `"rabbitmq:5672"` | Default internal rabbitmq service address from bitnami/rabbitmq subchart. |
| global.rabbitmqHostname | string | `""` | Set rabbitmq service address in plain text. Takes precedence over `global.rabbitService`! |
| global.rabbitmqHostnameSecretKeyRef | object | `{}` | Set rabbitmq service address from existing secret. |
| global.rabbitmqPassword | string | `"cVz9ZdJKYm7u"` | Set rabbitmq password in plain text |
| global.rabbitmqPasswordSecretKeyRef | object | `{}` | Set rabbitmq password from existing secret |
| global.rabbitmqProtocol | string | `"amqp"` | Set rabbitmq protocol (`amqp/amqps`) |
| global.rabbitmqUsername | string | `"user"` | Set rabbitmq username in plain text |
| global.rabbitmqUsernameSecretKeyRef | object | `{}` | Set rabbitmq username from existing secret |
| global.redisPassword | string | `"hoC9szf7NtrU"` | Set redis password in plain text |
| global.redisPasswordSecretKeyRef | object | `{}` | Set redis password from existing secret |
| global.redisPort | int | `6379` | Set redis service port |
| global.redisService | string | `"redis-master"` | Default internal redis service address from bitnami/redis subchart |
| global.redisUrl | string | `""` | Set redis hostname in plain text. Takes precedence over `global.redisService`! |
| global.redisUrlSecretKeyRef | object | `{}` | Set redis hostname from existing secret. |
| global.runnerService | string | `"runner"` | Default runner service name. |
| global.runtimeEnvironmentManagerPort | int | `80` | Default runtime-environment-manager service port. |
| global.runtimeEnvironmentManagerService | string | `"runtime-environment-manager"` | Default runtime-environment-manager service name. |
| global.security | object | `{"allowInsecureImages":true}` | Bitnami |
| global.storageClass | string | `""` | Global StorageClass for Persistent Volume(s) |
| global.tlsSignPort | int | `4999` | Default tls-sign service port. |
| global.tlsSignService | string | `"cfsign"` | Default tls-sign service name. |
| global.tolerations | list | `[]` | Global tolerations constraints Apply toleratons to all Codefresh subcharts. Will not be applied on Bitnami subcharts. |
| helm-repo-manager | object | See below | helm-repo-manager |
| hermes | object | See below | hermes |
| hooks | object | See below | Pre/post-upgrade Job hooks. |
| hooks.consul | object | `{"affinity":{},"enabled":true,"image":{"registry":"us-docker.pkg.dev/codefresh-inc/public-gcr-io","repository":"codefresh/kubectl","tag":"1.33.0"},"nodeSelector":{},"podSecurityContext":{},"resources":{},"tolerations":[]}` | Recreates `consul-headless` service due to duplicated ports in Service during the upgrade. |
| hooks.mongodb | object | `{"affinity":{},"enabled":true,"image":{"registry":"us-docker.pkg.dev/codefresh-inc/public-gcr-io","repository":"codefresh/mongosh","tag":"2.5.0"},"nodeSelector":{},"podSecurityContext":{},"resources":{},"tolerations":[]}` | Updates images in `system/default` runtime. |
| imageCredentials | object | `{}` | Credentials for Image Pull Secret object |
| ingress | object | `{"annotations":{"nginx.ingress.kubernetes.io/service-upstream":"true","nginx.ingress.kubernetes.io/ssl-redirect":"false","nginx.org/redirect-to-https":"false"},"enabled":true,"ingressClassName":"nginx-codefresh","labels":{},"nameOverride":"","services":{"internal-gateway":["/"]},"tls":{"cert":"","enabled":false,"existingSecret":"","key":"","secretName":"star.codefresh.io"}}` | Ingress |
| ingress-nginx | object | See below | ingress-nginx Ref: https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml |
| ingress.annotations | object | See below | Set annotations for ingress. |
| ingress.enabled | bool | `true` | Enable the Ingress |
| ingress.ingressClassName | string | `"nginx-codefresh"` | Set the ingressClass that is used for the ingress. Default `nginx-codefresh` is created from `ingress-nginx` controller subchart |
| ingress.labels | object | `{}` | Set labels for ingress |
| ingress.nameOverride | string | `""` | Override Ingress resource name |
| ingress.services | object | See below | Default services and corresponding paths |
| ingress.tls.cert | string | `""` | Certificate (base64 encoded) |
| ingress.tls.enabled | bool | `false` | Enable TLS |
| ingress.tls.existingSecret | string | `""` | Existing `kubernetes.io/tls` type secret with TLS certificates (keys: `tls.crt`, `tls.key`) |
| ingress.tls.key | string | `""` | Private key (base64 encoded) |
| ingress.tls.secretName | string | `"star.codefresh.io"` | Default secret name to be created with provided `cert` and `key` below |
| internal-gateway | object | See below | internal-gateway |
| k8s-monitor | object | See below | k8s-monitor |
| kube-integration | object | See below | kube-integration |
| mailer.enabled | bool | `false` |  |
| mongodb | object | See below | mongodb Ref: https://github.com/bitnami/charts/blob/main/bitnami/mongodb/values.yaml |
| nats | object | See below | nats Ref: https://github.com/bitnami/charts/blob/main/bitnami/nats/values.yaml |
| nomios | object | See below | nomios |
| payments.enabled | bool | `false` |  |
| pipeline-manager | object | See below | pipeline-manager |
| postgresql | object | See below | postgresql Ref: https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml |
| postgresql-ha | object | See below | postgresql Ref: https://github.com/bitnami/charts/blob/main/bitnami/postgresql-ha/values.yaml |
| postgresqlCleanJob | object | See below | Maintenance postgresql clean job. Removes a certain number of the last records in the event store table. |
| rabbitmq | object | See below | rabbitmq Ref: https://github.com/bitnami/charts/blob/main/bitnami/rabbitmq/values.yaml |
| redis | object | See below | redis Ref: https://github.com/bitnami/charts/blob/main/bitnami/redis/values.yaml |
| redis-ha | object | `{"auth":true,"enabled":false,"haproxy":{"enabled":true,"resources":{"requests":{"cpu":"100m","memory":"128Mi"}}},"persistentVolume":{"enabled":true,"size":"10Gi"},"redis":{"resources":{"requests":{"cpu":"100m","memory":"128Mi"}}},"redisPassword":"hoC9szf7NtrU"}` | redis-ha # Ref: https://github.com/DandyDeveloper/charts/blob/master/charts/redis-ha/values.yaml |
| runner | object | See below | runner |
| runtime-environment-manager | object | See below | runtime-environment-manager |
| runtimeImages | object | See below | runtimeImages |
| salesforce-reporter.enabled | bool | `false` |  |
| seed | object | See below | Seed jobs |
| seed-e2e | object | `{"affinity":{},"backoffLimit":10,"enabled":false,"image":{"registry":"docker.io","repository":"mongo","tag":"latest"},"nodeSelector":{},"podSecurityContext":{},"resources":{},"tolerations":[],"ttlSecondsAfterFinished":300}` | CI |
| seed.enabled | bool | `true` | Enable all seed jobs |
| seed.mongoSeedJob | object | See below | Mongo Seed Job. Required at first install. Seeds the required data (default idp/user/account), creates cfuser and required databases. |
| seed.mongoSeedJob.mongodbRootPassword | string | `"XT9nmM8dZD"` | Root password in plain text (required ONLY for seed job!). |
| seed.mongoSeedJob.mongodbRootPasswordSecretKeyRef | object | `{}` | Root password from existing secret |
| seed.mongoSeedJob.mongodbRootUser | string | `"root"` | Root user in plain text (required ONLY for seed job!). |
| seed.mongoSeedJob.mongodbRootUserSecretKeyRef | object | `{}` | Root user from existing secret |
| seed.postgresSeedJob | object | See below | Postgres Seed Job. Required at first install. Creates required user and databases. |
| seed.postgresSeedJob.postgresPassword | optional | `""` | Password for "postgres" admin user (required ONLY for seed job!) |
| seed.postgresSeedJob.postgresPasswordSecretKeyRef | optional | `{}` | Password for "postgres" admin user from existing secret |
| seed.postgresSeedJob.postgresUser | optional | `""` | "postgres" admin user in plain text (required ONLY for seed job!) Must be a privileged user allowed to create databases and grant roles. If omitted, username and password from `.Values.global.postgresUser/postgresPassword` will be used. |
| seed.postgresSeedJob.postgresUserSecretKeyRef | optional | `{}` | "postgres" admin user from exising secret |
| segment-reporter.enabled | bool | `false` |  |
| tasker-kubernetes | object | `{"affinity":{},"container":{"image":{"registry":"us-docker.pkg.dev/codefresh-enterprise/gcr.io","repository":"codefresh/tasker-kubernetes"}},"enabled":true,"hpa":{"enabled":false},"imagePullSecrets":[],"nodeSelector":{},"pdb":{"enabled":false},"podSecurityContext":{},"resources":{"limits":{},"requests":{"cpu":"100m","memory":"128Mi"}},"tolerations":[]}` | tasker-kubernetes |
| webTLS | object | `{"cert":"","enabled":false,"key":"","secretName":"star.codefresh.io"}` | DEPRECATED - Use `.Values.ingress.tls` instead TLS secret for Ingress |
