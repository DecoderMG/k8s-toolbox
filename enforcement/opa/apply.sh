#!/bin/bash

# Initial scripts to apply Open Policy Agent on the cluster.

caCertPath=''
caKeyPath=''
tlsCertPath=''
tlsKeyPath=''

echo "Open Policy Agent needs TLS and CA certs to be stood up."
echo "Do you have a CA cert you'd like to provide?(yes/no)"
read hasCaCert

if [ "${hasCaCert}" = 'yes' ]
then
  echo "Please provide the complete path to your CA private key file: "
  read caKeyPath
  echo "Please provide the complete path to your CA cert file: "
  read caCertPath
else
  echo "Generating 2048 bit ca.key set to expire in 1000 days in working directory..."
  openssl genrsa -out ca.key 2048
  openssl req -x509 -new -nodes -key ca.key -days 1000 -out ca.crt -subj "/CN=admission_ca"
  caCertPath="$(pwd)/ca.crt"
  caKeyPath="$(pwd)/ca.key"
fi

echo "Do you have a TLS certificate and private key you'd like to use for the OPA server?(yes/no)"
read hasTlsCert

if [ "${hasTlsCert}" = 'yes' ]
then
  echo "Please provide the path to your tls private key: "
  read tlsKeyPath
  echo "Please provide the path to your tls certificate: "
  read tlsCertPath
else
  if [ "${hasCaCert}" = 'yes' ]
  then
    echo "Would you like to use the CA key you provided to generate the OPA server certs?(yes/no)"
    read useCAkey
  fi
  echo "Generating server configuration in working directory..."
    cat >server.conf <<ENDOFCONFIG
    [req]
    req_extensions = v3_req
    distinguished_name = req_distinguished_name
    [req_distinguished_name]
    [ v3_req ]
    basicConstraints = CA:FALSE
    keyUsage = nonRepudiation, digitalSignature, keyEncipherment
    extendedKeyUsage = clientAuth, serverAuth
ENDOFCONFIG
  echo "Generating TLS certificate and private key in working directory with a validity of 1000 days..."
  openssl genrsa -out server.key 2048
  tlsKeyPath="$(pwd)/server.key"
  openssl req -new -key server.key -out server.csr -subj "/CN=opa.opa.svc" -config server.conf

  if [ "${useCAkey}" = 'yes' ]
  then
    openssl x509 -req -in server.csr -CA $caCertPath -CAkey $caKeyPath -CAcreateserial -out server.crt -days 1000 -extensions v3_req -extfile server.conf
  else
    openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 1000 -extensions v3_req -extfile server.conf
  fi
  tlsCertPath="$(pwd)/server.crt"
fi

# Kubectl is smart enough not to double dip, calling create is safe for checking or creating the ns we need.
echo "Ensuring enforcement namespace exists."
kubectl create namespace enforcement

# Make sure we can access OPA TLS information within the cluster
echo "Creating secret to store OPA TLS information in."
kubectl create secret tls opa-server --cert=${tlsCertPath} --key=${tlsKeyPath} --namespace enforcement

# Generate deployment and webhook yamls from template files
rm -f deployment.yaml temp.yaml 
( echo "cat <<ENDOFYAML >deployment.yaml";
  (cat deployment-template.yaml);
  ENDOFYAML;
) >temp.yaml
. temp.yaml
rm temp.yaml

rm -f webhook-configuration.yaml temp.yaml  
( echo "cat <<ENDOFYAML >webhook-configuration.yaml";
  (cat webhook-configuration-template.yaml);
  ENDOFYAML;
) >temp.yaml
. temp.yaml
rm temp.yaml

# Apply OPA yamls 
echo "Deploying OPA onto cluster."
kubectl apply -f cluster-role-binding.yaml
kubectl apply -f role.yaml
kubectl apply -f role-binding.yaml
kubectl apply -f service.yaml
kubectl apply -f deployment.yaml
kubectl apply -f configmap.yaml

# Some OPA label enforcement
echo "Labeling kube-system and enforcement namespaces with openpolicyagent.org/webhook=ignore to ensure OPA does not mess with itself of k8s core"
kubectl label ns kube-system openpolicyagent.org/webhook=ignore
kubectl label ns enforcement openpolicyagent.org/webhook=ignore

echo "Registering OPA as a cluster administration controller"
kubectl apply -f webhook-configuration.yaml

echo "OPA deployed onto cluster!"