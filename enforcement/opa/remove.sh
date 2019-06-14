#!/bin/bash

# NOTE: ONLY RUN THIS IS YOU HAVE SET UP OPA USING THE PROVIDED APPLY.SH SCRIPT
# OTHERWISE YOU MAY REMOVE CLUSTER SYSTEMS YOU DID NOT INTEND TO REMOVE

kubectl delete clusterrolebinding opa-viewer -n enforcement
kubectl delete role configmap-modifier -n enforcement
kubectl delete rolebinding opa-configmap-modifier -n enforcement
kubectl delete service opa -n enforcement
kubectl delete deployment opa -n enforcement
kubectl delete configmap opa-default-system-main -n enforcement
kubectl delete secret opa-server -n enforcement

kubectl label ns kube-system openpolicyagent.org/webhook-
kubectl label ns enforcement openpolicyagent.org/webhook-

kubectl delete validatingwebhookconfiguration opa-validating-webhook