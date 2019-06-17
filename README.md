### Purpose

Working within Kubernetes you quickly realize there are many services that can be quickly stood up with a couple YAML files and configurations. This toolbox represents an ever growing list of scripts and YAML files to quickly deploy onto a Kubernetes cluster for R&D or development testing purposes. Most of the services are installed as bare services like Open Policy Agent (OPA), OPA will be installed as an admission controller for the cluster without policies. The policies are deemed use case specific and thus are currently, outside the scope of the toolbox. Simply put, the end goal is to assemble a toolbox that allows Kubernetes Developers to quickly stand up clusters and deploy the services they need in minutes.

### How the toolbox operates

The toolbox is a collection of bash scripts and YAML files (some templated, some not). The bash scripts apply the services onto a cluster and will handle generating YAML files (from the template YAMLS) when custom information is required. This is the intended way to use the toolbox but if needed you can apply the included YAMLS on a per need basis. :) 
