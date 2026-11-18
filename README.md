# Forever Handheld

<p>
  <a href="https://github.com/jarlbrak/forever-handheld/releases/latest"><img src="https://img.shields.io/github/v/release/jarlbrak/forever-handheld" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT license"></a>
  <a href="https://github.com/jarlbrak/forever-handheld/actions/workflows/ci.yml"><img src="https://github.com/jarlbrak/forever-handheld/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
</p>

**Forever Handheld** is a World of Warcraft: Forever addon that turns the default interface into a
controller-first handheld HUD. It is built for the **Steam Deck** (1280x800, played from the couch at
arm's length) and works on any machine where you play WoW Forever with a gamepad.

It is a visual companion to [ControllerForever](https://www.curseforge.com/wow/addons/controllerforever).
ControllerForever owns every button press, binding and secure action. Forever Handheld only changes
what you see: it mirrors ControllerForever's layers as a compact dock of native icons, and restyles
game windows so they are readable and navigable on a small screen with a controller.

## What it does

- **Controller dock.** A compact dock shows the face buttons and D-pad for the base, LT, RT and LT + RT
  layers, using the game's own spell icons, cooldowns and dynamic macro icons, updated live.
- **Contextual target HUD.** Target, quest and interaction context sits next to the dock instead of
  across the screen.
- **Readable windows.** Settings, keybinding, edit mode, professions, collections, calendar, chat
  settings, tutorials and supported addon windows get larger text and layouts that fit a handheld
  screen. Native windows keep their own layout, focus and actions; this addon only paints them.
- **Passive feeds.** A read-only conversation glance and an activity feed (rewards, world notices) sit
  beside the dock, so you can follow chat without opening it.
- **Guide and journey support.** Optional integrations for RXPGuides, Loreward, Questie, RareScanner and
  AutoGear: controller navigation for their buttons, route markers on the native map, readable rare
  loot and field notes.
- **Combat safe.** Nothing here moves protected frames or changes bindings in combat. Layout changes
  that the game would block are deferred until combat ends.

Chat commands for previews and diagnostics: `/fhpeek`, `/fhactivity`, `/fhnotes`, `/fhtimers`,
`/fhguides`, `/fhroster`.

## Requirements

- World of Warcraft: Forever (interface 16001 to 16100) with the Gamepad UI turned on.
- [ControllerForever](https://www.curseforge.com/wow/addons/controllerforever) 3.9.43 or newer
  (required dependency).
- Optional: RXPGuides, Loreward, Questie, RareScanner, AutoGear.

## Install

1. Install ControllerForever and enable the game's gamepad mode.
2. Download `ForeverHandheld-<version>.zip` from the
   [latest release](https://github.com/jarlbrak/forever-handheld/releases/latest).
3. Extract it so the folder sits at `_forever_/Interface/AddOns/ForeverHandheld/` inside your
   World of Warcraft folder.
   - **Steam Deck:** WoW Forever runs under Proton, so the game folder is inside the Proton prefix,
     typically `.../pfx/drive_c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/`.
     Desktop mode with Dolphin, or `scp` from another computer, both work.
4. Start the game, enable **Forever Handheld** and **ControllerForever** in the AddOns list, and log in.

To install from a clone instead, copy the `ForeverHandheld/` folder from this repository into
`AddOns/`, or use the deploy tool described in [docs/DEPLOY.md](docs/DEPLOY.md).

## Third-party patches

Some optional addons need small fixes to behave on a controller. They are kept as patch files against
a pinned upstream version in [`patches/`](patches/README.md), with a script that applies and reverts
them safely:

```bash
patches/apply.sh RXPGuides "/path/to/_forever_/Interface/AddOns/RXPGuides"
```

| Addon | Pinned version | Why |
| --- | --- | --- |
| RXPGuides | v4.11.36 | Its guide window becomes protected in combat when it carries a secure targeting button, so resizing or dragging it mid-fight raises "action blocked" errors. The patch defers that geometry until combat ends. |

The RXPGuides patch is licensed CC BY-NC-SA 4.0, like RXPGuides itself. See
[patches/README.md](patches/README.md) for details and for what is not published.

## Development

```bash
tests/run.sh                # 40 Lua regression tests, needs luajit or lua5.1
tests/patches/check.sh      # patches apply to the pinned upstream and pass their test
luacheck ForeverHandheld    # lint (config in .luacheckrc)
python3 tools/validate.py   # toc and file list, metadata, private-data scan
```

[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) explains how the modules fit together and the
presentation-only rules they follow. [CONTRIBUTING.md](CONTRIBUTING.md) covers pull requests.

## License

Forever Handheld is [MIT licensed](LICENSE). World of Warcraft and its assets belong to Blizzard
Entertainment; ControllerForever, RXPGuides and the other supported addons belong to their authors and
are not included.
