# Deploying to a Steam Deck

`tools/deploy.py` installs the addon from this checkout onto a Steam Deck over ssh, or into an AddOns
folder on the same machine. It validates and tests the addon first, backs up the installed copy, copies
only changed files, and verifies every file by sha256 afterwards.

## One-time setup

1. On the Deck, in desktop mode, set a password for the `deck` user (`passwd`) and enable sshd:
   `sudo systemctl enable --now sshd`.
2. Make the Deck reachable from your computer, by LAN hostname or through a VPN such as Tailscale,
   and install your ssh key: `ssh-copy-id deck@<deck-host>`.
3. Find the game's AddOns folder on the Deck. For a Proton install it is inside the Wine prefix:
   `<prefix>/drive_c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns`.
4. Copy `tools/deploy.env.example` to `tools/deploy.env` (gitignored) and fill in `FH_DEPLOY_HOST` and
   `FH_DEPLOY_ADDONS`. Environment variables with the same names override the file.

## Deploying

```bash
python3 tools/deploy.py --dry-run   # show what would change
python3 tools/deploy.py             # validate, test, back up, copy, verify
python3 tools/deploy.py --verify    # just compare what is installed with this checkout
```

Then `/reload` in game. Backups go to `Interface/ForeverHandheld-backups/<timestamp>/`, next to
`AddOns/` so the game never loads them. Use `--prune` to move installed files that the checkout no
longer ships into that backup.

For a local install, leave `FH_DEPLOY_HOST` empty and point `FH_DEPLOY_ADDONS` at a local folder.

## Applying patches on the Deck

`patches/apply.sh` runs on the Deck too (it needs only bash, perl and patch). Copy the `patches/`
folder over, or run it from a clone on the Deck:

```bash
patches/apply.sh RXPGuides "<AddOns>/RXPGuides"
```
