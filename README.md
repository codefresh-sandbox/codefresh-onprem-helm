### How to build CF onprem chart locally

```shell
yq m -x codefresh/env/on-prem/values.yaml codefresh/env/on-prem/versions.yaml > codefresh/values.yaml
helm dependency update codefresh --debug
helm package codefresh
```
