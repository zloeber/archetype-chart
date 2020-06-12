# Archetype Chart

A declarative helm chart for deploying common types of services on Kubernetes

## Requirements

Each file in templates is generally a smaller part of a larger chart with more benefit gained by using more components to make a full deployment. Noticeable additions are made for 'project' elements like the project configmap integration into deployments.

Some chart elements have cluster requirements:

- To use the 'keyvaultSecret' deployment the following will need to be deployed on your cluster:Azure keyvault injection application (https://github.com/SparebankenVest/azure-key-vault-to-kubernetes)
- To use 'certificate' deployments cert-manager CRDs will need to be installed.
- To use 'SparkApplication' deployments the google spark operator CRDs will need to be installed.
- To use some rbac elements rbacmanager CRDs will need to be installed.

## Usage

```bash
helm repo add archetype https://zloeber.github.io/archetype-chart/
```

## Building/Publishing

Update the chart version in Chart.yaml, then run the following to perform a release for that version.

```bash
make build cr/upload cr/index
git add --all . && git commit -m 'release: new release'
git push origin master
git checkout gh-pages
git merge master
git push origin gh-pages
git checkout master
```

## Credits

(monochart)[https://github.com/cloudposse/charts/tree/master/incubator/monochart] - The original, and best, archetype chart