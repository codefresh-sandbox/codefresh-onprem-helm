# Local Setup

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
$ # --cpus - 4 cores
$ # --memory - 8GB RAM
$ # --disk-size - 40GB disj
$ # --vm-driver - xhive macOS VM  
$ minikube start --cpus=4 --memory=8192 --vm-driver=xhyve --disk-size=40g
```

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

Enable `heapster`, `dashboard`, `ingressּּּּ` and other usefule addons:

```sh
$ minikube addons enable ingress
$ minikube addons enable dashboard
$ minikube addons enable heapster
```

# Install Helm

```sh
$ helm init

$HELM_HOME has been configured at /Users/alexei/.helm.

Tiller (the helm server side component) has been installed into your Kubernetes Cluster.
Happy Helming!
```

show helm version:

```sh
$ helm version

Client: &version.Version{SemVer:"v2.4.2", GitCommit:"82d8e9498d96535cc6787a6a9194a76161d29b4c", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.4.2", GitCommit:"82d8e9498d96535cc6787a6a9194a76161d29b4c", GitTreeState:"clean"}
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
$ helm --debug upgrade $RELEASE_NAME codefresh --install --reset-values --recreate-pods --namespace $NAMESPACE --values values.yaml --values values-dec.yaml
```