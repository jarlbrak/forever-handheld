#!/usr/bin/env python3
"""Install ForeverHandheld on a Steam Deck (over ssh) or into a local AddOns folder.

Before copying it runs tools/validate.py and tests/run.sh, backs up the addon that is
currently installed, then verifies every copied file by sha256.

Configuration comes from environment variables or from tools/deploy.env (gitignored;
copy tools/deploy.env.example to start):

    FH_DEPLOY_HOST    ssh destination, e.g. deck@steamdeck (omit for a local install)
    FH_DEPLOY_ADDONS  the game's Interface/AddOns directory on that machine

Examples:
    python3 tools/deploy.py                 # deploy using deploy.env / environment
    python3 tools/deploy.py --dry-run       # show what would happen
    python3 tools/deploy.py --verify        # only compare the installed copy with this checkout
    FH_DEPLOY_HOST= FH_DEPLOY_ADDONS=~/wow/_forever_/Interface/AddOns python3 tools/deploy.py
"""
import argparse
import hashlib
import os
import pathlib
import shlex
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
ADDON = ROOT / "ForeverHandheld"
NAME = "ForeverHandheld"


def load_config():
    env_file = ROOT / "tools" / "deploy.env"
    values = {}
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, _, value = line.partition("=")
                values[key.strip()] = value.strip().strip('"').strip("'")
    host = os.environ.get("FH_DEPLOY_HOST", values.get("FH_DEPLOY_HOST", ""))
    addons = os.environ.get("FH_DEPLOY_ADDONS", values.get("FH_DEPLOY_ADDONS", ""))
    if not addons:
        sys.exit("FH_DEPLOY_ADDONS is not set (see tools/deploy.env.example)")
    return host, addons


def version():
    for line in (ADDON / f"{NAME}.toc").read_text().splitlines():
        if line.startswith("## Version:"):
            return line.split(":", 1)[1].strip()
    return "unknown"


def manifest():
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(ADDON.iterdir()) if p.is_file()}


class Target:
    def __init__(self, host, addons, dry_run):
        self.host, self.dry_run = host, dry_run
        self.addons = addons if host else os.path.expanduser(addons)
        self.live = self.addons.rstrip("/") + "/" + NAME

    def sh(self, script, capture=False):
        argv = ["ssh", self.host, script] if self.host else ["sh", "-c", script]
        if self.dry_run and not capture:
            print("would run:", " ".join(shlex.quote(a) for a in argv))
            return ""
        return subprocess.run(argv, check=True, text=True, capture_output=capture).stdout

    def copy(self, files):
        if self.host:
            argv = ["scp", "-q", *map(str, files), f"{self.host}:{shlex.quote(self.live)}/"]
        else:
            argv = ["cp", *map(str, files), self.live + "/"]
        if self.dry_run:
            print("would run:", " ".join(shlex.quote(a) for a in argv[:3]), "...", argv[-1])
        else:
            subprocess.run(argv, check=True)

    def remote_hashes(self):
        q = shlex.quote(self.live)
        out = self.sh(f"cd {q} 2>/dev/null && for f in *; do [ -f \"$f\" ] && (sha256sum \"$f\" 2>/dev/null || shasum -a 256 \"$f\"); done; true", capture=True)
        hashes = {}
        for line in out.splitlines():
            digest, _, name = line.partition(" ")
            hashes[name.strip().lstrip("*")] = digest
        return hashes


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dry-run", action="store_true", help="print the commands without changing anything")
    ap.add_argument("--verify", action="store_true", help="only compare the installed copy with this checkout")
    ap.add_argument("--skip-tests", action="store_true", help="do not run tests/run.sh first")
    ap.add_argument("--prune", action="store_true", help="move installed files that are no longer shipped into the backup")
    args = ap.parse_args()

    host, addons = load_config()
    target = Target(host, addons, args.dry_run)
    local = manifest()
    where = f"{host}:{target.live}" if host else target.live

    if not args.verify:
        subprocess.run([sys.executable, str(ROOT / "tools" / "validate.py")], check=True)
        if not args.skip_tests:
            subprocess.run([str(ROOT / "tests" / "run.sh")], check=True, stdout=subprocess.DEVNULL)
            print("tests passed")
        before = target.remote_hashes()
        stamp = time.strftime("%Y%m%d-%H%M%S")
        backup = target.addons.rstrip("/") + f"/../{NAME}-backups/{stamp}"
        q, qb = shlex.quote(target.live), shlex.quote(backup)
        if before:
            target.sh(f"mkdir -p {qb} && cp -p {q}/* {qb}/")
            print(f"backed up the installed copy to {backup}")
        target.sh(f"mkdir -p {q}")
        changed = [ADDON / n for n, d in local.items() if before.get(n) != d]
        if changed:
            target.copy(changed)
        stale = sorted(set(before) - set(local))
        if stale and args.prune:
            target.sh(f"mkdir -p {qb} && cd {q} && mv " + " ".join(shlex.quote(s) for s in stale) + f" {qb}/")
        elif stale:
            print("installed files not in this checkout (use --prune to move them aside):", ", ".join(stale))
        print(f"{'would copy' if args.dry_run else 'copied'} {len(changed)} changed file(s) of {len(local)} to {where}")
        if args.dry_run:
            return 0

    remote = target.remote_hashes()
    bad = sorted(n for n, d in local.items() if remote.get(n) != d)
    if bad:
        print(f"MISMATCH at {where}: {', '.join(bad)}", file=sys.stderr)
        return 1
    print(f"verified: {where} matches ForeverHandheld {version()} ({len(local)} files). /reload in game to load it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
