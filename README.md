# blog_template

A template for a personal site where every page is a Jupyter notebook, built by [MyST](https://mystmd.org) and served free on GitHub Pages. Posts show the outputs committed with the notebook; a post can link to an editable copy that runs in the reader's browser (JupyterLite).

**Use this template and run it on your own domain.** The steps are below. The reasoning behind the design is the post: [Design of this site and how to run it yourself](bootstrap.ipynb).

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

### 7. Posts in their own repo

Optional, and what the hub loop below needs. Keep the notebooks in a public repo, one per post, and mount it:

```bash
git submodule add -b main https://github.com/<user>/<posts-repo>.git posts
```

The workflow builds that repo's head, so a push there publishes without a commit here, once the posts repo can start the deploy:

- A fine-grained token: repository access, this repo only; permission, Actions read and write. Store it in the posts repo: `gh secret set SITE_ACTIONS_TOKEN -R <user>/<posts-repo>`.
- A workflow in the posts repo, on push to `main`:
  ```yaml
  - run: gh api -X POST repos/<user>/<site-repo>/actions/workflows/deploy.yml/dispatches -f ref=main
    env:
      GH_TOKEN: ${{ secrets.SITE_ACTIONS_TOKEN }}
  ```

## Write a post

1. Save the notebook **with its outputs** as `posts/YYYY-MM-DD-title.ipynb`. `myst.yml` lists `posts/*.ipynb` by pattern, newest first.
2. Add a listing line with a one-sentence blurb to `blog.ipynb`.
3. Push. If `posts/` is a submodule, push inside it; its workflow starts the deploy. Then `git submodule update --remote posts` here, commit, push.

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
| `posts/` | dated notebooks, committed with outputs; a directory, or the posts repo as a submodule |
| `CNAME` | your domain, one line; absent means a `github.io` path |
| `robots.txt` | crawler policy, copied into the build |
| `custom.css` | three lines, hides the duplicate home entry in the sidebar |
| `.github/workflows/deploy.yml` | build and deploy; no site-specific values in it. Content submodules build at their remote head, so a push to a public `posts` submodule plus a workflow dispatch publishes without a commit here |
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

To author on the hub, clone the posts repo there with a **deploy key scoped to that repo, write access only** — never a personal SSH key on a cloud box. `tljh/README.md` has the full loop with jupyterlab-git.
