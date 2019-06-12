#!/bin/bash

# Initial scripts to deploy a node level fluentd logger across a k8s cluster using elastic search.

echo 'Please provide Elasticsearch Host: '
read elasticsearchHost
echo 'Please provide Elasticsearch Port: '
read elasticsearchPort
echo 'Please provide Elasticsearch Schema: '
read elasticsearchSchema
echo 'Please provide Fluentd UID: '
read fluentdUid
echo 'Please provide Elasticsearch Username for Fluentd to use: '
read elasticsearchUsername
echo 'Please provide Elasticsearch password for Fluentd to use: '
read elasticsearchPassword

# Deploy fluentd service account and cluser role
kubectl apply -f service-account.yaml
kubectl apply -f cluster-role.yaml
kubectl apply -f cluster-role-binding.yaml

# Apply collected elastic search config from user and deploy daemonset.
rm -f elasticsearch-daemonset.yaml temp.yaml  
( echo "cat <<EOF >elasticsearch-daemonset.yaml";
  cat elasticsearch-daemonset-template.yaml;
  echo "EOF";
) >temp.yaml
. temp.yaml
rm temp.yaml

kubectl apply -f elasticsearch-daemonset.yaml