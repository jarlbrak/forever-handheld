# Third-party patches

Forever Handheld itself never modifies another addon's files. A few optional addons need small fixes
to behave well on a controller, mostly around combat lockdown. Those fixes live here as unified diffs
against one pinned upstream version per addon, so you can read exactly what changes before you apply
anything.

| Folder | Upstream | Pinned | License of the patch |
| --- | --- | --- | --- |
| [`RXPGuides/`](RXPGuides/README.md) | [RestedXP/RXPGuides](https://github.com/RestedXP/RXPGuides) | v4.11.36 | CC BY-NC-SA 4.0 |

## Applying

```bash
patches/apply.sh --check  RXPGuides "/path/to/_forever_/Interface/AddOns/RXPGuides"   # dry run
patches/apply.sh          RXPGuides "/path/to/_forever_/Interface/AddOns/RXPGuides"
patches/apply.sh --revert RXPGuides "/path/to/_forever_/Interface/AddOns/RXPGuides"
```

The script:

- refuses to run if the installed addon's `## Version` differs from `UPSTREAM`;
- checks every patch applies cleanly before changing anything;
- handles the CRLF line endings that addon zips ship with;
- keeps the original of each changed file in `<addon>/.forever-handheld-backup/`.

Updating the addon through CurseForge or another client overwrites the patched files. Re-run the
script after updating (it will tell you if the new version needs a refreshed patch).

## Not published: ControllerForever

The author also keeps small local fixes to six ControllerForever 3.9.43 files (bag and combat
inventory windows, the menu, the rule bar and trigger taps). ControllerForever is distributed without
a license that grants permission to share modified copies, so those patches are not included here,
not even as diffs. They are fixes to ControllerForever's own windows; Forever Handheld does not
reference the patched code.
If the ControllerForever authors grant permission or publish under an open license, they can be added
under `patches/ControllerForever/`.

## Adding or refreshing a patch

1. Start from a clean copy of the upstream file at the pinned tag (LF line endings).
2. Make the change, then write the diff with paths `a/<Addon>/<file>` and `b/<Addon>/<file>`:
   `diff -u --label a/RXPGuides/GuideWindow.lua --label b/RXPGuides/GuideWindow.lua old new`.
3. Record the version and the upstream file's sha256 in `<Addon>/UPSTREAM`.
4. Add a regression test under `tests/patches/` and wire it into `tests/patches/check.sh`.
5. Explain the why in `<Addon>/README.md`, and include the upstream license notice.
