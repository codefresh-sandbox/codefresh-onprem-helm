# Helm for Codefresh

### Updaing microservice version and other non-secret parameters:
Edit `codefresh/env/<environment>/values.yaml`
For example, to change api version to v399 on production open `codefresh/env/<environment>/values.yaml`
and set `cfapi.imageTag: v399`
```
git commit -am "cfapi updated to ..."
git push
```
Than go to Codefresh and launch appropriative cf-helm pipeline
For production it is configured to start automatically by webhook

### Updating secret values
All secret values for helm are stored in file ç encrypted with sops - https://github.com/mozilla/sops  

* Install sops from https://github.com/mozilla/sops/releases
* setup aws credentials file ( ~/.aws/credentials )
```
git pull
sops -d [folder with values-enc.yaml, default ./ ]
```
It will decrypt all values-enc.yaml to values-dec.yaml
* edit values-dec.yaml
* run `sops -e [folder with values-enc.yaml, default ./ ]`
  It will encrypt all values-dec.yaml to values-enc.yaml
* commit and push
  `git commit -am "secrets for production changed" && git push`

### Updating existing chart template
* edit template. Follow general helm pattern to separate k8s definitions from environemnt specific values. 
* update version in Chart.yaml
* update version of edited chart in requirements.yaml (if it appears there)
`git commit -am "chart main-service changed" && git push`
* run cf-helm pipeline to apply changes
  
### Adding new helm chart for a microservice
We recommend to add a new chart using our cf-helm-starter boilerplate: 
https://github.com/codefresh-io/cf-helm-starter  
  
### Dev environment setup
Recommended way is to use cf-helm Codefresh pipeline - see codefresh yamls in pipeline/ and Dockerfile

If you prefer to debug helm charts locally install helm, sops, kubectl 
* Install helm by `brew install kubernetes-helm` - see https://github.com/kubernetes/helm/blob/master/docs/install.md
* Install sops from https://github.com/mozilla/sops/releases
* setup aws credentials file ( ~/.aws/credentials )

Use ./sops -d|e [env-values-dir] to decrypt|encrypt secrets
Setup environment:
```
kubectl config use-context <context>
./sops -d
. codefresh/env/<environment>/export-envs
```

and launch deploy script from bin/ :
```
bin/deploy-test-saas
```