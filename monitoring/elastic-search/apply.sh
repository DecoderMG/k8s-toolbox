#!/bin/bash

# Initial scripts to apply eleastic search cluster.

kubectl apply -f service.yaml
kubectl apply -f loadbalancer.yaml
kubectl apply -f configmap.yaml
kubectl apply -f statefulset.yaml