# JupyterHub on Kubernetes (z2jh)

Same author-only hub as `../tljh`, built on [Zero to JupyterHub](https://z2jh.jupyter.org) (helm chart 4.4.1). Local first, cloud later.

## Layout

- `values.yaml` — base config, environment-agnostic
- `values-local.yaml` — local overrides (dummy auth, no cloud metadata block, no prepuller/user-scheduler)
- `values-eks.yaml` — ALL cloud-specific choices live here (HTTPS, GitHub OAuth, later GPU profiles)
- `local/` — Lima VM running k3s (what z2jh's own CI tests against)

## Run locally

```bash
./local/up.sh          # boots k3s VM + helm-installs the chart (~5 min first time)
open http://localhost:12080   # login: admin / localdev  (admin user in values.yaml, password in values-local.yaml)
limactl stop z2jh      # later: limactl delete z2jh
```

Re-running `up.sh` upgrades in place after values changes. Debug: `limactl shell z2jh sudo k3s kubectl -n jhub get pods`.

The VM has nested virtualization on (real `/dev/kvm`), so it doubles as the testbed for VM-grade sandbox runtimes (Kata etc.).

## Cloud (EKS or any managed k8s)

Fill in the placeholders in `values-eks.yaml`, then on a cluster with kubectl access:

```bash
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm upgrade --install jhub jupyterhub/jupyterhub --version 4.4.1 \
  -n jhub --create-namespace -f values.yaml -f values-eks.yaml
```

DNS: point `hub.<yourdomain>` at the LoadBalancer the chart creates; the chart's autohttps handles Let's Encrypt. Cluster provisioning itself (eksctl/terraform) is not in this repo yet.
