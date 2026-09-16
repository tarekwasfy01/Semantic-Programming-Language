#!/usr/bin/env python3
import json, os, re, sys, tempfile, urllib.request, urllib.parse, zipfile
from pathlib import Path

EVENT_PATH = os.environ.get("GITHUB_EVENT_PATH")
REGISTRY = Path(os.environ.get("REGISTRY_FILE", "modules.json"))


def fail(msg):
    print(f"::error::{msg}")
    Path(os.environ.get("GITHUB_OUTPUT", "/tmp/out")).open("a").write(f"result=invalid\nmessage={msg}\n")
    sys.exit(1)


def extract(body, heading):
    # Works with both the pre-filled website issue body and GitHub Issue Forms.
    rx = rf"###\s+{re.escape(heading)}\s*\n+(.+?)(?=\n###\s+|\Z)"
    m = re.search(rx, body or "", re.I | re.S)
    if not m:
        return ""
    value = m.group(1).strip()
    # Issue forms may include _No response_ markers.
    return "" if value.lower() in {"_no response_", "no response"} else value.splitlines()[0].strip()


def parse_version(url):
    name = urllib.parse.unquote(urllib.parse.urlparse(url).path.rsplit('/', 1)[-1])
    stem = re.sub(r"\.zip$", "", name, flags=re.I)
    m = re.search(r"(?:[-_.]?v)(\d+)$", stem, re.I)
    return (stem[:m.start()].rstrip("-_."), int(m.group(1))) if m else (stem, 1)


def same_update_family(old_url, new_url):
    old, new = urllib.parse.urlparse(old_url), urllib.parse.urlparse(new_url)
    if old.scheme != "https" or new.scheme != "https": return False
    if old.netloc.lower() != new.netloc.lower(): return False
    old_dir = old.path.rsplit('/',1)[0]
    new_dir = new.path.rsplit('/',1)[0]
    ob, ov = parse_version(old_url); nb, nv = parse_version(new_url)
    return old_dir == new_dir and ob.lower() == nb.lower() and nv > ov


def download(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent":"Semantic-Module-Registry/1.0"})
    with urllib.request.urlopen(req, timeout=90) as r, open(dest, "wb") as f:
        while True:
            chunk = r.read(1024 * 1024)
            if not chunk: break
            f.write(chunk)


def main():
    if not EVENT_PATH: fail("Missing GitHub event payload")
    event = json.load(open(EVENT_PATH, encoding="utf-8"))
    body = event.get("issue", {}).get("body", "")
    title = event.get("issue", {}).get("title", "")
    name = extract(body, "Module name") or re.sub(r"^\[Module\]\s*", "", title).strip()
    url = extract(body, "Release ZIP URL")
    if not name or not url: fail("Module name or ZIP URL is missing")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._ -]{0,99}", name): fail("Invalid module name")
    p = urllib.parse.urlparse(url)
    if p.scheme != "https" or not p.netloc: fail("The release URL must be a public HTTPS URL")

    with tempfile.TemporaryDirectory() as td:
        path = os.path.join(td, "module.zip")
        try: download(url, path)
        except Exception as e: fail(f"Could not download the module archive: {e}")
        try:
            with zipfile.ZipFile(path) as z:
                bad = z.testzip()
                if bad: fail(f"Corrupt ZIP entry: {bad}")
                files = [i.filename for i in z.infolist() if not i.is_dir()]
                # Zip-slip check; files are inspected but never extracted by this workflow.
                for f in files:
                    pp = Path(f)
                    if pp.is_absolute() or ".." in pp.parts: fail("Archive contains an unsafe path")
                smods = [f for f in files if f.lower().endswith('.smod')]
                if not smods: fail("No .smod manifest found in the archive")
                readme = any(Path(f).name.lower() in {"readme.md","readme.txt"} for f in files)
                license_ = any(Path(f).name.lower() in {"license.md","license.txt"} for f in files)
                icon = any(Path(f).suffix.lower()=='.ico' for f in files)
        except zipfile.BadZipFile: fail("The submitted URL does not point to a readable ZIP archive")

    current = []
    if REGISTRY.exists():
        try: current = json.loads(REGISTRY.read_text(encoding="utf-8"))
        except Exception: fail("Registry JSON is invalid")
    if not isinstance(current, list): fail("Registry must be a JSON array")

    existing = next((m for m in current if str(m.get("name","")).lower()==name.lower()), None)
    if existing:
        if existing.get("url") == url: fail("This module release is already indexed")
        if not same_update_family(existing.get("url", ""), url):
            fail("Updates must keep the same host/path and ZIP base name, with a higher -vN suffix (for example MyModule-v2.zip)")
        existing["url"] = url
        action = "updated"
    else:
        if any(str(m.get("url","")).lower()==url.lower() for m in current): fail("This release URL is already indexed")
        current.append({"name": name, "url": url})
        current.sort(key=lambda x: str(x.get("name","")).lower())
        action = "added"

    REGISTRY.write_text(json.dumps(current, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    out = os.environ.get("GITHUB_OUTPUT")
    if out:
        with open(out,"a",encoding="utf-8") as f:
            f.write(f"result={action}\n")
            f.write(f"name={name}\n")
            f.write(f"readme={'yes' if readme else 'no'}\n")
            f.write(f"license={'yes' if license_ else 'no'}\n")
            f.write(f"icon={'yes' if icon else 'no'}\n")
            f.write(f"message=Module {action} successfully\n")
    print(f"Module {name} {action}; README={readme}, LICENSE={license_}, ICON={icon}")

if __name__ == "__main__": main()
