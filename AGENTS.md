# Forever Handheld: agent instructions

This is the canonical public instruction file for coding agents and automation in this repository.
Harness-specific files (such as `CLAUDE.md`) point here.

## Project

Forever Handheld is a World of Warcraft: Forever addon (Lua 5.1, interface 16001 to 16100) that
restyles the default UI into a controller-first handheld HUD for the Steam Deck. It is a visual
companion to ControllerForever, which owns all secure input.

- `ForeverHandheld/`: the addon. Load order is the file list in `ForeverHandheld.toc`.
- `tests/`: plain-Lua regression tests with stubbed WoW APIs; `tests/run.sh` runs them.
- `patches/`: diffs against pinned third-party addon versions, applied by `patches/apply.sh`.
- `tools/`: `validate.py` (static checks) and `deploy.py` (install to a Deck or local folder).
- `docs/`: architecture and deploy notes.

## Rules

- Presentation only. Never take over input, change bindings, or touch protected frames in combat.
  Defer with `PLAYER_REGEN_ENABLED`. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- Inspect `git status --short --branch` before editing. Preserve unrelated changes.
- Prefer the smallest faithful change. No drive-by cleanup or reformatting.
- Every behavior change gets a test in `tests/`. Run `tests/run.sh`, `luacheck ForeverHandheld`
  and `python3 tools/validate.py` before committing.
- New Lua files must be listed in the toc. Bump `## Version` and `CHANGELOG.md` for player-facing
  changes.
- Never commit private values: hostnames, IP addresses (including Tailscale), absolute home paths,
  e-mail addresses, WoW account folder names, BattleTags, realm or character names, SavedVariables,
  logs or screenshots with names. Machine-specific values go in ignored `tools/deploy.env` or
  `AGENTS.local.md`.
- Do not commit third-party addon source. Patches for an addon are only published when its license
  allows sharing modified copies.
- No em dashes in files, comments, commit messages or PR bodies.
