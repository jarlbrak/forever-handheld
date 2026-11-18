# Contributing to Forever Handheld

Thanks for your interest. Bug reports from real handheld play are the most useful thing you can send.

## Reporting bugs

Use the [bug report form](https://github.com/jarlbrak/forever-handheld/issues/new/choose). Include the
full Lua error or "action blocked" message, your device, and the versions of Forever Handheld,
ControllerForever and any supported addon. Leave out account names, BattleTags, realms and character
names, and crop them out of screenshots.

If a button does the wrong thing, check whether it happens with Forever Handheld disabled. Input and
bindings belong to ControllerForever; report those on its
[CurseForge page](https://www.curseforge.com/wow/addons/controllerforever).

## The presentation-only rule

Forever Handheld never owns input. Every module follows the same contract, stated at the top of each
file:

- Native frames and ControllerForever own selection, focus, bindings, secure actions and persistence.
- This addon reads state and paints: fonts, sizes, anchors of its own frames, textures, copies of text.
- Nothing touches protected frames or bindings while `InCombatLockdown()` is true. Defer instead.
- Reading game values must survive restricted or secret values (see `issecretvalue` checks).

A change that needs to take over input belongs in ControllerForever, not here.

## Making a change

1. Open or comment on an issue first for anything larger than a small fix.
2. Keep each change the smallest faithful slice. No drive-by reformatting.
3. Add or update a test in `tests/` that loads the module with stubbed WoW APIs. See
   `tests/test-story.lua` for a small example and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the
   test harness conventions.
4. List new files in `ForeverHandheld/ForeverHandheld.toc` in load order.
5. Run the checks:

   ```bash
   tests/run.sh
   tests/patches/check.sh
   luacheck ForeverHandheld
   python3 tools/validate.py
   ```

6. Test in game when the change is visible. Say in the PR what you could not verify.

### Third-party patches

Patch files in `patches/<Addon>/` are unified diffs against the version pinned in `UPSTREAM`. To update
one for a new upstream release, apply the old patch to the new version, resolve conflicts, regenerate
the diff from a clean upstream copy, update `UPSTREAM` (version and hash), and make
`tests/patches/check.sh` pass. Only publish patches for addons whose license allows modified copies to
be shared; see [patches/README.md](patches/README.md).

## Pull requests

- Include `Fixes #<number>` or `Closes #<number>` for each fully resolved issue, `Refs #<number>` for
  partial work.
- CI must pass: tests on Lua 5.1 and LuaJIT, luacheck, `tools/validate.py`, shellcheck and the secret
  scan.
- Update `CHANGELOG.md` and the toc `## Version` when the change ships to players.
- No em dashes in any file, comment, commit message, or PR body. Use commas, colons, semicolons,
  periods, or parentheses.

The pull-request template walks through this checklist.

## Releases

Releases are cut by pushing a `v<version>` tag that matches the toc version. The release workflow runs
the tests and builds the zip with the [BigWigs packager](https://github.com/BigWigsMods/packager),
using the matching `CHANGELOG.md` section as release notes.

## AI-assisted contributions

[`AGENTS.md`](AGENTS.md) is the instruction file for coding agents. It works from a clean clone without
private tools. Machine-specific setup (deploy host, paths) belongs in ignored files such as
`tools/deploy.env` and `AGENTS.local.md`, never in committed files.

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By taking part, you agree to
uphold it.
