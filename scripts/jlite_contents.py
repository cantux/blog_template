import json
import pathlib
import shutil

out = pathlib.Path(".jlite")
if out.exists():
    shutil.rmtree(out)
out.mkdir()

for nb in pathlib.Path("posts").glob("*.ipynb"):
    doc = json.loads(nb.read_text())
    doc["cells"] = [
        c for c in doc["cells"]
        if "/lite/" not in "".join(c.get("source", []))
    ]
    (out / nb.name).write_text(json.dumps(doc))
