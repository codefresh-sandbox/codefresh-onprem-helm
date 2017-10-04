# Local Setup

## Prerequisites
1. minikube `brew cask install minikube`
2. helm `brew install kubernetes-helm`
3. sops `brew install sops`
4. go 1.8.1 (or newer)
5. helm plugin chartify `helm plugin install https://github.com/rimusz/helm-chartify`
6. helm plugin template `helm plugin install https://github.com/technosophos/helm-template`

## installation

For local development use [minikube](https://github.com/kubernetes/minikube). 
Download and install it manually, or using `homebrew cask` with `brew cask install minikube` command (only macOS).

For macOS it's recommended to use lightweight VM `xhive`.
Install it with:
```sh
$ brew install docker-machine-driver-xhyve
```

## create local development K8s cluster

Create a new `minikube` cluster with sufficient resources.

```sh
$ # --cpus - 2 cores
$ # --memory - 4GB RAM
$ # --disk-size - 20GB disj
$ minikube start --cpus=2 --memory=4096 --disk-size=20g
```

Or use helper script `start_minikube.sh` and override some environment variables, if you like to customize it.

**Note**: wait several minutes till `minikube` download and install all components. You can check `minikube` status on K8s dashboard.

## enable `minikube` addons

List enabled addons:

```sh
$ # list all addons
$ minikube addons list
- addon-manager: enabled
- dashboard: enabled
- default-storageclass: enabled
- kube-dns: enabled
- heapster: enabled
- ingress: enabled
- registry-creds: disabled
```

Enable `heapster`, `dashboard`, `ingressּּּּ` and other useful addons:

```sh
$ minikube addons enable ingress
$ minikube addons enable dashboard
$ minikube addons enable heapster
# use minikube addons open heapster to open Heapster Dashboard
```

# Install Helm

Minimal required Helm version is `2.5.1`.


```sh
# install Helm client
$ brew install kubernetes-helm

# install Helm
$ helm init --upgrade

$HELM_HOME has been configured at /Users/alexei/.helm.

Tiller (the helm server side component) has been installed into your Kubernetes Cluster.
Happy Helming!
```

show helm version:

```sh
$ helm version

Client: &version.Version{SemVer:"v2.5.1", GitCommit:"7cf31e8d9a026287041bae077b09165be247ae66", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.5.1", GitCommit:"7cf31e8d9a026287041bae077b09165be247ae66", GitTreeState:"clean"}

```

# Handle Secrets

> Run `./sops.sh -d` before `helm update/install` to decrypt (locally) values files with secrets keys

Files that contain secret keys should not be submitted to Git un-encrypted. In order to properly encrypt files, we use [sops](https://github.com/mozilla/sops) tool (by Mozilla team) with private key stored in AWS KMS service.

Use helper script `sops.sh` to encrypt and decrypt values files with secret data. The `sops.sh` scripts is looking for any `*-dec.yaml` files and creates an encrypted copy (`*-enc.yaml`) of these files. You should commit only `*-enc.yaml` files into `git` repository.  

**Note**: You can also work with `sops` directly: run `sops <filename>` to decrypt, edit and encrypt any secret file.

`sops.sh` helper script

```sh
#!/bin/sh

# read input parameters
while [ $# -gt 0 ]
do
  case "$1" in
    -d) dec=1; shift;;
    -e) enc=1; shift;;
    -h)
        echo >&2 "usage: $0 -(e|d) [encrypt|decrypt '*-enc.yaml' values files]"
        exit 1;;
     *) break;; # terminate while loop
  esac
  shift
done

# encrypt files
if [[ $enc -eq 1 ]]; then
  for f in $(find . -name "*-dec.yaml"); do 
    echo "Encrypting $f ..."
    sops -e $f > ${f/dec/enc}
  done
fi

# descrypt files
if [[ $dec -eq 1 ]]; then
  for f in $(find . -name "*-enc.yaml"); do 
    echo "Decrypting $f file"
    sops -d $f > ${f/enc/dec}
  done
fi
```

To avoid commiting non-encrypted secrets into `git` repository, you can install a helper `git` hook.

Put `.sopscommithook` file into `.git/hooks` directory (make sure it's executable)

```sh
#!/bin/sh

for FILE in $(git diff-index HEAD --name-only | grep <your vars dir> | grep "dec.yaml"); do
    if [ -f "$FILE" ] && ! grep -C10000 "sops:" $FILE | grep -q "version:"; then
    then
        echo "!!!!! $FILE" 'file is not encrypted!!!'
        echo "Run: ./sops.sh -e"
        exit 1
    fi
done
exit
```

# (Optional) Docker Registry Mirror

To speedup Docker image downloads, after restarting or reinstalling minikube, point Docker Registry, running in minikube to local directory (use `start_minikube.sh` helper script).

Make sure to create `~/.mirror/config` and `~/.mirror/data` folders.

Put `config.yml` file (see bellow) into `~/.mirror/config`.

```yaml
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
proxy:
  remoteurl: https://registry-1.docker.io
```

# Install Codefresh

## Update chart dependencies

## Update or install Codefresh

```sh
$ # decrypt secret keys (optional step)
$ ./sops.sh -d
$ 
$ # update all dependencies
$ helm dependency update codefresh
$ 
$ # set RELEASE_NAME and NAMESPACE to whatever you want - namespace and Helm release will be created/updated
$ helm --debug upgrade $RELEASE_NAME codefresh --install --reset-values --recreate-pods --namespace $NAMESPACE --values codefresh/values.yaml --values codefresh/values-dec.yaml --values codefresh/regsecret-dec.yaml --values codefresh/env/$ENVIRONMENT/values.yaml --values codefresh/env/$ENVIRONMENT/values-dec.yaml
```

## Linter and friends

Use following techniques to debug and validate Helm charts.

### 1. Helm lint

```sh
$ helm lint $CHARTNAME
```

Do not expect too much, helm linter is a very basic one.

### 2. Dry Run

You can generate expected output with `--dry-run` flag.

```sh
$ helm --dry-run --debug install $CHARTNAME --values ...
```

### 3. Helm Template plugin

[Helm template plugin](https://github.com/technosophos/helm-template) generates Kubernetes YAML file (one file with multiple documents). It is doing this on client side, without uploading to Tiller server.

```sh
# install
$ helm plugin install https://github.com/technosophos/helm-template
# use
$ helm template --namespace $NAMESPACE $CHARNAME --values ...
``` 

### 4. Kubeval tool

[Kubeval](https://github.com/garethr/kubeval) is an open source tool that can validate Kubernetes YAML against specification (JSON schema).

```sh 
$ kubeval FILE.yaml
```

One drawback is that Kubeval cannot parse multi document YAML. Use `csplit` utility (or `gcsplit` on MacOS)

```sh
# generate YAML file from Helm chart
$ helm template ... > output.yaml
# split it into multiple files
$ csplit assa.yaml '/^---/' {*}
# run kubeval on all docs: xx## is a doc name pattern for csplit
$ for f in $(ls xx*); do kubeval $f; done
```

## Packaging And Distribution

To package the codefresh chart, run:

```
helm package codefresh
```

This will create a local `*.tgz` file. Now we need to generate the index file
and merge it with the existing index file in our charts repository.

To generate a new index file, run:

```
wget http://codefresh-helm-charts.s3-website-us-east-1.amazonaws.com/index.yaml
helm repo index . --merge index.yaml --url http://codefresh-helm-charts.s3-website-us-east-1.amazonaws.com
```

Now upload both the updated `index.yaml` file and the `*.tgz` package file to
Codefresh' charts repository:

```
s3cmd cp index.yaml s3://codefresh-helm-charts/
s3cmd cp <package-full-name>.tgz s3://codefresh-helm-charts/
```

## TODO

- [x] Add tls-sign
- [x] Add cf-runtime
- [x] Fix Github log-in issues when working locally
- [x] Fix build issues
- [ ] Add all environment's secrets
  -  [ ] Write a helper script for launching helm with proper env values
- [ ] Research a better way to allow access to our Docker images
- [x] Add Codefresh helm repository
- [ ] Add Codefresh pipeline with helm
  - [x] Dynamic env
  - [x] Minikube local development environment
  - [ ] Staging
  - [ ] Production
- [ ] Integrate with on-prem installation procedures
- [x] Update to helm 2.5.1
- [x] Check if we can replicate Drone's cool helm plugin
- [ ] Submit nats and registry to Kubernetes apps repo

