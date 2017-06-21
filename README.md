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

# Install Codefresh

```sh
$ # set RELEASE_NAME and NAMESPACE to whatever you want - namespace and Helm release will be created/updated
$ helm --debug upgrade $RELEASE_NAME codefresh --install --reset-values --namespace $NAMESPACE
```