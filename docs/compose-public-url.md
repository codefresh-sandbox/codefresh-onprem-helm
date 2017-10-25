# Abstract

We want to be able to run a Docker composition inside a dind pod.

For now, it's not possible because the composition's containers aren't exposed
to the external network.

# Test configuration

I run a regular dind environment and replaced the runtime_env configmap with the
content of [runtime_env.yml](runtime_env.yml) file. Just make sure to adjust the
names depending on the name of the dynamic environment you're running, the
included example assumes the environment is named `ext`.

Note that the api should be restarted after this change.

I also removed both the runner and the builder statefulSets and adjusted their
consul registration scripts to register them under the `codefresh2` environment.

# Test run

After creating a simple demochat composition, I was able to run it inside a
runner pod.

Now, I submitted the following ingress file in the dynamic environment's namespace:

```
---
apiVersion: v1
kind: Service
metadata:
  name: composition-demochat-5000
spec:
  type: ClusterIP
  ports:
  - name: "http"
    port: 5000
    protocol: TCP
    targetPort: 5000
  selector:
    app: composition-runner

---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.allow-http: "false"
    kubernetes.io/ingress.class: nginx
  name: demochat
spec:
  rules:
  - host: demochat.composition.dev.codefresh.io
    http:
      paths:
      - backend:
          serviceName: composition-demochat-5000
          servicePort: 5000
```

# Architecture

At the moment, the api service communicates with Kubernetes API to create the
runtime and dind resources. We can add the logic to the API service to also
create and delete the ingress and service resources, as described above, before
and after composition's launch and termination.

The Kubernetes's DinD cluster will have one nginx ingress controller which will
be exposed using the cloud's standard L4 loadbalancer.

A DNS record will be added to point the `*.composition.codefresh.io` to this
LB's IP address.

The name by which the composition's resource will be exposed is controlled by
the `host` entry in the ingress resources the API will submit to K8s' API.

# Risks And Considerations

- It may take time for the ingress controller to refresh it's configuration.
 We need to measure if the average refresh time is acceptable and how it changes
 based on the amount of defined ingress resources.
- What is the maximum amount of ingress resources that are supported by one
 ingress controller? We are going to have one ingress resource **per each
 composition in the system!**
- The ingress resource should be cleaned along the composition. This may add
 complexity and can lead to orphan ingress resources.
- We probably should rate limit the amount of requests that each exposed
 composition will support. Since we will serve **all** compositions using the
 same (clustered) nginx controller, we don't want to overload it for everyone
 because of one user. We can also create dedicated ingress controller for high
 profile users using a namespace since it's possible to create multiple ingress
 controllers in one cluster if they are deployed in separate namespaces.

