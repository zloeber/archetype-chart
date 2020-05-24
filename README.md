# Archetype

A declarative helm chart for deploying common types of services on Kubernetes

## Requirements

Each file in templates is generally a smaller part of a larger chart with more benefit gained by using more components to make a full deployment. Noticeable additions are made for 'project' elements like the project configmap integration into deployments.

Some chart elements have cluster requirements:

- To use the 'keyvaultSecret' deployment the following will need to be deployed on your cluster:Azure keyvault injection application (https://github.com/SparebankenVest/azure-key-vault-to-kubernetes)
- To use 'certificate' deployments cert-manager CRDs will need to be installed.
- To use 'SparkApplication' deployments the google spark operator CRDs will need to be installed.
- To use some rbac elements rbacmanager CRDs will need to be installed.
