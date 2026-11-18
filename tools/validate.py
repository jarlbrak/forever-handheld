#!/usr/bin/env python3
"""Static checks for the ForeverHandheld addon folder.

Checks that the .toc lists exactly the Lua files that ship, that every listed file exists,
that the metadata fields the project relies on are present, and that no private or
machine-specific values slipped into the addon. Exit status is non-zero on any failure.

    python3 tools/validate.py              # validate ForeverHandheld/
    python3 tools/validate.py --manifest   # also print a sha256 manifest (JSON) to stdout
"""
import argparse
import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ADDON = ROOT / "ForeverHandheld"
TOC = ADDON / "ForeverHandheld.toc"
REQUIRED = ["Interface", "Title", "Version", "Author", "X-License", "X-Website", "Dependencies"]
# Patterns that must never ship in the addon: absolute home paths, Tailscale/CGNAT
# addresses, ssh targets and e-mail addresses.
PRIVATE = [
    (re.compile(r"/(Users|home)/[A-Za-z0-9_.-]+"), "absolute home path"),
    (re.compile(r"\b100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.\d{1,3}\.\d{1,3}\b"), "Tailscale/CGNAT address"),
    (re.compile(r"\b[a-z0-9_-]+@[a-z0-9-]+(\.[a-z0-9-]+)+\b", re.I), "e-mail address or ssh target"),
    (re.compile(r"\.ts\.net\b"), "Tailscale hostname"),
]


def parse_toc():
    fields, files = {}, []
    for line in TOC.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("## "):
            key, _, value = line[3:].partition(":")
            fields[key.strip()] = value.strip()
        elif line and not line.startswith("#"):
            files.append(line.replace("\\", "/"))
    return fields, files


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--manifest", action="store_true", help="print a sha256 manifest of the addon")
    args = ap.parse_args()
    errors = []
    fields, files = parse_toc()
    for key in REQUIRED:
        if not fields.get(key):
            errors.append(f"toc: missing ## {key}")
    if not re.fullmatch(r"\d+\.\d+\.\d+", fields.get("Version", "")):
        errors.append(f"toc: Version '{fields.get('Version')}' is not MAJOR.MINOR.PATCH")
    shipped = {p.name for p in ADDON.glob("*.lua")}
    listed = set(files)
    for name in sorted(listed - {p.name for p in ADDON.iterdir()}):
        errors.append(f"toc lists {name}, which does not exist")
    for name in sorted(shipped - listed):
        errors.append(f"{name} is not listed in the toc (it would never load)")
    if len(files) != len(listed):
        errors.append("toc lists a file more than once")
    for path in sorted(ADDON.iterdir()):
        if path.suffix not in (".lua", ".toc", ".xml"):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for pattern, label in PRIVATE:
            for m in pattern.finditer(text):
                if label.startswith("e-mail") and "discord" in m.group(0):
                    continue
                line = text.count("\n", 0, m.start()) + 1
                errors.append(f"{path.name}:{line}: looks like a {label}: {m.group(0)!r}")
    if args.manifest:
        manifest = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(ADDON.iterdir()) if p.is_file()}
        json.dump({"version": fields.get("Version"), "files": manifest}, sys.stdout, indent=2)
        print()
    for e in errors:
        print("error:", e, file=sys.stderr)
    if not errors:
        print(f"ok: ForeverHandheld {fields['Version']}, {len(files)} Lua files listed and present", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
