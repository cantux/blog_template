# blog_template

A template for a personal site where every page is a Jupyter notebook, built by [MyST](https://mystmd.org) and served free on GitHub Pages. Posts show the outputs committed with the notebook; a post can link to an editable copy that runs in the reader's browser (JupyterLite).

**Use this template and run it on your own domain.** The steps are below. The reasoning behind the design is the post: [How this site is built](bootstrap.ipynb).

## Use it

### 1. Create your repo

Click **Use this template** on GitHub, or fork. Clone it.

### 2. Personalize

Open `setup.sh`, set three variables at the top, and run it:

```bash
TITLE="Jane Doe"
DOMAIN="janedoe.com"     # leave "" to publish at <user>.github.io/<repo>
GITHUB_USER="janedoe"
```

```bash
./setup.sh
```

It writes `CNAME` and puts your name into `myst.yml`, `index.md` and `about.ipynb`. Then write `index.md` and `about.ipynb`. They are yours now.

### 3. DNS

Skip this if you left `DOMAIN` empty.

| Name | Type | Value |
|---|---|---|
| `yourdomain.com` | A | `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153` |

Four A records, not a CNAME — an apex name cannot be a CNAME because it already carries the zone's SOA and NS records.

### 4. Turn on Pages

In the repo: **Settings → Pages**.

- **Source: GitHub Actions.** Not "Deploy from a branch". Nothing deploys until this is set.
- **Custom domain:** your domain. GitHub provisions the certificate; tick **Enforce HTTPS** once it goes green, which can take a few minutes.

### 5. Let search engines in

`robots.txt` ships with `Disallow: /`, so a site under construction stays out of the index. Delete that line when you want readers.

### 6. Push

```bash
git add -A && git commit -m "Make it mine" && git push
```

Every push to `main` runs [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml), which builds and deploys. First run takes a couple of minutes. Watch it in the Actions tab.

## Write a post

1. Save the notebook **with its outputs** as `posts/YYYY-MM-DD-title.ipynb`.
2. Add it under `blog.ipynb`'s children in `toc` in `myst.yml`.
3. Add a listing line with a one-sentence blurb to `blog.ipynb`.
4. Push.

The build never starts a kernel — it renders the outputs already in the file. So whatever the notebook looked like when you saved it is what ships.

To offer an editable copy that runs in the reader's browser, link it from the post. Do this only when everything the notebook imports exists in Pyodide:

```
**[In-browser notebook →](/lite/notebooks/index.html?path=YYYY-MM-DD-title.ipynb)**
```

## Local preview

```bash
npx mystmd start
```

Serves at http://localhost:3000 with hot reload. `/lite/` links 404 locally — that app is only built in CI.

To execute notebooks locally (the site build never needs this):

```bash
python3 -m venv .venv && .venv/bin/pip install jupyter numpy matplotlib plotly
.venv/bin/jupyter execute --inplace posts/<post>.ipynb
```

## What's in here

| path | what it is |
|---|---|
| `myst.yml` | the entire site config — toc and theme |
| `index.md` | landing page |
| `about.ipynb`, `blog.ipynb` | pages, same as any post |
| `bootstrap.ipynb` | the post that explains this design; keep it or drop it |
| `posts/` | dated notebooks, committed with outputs |
| `CNAME` | your domain, one line; absent means a `github.io` path |
| `robots.txt` | crawler policy, copied into the build |
| `custom.css` | three lines, hides the duplicate home entry in the sidebar |
| `.github/workflows/deploy.yml` | build and deploy; no site-specific values in it |
| `scripts/jlite_contents.py` | stages `posts/` for the JupyterLite build |
| `setup.sh` | one-shot personalization |
| `tljh/`, `z2jh/` | optional private authoring hub, two flavors |

## Taking later fixes from the template

Your name, domain, pages and posts are yours; everything else is meant to merge.

```bash
git remote add template https://github.com/cantux/blog_template.git
git pull template main            # add --allow-unrelated-histories the first time if you used "Use this template"
```

## Optional: an authoring hub

You do not need this to run the site. It is a private JupyterHub for writing notebooks against real hardware — GPU, compiled packages, live kernels — with nothing on the published site pointing at it. Two flavors, both runnable locally in a Lima VM before any cloud spend:

```bash
limactl start --name=tljh tljh/local/tljh-local.yaml   # http://localhost:12000
./z2jh/local/up.sh                                     # http://localhost:12080
```

`tljh/` is The Littlest JupyterHub on one EC2 instance. `z2jh/` is Zero to JupyterHub on Kubernetes, local-first, with cloud specifics confined to `values-eks.yaml`. Each directory has its own README. Running one costs about $21 a month; the post has the breakdown.

To author on the hub, clone this repo there with a **deploy key scoped to this repo, write access only** — never a personal SSH key on a cloud box:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/blog_deploy -N ''
```

Add `~/.ssh/blog_deploy.pub` under Settings → Deploy keys with write access, then:

```bash
GIT_SSH_COMMAND='ssh -i ~/.ssh/blog_deploy' git clone git@github.com:<user>/<repo>.git
git config core.sshCommand 'ssh -i ~/.ssh/blog_deploy'
```
