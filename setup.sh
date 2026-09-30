#!/usr/bin/env bash
set -euo pipefail

TITLE="Your Name"
DOMAIN=""
GITHUB_USER="yourusername"

cd "$(dirname "$0")"

if [ "$TITLE" = "Your Name" ] || [ "$GITHUB_USER" = "yourusername" ]; then
  echo "Edit TITLE, DOMAIN and GITHUB_USER at the top of this script first." >&2
  exit 1
fi

if [ -n "$DOMAIN" ]; then
  echo "$DOMAIN" > CNAME
else
  rm -f CNAME
fi

python3 - "$TITLE" "$GITHUB_USER" <<'PY'
import sys

title, user = sys.argv[1], sys.argv[2]
for path in ("myst.yml", "index.md", "about.ipynb"):
    with open(path) as fh:
        text = fh.read()
    with open(path, "w") as fh:
        fh.write(text.replace("Your Name", title).replace("yourusername", user))
PY

echo "Done."
echo
echo "Next:"
echo "  - Write index.md and about.ipynb."
if [ -n "$DOMAIN" ]; then
  echo "  - Point $DOMAIN at GitHub Pages: four A records to 185.199.108-111.153."
  echo "  - Settings > Pages: source 'GitHub Actions', custom domain $DOMAIN."
else
  echo "  - Settings > Pages: source 'GitHub Actions'."
fi
echo "  - Delete the Disallow line in robots.txt when you want to be indexed."
echo "  - Commit and push to main."
