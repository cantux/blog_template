# JupyterHub on EC2 (TLJH)

Personal hub for authoring blog notebooks. Author-only: the blog never talks to this hub, so no CORS, no public tokens.

## Run locally first

TLJH needs Ubuntu + systemd, so on macOS it runs in a Lima VM (arm64-native; TLJH supports arm64):

```bash
limactl start --name=tljh local/tljh-local.yaml   # boots Ubuntu 24.04, installs TLJH (~5 min first time)
open http://localhost:12000                        # login: admin + any password (first login sets it)
limactl stop tljh                                  # later: limactl delete tljh
```

Same TLJH as on EC2, minus TLS/OAuth/DNS. Note the VM is arm64 while the EC2 target is x86 — fine for hub config work; Python wheels just differ.

## One-time setup

1. **Launch EC2** (console or CLI):
   - Ubuntu 24.04 LTS, **x86_64** (t3.small — x86 lets you switch to a GPU type later; ARM does not)
   - 30 GB gp3 disk
   - Security group: allow 22 (your IP only), 80, 443
   - **No IAM role** on the instance
   - Metadata: IMDSv2 **required**, hop limit 1
   - Allocate an **Elastic IP** and associate it
2. **DNS**: A record `hub.<yourdomain>` → the Elastic IP.
3. **Install TLJH** (on the instance):
   ```bash
   curl -L https://tljh.jupyter.org/bootstrap.py | sudo python3 - --admin <your-github-username>
   ```
4. **HTTPS**:
   ```bash
   sudo tljh-config set https.enabled true
   sudo tljh-config set https.letsencrypt.email <your-email>
   sudo tljh-config add-item https.letsencrypt.domains hub.<yourdomain>
   sudo tljh-config reload proxy
   ```
5. **GitHub OAuth** (create an OAuth app at github.com/settings/developers, callback `https://hub.<yourdomain>/hub/oauth_callback`):
   ```bash
   sudo tljh-config set auth.type github
   sudo tljh-config set auth.GitHubOAuthenticator.client_id <id>
   sudo tljh-config set auth.GitHubOAuthenticator.client_secret <secret>
   sudo tljh-config set auth.GitHubOAuthenticator.allowed_users <your-github-username>
   sudo tljh-config reload
   ```
6. **Limits** (single user, keep the box healthy):
   ```bash
   sudo tljh-config set limits.memory 1.5G
   sudo tljh-config reload
   ```
7. **Post deps** (shared user env):
   ```bash
   sudo -E /opt/tljh/user/bin/pip install numpy matplotlib pandas
   ```

## GPU sessions (heavy posts)

Pay GPU rates only while authoring:

1. Stop the instance (console) → Change instance type → `g4dn.xlarge` (~$0.53/hr) → Start.
2. First GPU boot only: install NVIDIA drivers (`sudo apt install -y ubuntu-drivers-common && sudo ubuntu-drivers install`), reboot. Drivers persist on disk.
3. `pip install torch` in the user env works on both CPU and GPU boots.
4. Done authoring: stop → change type back to `t3.small` → start. Elastic IP and disk survive.

## Cost

~$21/mo (t3.small $15 + disk $2.5 + IPv4 $3.6) + GPU hours as used. Set a billing alarm in CloudWatch.

## Authoring loop

Write/run notebooks on the hub → download/commit the .ipynb **with outputs** to this repo's `posts/` → CI rebuilds the site.
