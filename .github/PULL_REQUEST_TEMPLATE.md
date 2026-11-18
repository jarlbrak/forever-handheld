## What this changes

<!-- One or two sentences. For each fully resolved issue, include "Fixes #123" or
"Closes #123" in the PR body outside this comment. Use "Refs #123" for partial work. -->

## Checklist

- [ ] Every fully resolved issue has a closing keyword in this PR body; partial work uses `Refs` (or no issue applies).
- [ ] `tests/run.sh` passes, and new behavior has a test in `tests/`.
- [ ] `luacheck ForeverHandheld` and `python3 tools/validate.py` are clean.
- [ ] New Lua files are listed in `ForeverHandheld/ForeverHandheld.toc`.
- [ ] No secure input, bindings or protected frames are touched in combat (presentation only).
- [ ] `## Version` in the toc and `CHANGELOG.md` are updated if this ships to players.
- [ ] No private values: hostnames, IPs, home paths, account, BattleTag, realm or character names.
- [ ] No em dashes anywhere in the diff.

## In-game check

<!-- Device (Steam Deck, PC), what you tried, and a screenshot if the HUD changed.
Note anything you could not verify in game. -->
