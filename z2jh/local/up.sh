#!/bin/bash
# Boot (or reuse) the local k3s VM and install/upgrade z2jh into it.
set -euo pipefail
cd "$(dirname "$0")"
Z2JH_DIR=$(cd .. && pwd)

limactl start --name=z2jh --tty=false ./z2jh-local.yaml

run() { limactl shell z2jh sudo "$@"; }
HELM="helm --kubeconfig /etc/rancher/k3s/k3s.yaml"
run $HELM repo add jupyterhub https://hub.jupyter.org/helm-chart/ --force-update
run $HELM repo update jupyterhub
run $HELM upgrade --install jhub jupyterhub/jupyterhub --version 4.4.1 \
  --namespace jhub --create-namespace --timeout 15m --wait \
  -f "$Z2JH_DIR/values.yaml" -f "$Z2JH_DIR/values-local.yaml"

echo
echo "Hub: http://localhost:12080  — login: admin / localdev"
echo "Stop: limactl stop z2jh   Delete: limactl delete z2jh"
