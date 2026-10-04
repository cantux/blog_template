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

Keep the posts in their own public repo and mount it as the site repo's `posts/` submodule: the deploy workflow builds that repo's head. On the hub you write in a clone of the posts repo and push from JupyterLab's Git tab; the posts repo's workflow starts the site deploy with a token that can only run workflows.

One-time, from a JupyterLab terminal on the hub (admin users have passwordless sudo, so no SSH key is needed):

```bash
sudo -E /opt/tljh/user/bin/pip install jupyterlab-git nbdime
sudo tee /opt/tljh/user/share/jupyter/lab/settings/overrides.json <<'EOF'
{"@jupyterlab/git:plugin": {"commitAndPush": true, "simpleStaging": true}}
EOF
ssh-keygen -t ed25519 -f ~/.ssh/posts_deploy -N ''
cat ~/.ssh/posts_deploy.pub    # add it as a deploy key with write access on the posts repo
GIT_SSH_COMMAND='ssh -i ~/.ssh/posts_deploy -o StrictHostKeyChecking=accept-new' git clone git@github.com:<user>/<posts-repo>.git ~/posts
git -C ~/posts config core.sshCommand 'ssh -i ~/.ssh/posts_deploy'
git -C ~/posts config user.name <user>
git -C ~/posts config user.email <user>@users.noreply.github.com
```

Restart your server (File → Hub Control Panel → Stop → Start) so the extension loads. Then: write in `~/posts`, open the Git tab, commit; the push follows. The posts repo needs a workflow that runs `gh api -X POST repos/<user>/<site-repo>/actions/workflows/deploy.yml/dispatches -f ref=main` with a fine-grained token (repository access: the site repo; permission: Actions, read and write). Call the REST endpoint, not `gh workflow run`: that command looks up the default branch over GraphQL, which refuses fine-grained tokens.
