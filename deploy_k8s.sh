  
#!/bin/bash

kubectl config use-context docker-desktop || exit 1
kubectl create ns opentelemetry
kubectl create ns tracing

set -e

echo deploying opentelemetry agent and collector...
kubectl -n opentelemetry apply -f k8s/opentelemetry/agent.yaml
kubectl -n opentelemetry apply -f k8s/opentelemetry/collector.yaml

# echo deploying opentelemetry collector operator...
# kubectl -n opentelemetry apply -f k8s/opentelemetry/operator/crds/opentelemetry.io_opentelemetrycollectors_crd.yaml
# kubectl -n opentelemetry apply -f k8s/opentelemetry/operator/role_binding.yaml
# kubectl -n opentelemetry apply -f k8s/opentelemetry/operator/role.yaml
# kubectl -n opentelemetry apply -f k8s/opentelemetry/operator/service_account.yaml
# kubectl -n opentelemetry apply -f k8s/opentelemetry/operator/operator.yaml
# kubectl -n opentelemetry apply -f k8s/opentelemetry/operator/crds/simplest.yaml

echo deploying kube-prometheus...
kubectl create -f k8s/kube-prometheus/manifests/setup
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
kubectl create -f k8s/kube-prometheus/manifests/

echo deploying jaeger-operator...
kubectl -n tracing create -f k8s/jaeger-operator/crd.yaml
kubectl -n tracing create -f k8s/jaeger-operator/rbac.yaml
kubectl -n tracing create -f k8s/jaeger-operator/operator.yaml
until kubectl -n tracing get jaeger ; do date; sleep 1; echo ""; done
kubectl -n tracing create -f k8s/jaeger-operator/jaeger_cr.yaml

