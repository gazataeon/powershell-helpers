# Kubernetes Scripts for Azure

## K8s platform build script - "build-k8s-infra.ps1"
This script will provision you a full Staging, Live and Management environment for the deployment of images to Kubernetes clusters.

Creates/configures the following:
* 3 Resource groups. Staging, Live and management.
* 2 Kubernetes Clusters, Staging and live.
* 1 Container registry in the management resource group.
    * enables docker style admin login to this registry.
* 3 Service Principles, for Management, Staging and Live services.
* 2 Public static IPs to be used for your Services later.

### Kubernetes YML config 
Because microsoft are crazy and Azure likes to be different, you need to do a little bit of messing around to get the static IP in use for your service.
Notice the below YML, the `loadBalancerIP` is defined there as well as in the meteadata block the resource group where the object lives.
Now MS say you need to put this in it's own RG with the strange format of `MC_myResourceGroup_myAKSCluster_eastus` (see here: https://docs.microsoft.com/en-us/azure/aks/static-ip).

I say, why? why do that? 

Yes you don't have to define the metadata in your YML later as below, but it also means having your Public IP resource sat alone in it's own resource group in a name format that may not fit with yours.


Example: `project1-service.yml`
```
---

kind: Service
apiVersion: v1
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: eu-w-k8s-live-rg
  name: project1-lb-live
  namespace: project1
spec:
  loadBalancerIP: 123.456.789.1
  type: LoadBalancer
  selector:
    app: project1
    role: web
    track: live
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80

---
```