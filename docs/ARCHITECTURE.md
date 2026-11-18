# Architecture

Forever Handheld is a set of independent Lua modules loaded in the order listed in
`ForeverHandheld/ForeverHandheld.toc`. There is no library dependency and no XML: every module builds
its frames in Lua and talks to the game, ControllerForever and the optional addons through their public
globals and events.

## The contract

ControllerForever and the native UI own input. Forever Handheld only presents. Each module states its
own version of this contract in its header comment, and the rules are the same everywhere:

- **Never own input.** No bindings, no secure action attributes, no focus or selection changes on
  native widgets. Controller navigation for third-party buttons (for example Loreward) goes through the
  native gamepad focus APIs and the owner's own handlers.
- **Combat lockdown.** Anything that would touch a protected frame (size, anchor, visibility) checks
  `InCombatLockdown()` and defers to `PLAYER_REGEN_ENABLED`. Pure paint (font, color, alpha, textures on
  addon-owned frames) may happen any time.
- **Copy, do not rewrite.** When native text is too small, modules draw a presentation-only copy over or
  beside it and keep the original string, callbacks and values intact.
- **Secret values.** WoW Forever can hand back restricted ("secret") values. Reads go through helpers
  such as `safeNumber` that fall back instead of erroring.
- **Idle cost.** Drivers sleep when nothing they watch is visible; tests assert there are no idle
  `OnUpdate` calls where that matters.

## Modules (load order)

| File | Purpose |
| --- | --- |
| `Controls.lua` | Presentation and read-only diagnostics. Native secure bindings own all actions. |
| `CombatSample.lua` | Bounded, passive evidence from real combat. No input, names, chat or audio. No update handler exists while idle. At most two samples per group context are collected per login, for at most sixty ... |
| `FieldReader.lua` | Deliberate controller reading of the last Field Notes. Session memory only. |
| `Progress.lua` | Read-only progress display. Native faction selection and secure input stay native. |
| `ForeverHandheld.lua` | Visual-only companion to ControllerForever. Secure input and action resolution stay in the original addon; native icons and dynamic macros are mirrored live. |
| `ItemDetails.lua` | Complete native equipment details in the margins; no copied or shortened stats. Tooltip data, scripts, owners, comparison routing and controller bindings stay native. |
| `QuestReading.lua` | Read-first quest flow. Native gamepad dialogue owns Skip/Continue/Accept; never call protected quest actions or close its windows from addon code. |
| `FeedTiming.lua` | The two passive feeds wake for messages, Comms changes and visible fades. |
| `Comms.lua` | Native chat owns editing and sending; local controls only focus, route or clear drafts. No chat is sent by this addon. Clear only discards the current local draft. |
| `PassiveChat.lua` | A read-only conversation glance beside the dock footer. Native Comms owns history, focus, drafts and sending. Nothing here intercepts controller input. |
| `ActivityFeed.lua` | Read-only rewards and world notices, mirrored opposite passive conversation. |
| `Windows.lua` | Shared handheld window finish. Paint only: native windows own layout, focus, input, visibility, selection, and actions. No native scripts or state tables are replaced. Our noninteractive rim inherits ... |
| `Workbench.lua` | Professions workbench: native widgets, native navigation, new visual layout. No action handlers, focus ownership, protected state, or native methods replaced. |
| `ProfessionLabels.lua` | Presentation-only copies for protected profession overview labels. Native buttons, font regions, callbacks, focus, icons and hit areas are read-only. |
| `CraftingText.lua` | Readable recipe catalog and crafting controls. Native list geometry, selection, search, navigation and crafting callbacks continue to own input. |
| `Panels.lua` | Shared presentation for every registered game panel and supported addon window. Native frames retain their parents, scripts, navigation, and actions. |
| `Story.lua` | Preserve Loreward's native timers/queue while moving passive text out of the action area. A bounded journal keeps it available for deliberate reading. |
| `RouteMap.lua` | Journey stops use an addon-owned marker on the native map canvas. No user waypoint, supertracking or native map-provider state is changed. |
| `JourneyNotice.lua` | Surface responses from our Next chapter action without requiring chat. Observe only synchronous Loreward output; never replace its command, print, chat method, guide state, or native chapter-choice ... |
| `RareReader.lua` | Deliberate, controller-readable loot inspection. Observes native alerts; never targets units, changes filters, clicks loot, or writes RareScanner's database. |
| `JourneyControls.lua` | Controller navigation for Loreward-owned buttons. Gameplay bindings are loaned through ControllerForever's own window protocol, never the game's protected focus tables. Native button scripts and ... |
| `Environment.lua` | Paint the native breath/fatigue/death timers. Their original owner still controls timing, visibility, pause state, layout and edit-mode placement. |
| `MinimapVisibility.lua` | Native minimap blips can survive UIParent's cinematic alpha fade. Hide the unprotected map only while that fade is complete, then restore our own hide. No binding, focus, native script, pin, or ... |
| `ColorEditor.lua` | Addon-owned color editing avoids the native color picker's callback-driven binding footer, which taints the Forever client controller stack. Only Apply calls the original AceGUI value callback. ... |
| `AddonSettings.lua` | Readable AceGUI option pages inside the native Settings window. Widgets retain their values, callbacks, disabled state, tooltip and navigation. Styling is restored when AceGUI returns a widget to its ... |
| `NativeSettings.lua` | A wide, shorter workspace lets the native scrolling lists stay legible on an 800px handheld display. Native rows, binding listeners and focus own input. |
| `NativeMenus.lua` | Resize ordinary text during public menu initialization, before native layout. The native menu retains its responders, final initializer, focus and scrolling. |
| `ProfessionMenus.lua` | Fit displayed native menus while preserving descriptions, callbacks, fonts, anchors, selection and the secure controller binding stack. |
| `SettingsHelp.lua` | Readable native help in Settings, Professions and Collections. Preserve owner, content, anchors and input. |
| `ChatSettings.lua` | Presentation only for the native chat configuration window. Native tabs, checked values, color swatches, filters, callbacks and focus retain ownership. |
| `BindingSettings.lua` | Presentation for native click-casting. No bindings, actions, focus or listeners are replaced; the native spell/macro picker owns all interaction. |
| `RareAlerts.lua` | Keep RareScanner's secure button and native actions; only dress/position it. No polling, synthetic clicks, binding replacement or combat-time mutation. |
| `CollectionText.lua` | Readable collection and social controls; retain native models, text, focus and actions. |
| `SocialDialogs.lua` | Special native dialogs do not emit PopupOpened. Subscribe through the documented frame manager entry points; native navigation owns all buttons. |
| `KeybindWorkspace.lua` | Presentation only: the native editor owns all selection, assignment and keys. |
| `TutorialDetails.lua` | Read long tutorial explanations in unused chapter-column space. Native rows, settings, focus, bindings and geometry remain owned by CF. |
| `LayoutEditor.lua` | Presentation only: native editor owns selection, input, movement and persistence. |
| `NativeEditMode.lua` | Improve native editor typography without touching secure layout state. The game still owns every checkbox, row order, focus target and callback. |
| `RadialHints.lua` | Teach the native stick gesture in the otherwise empty radial hub. No input interception, native state changes, or idle work. |
| `CalendarStyle.lua` | Tone the native paper grid without changing dates, navigation, event art, selection highlights or the calendar's month and event scripts. |
| `QuickKeybindControls.lua` | Quick Keybind receives raw gamepad input before normal key bindings. Offer its native Cancel action while no action button is listening. |

`CommunityQR.tga` is a QR code for the Loreward community invite, shown inside Loreward's own
community box when that box displays the matching link.

## Tests

`tests/run.sh` runs each `tests/test-<name>.lua` with a plain Lua 5.1 or LuaJIT interpreter. A test:

1. stubs the WoW API it needs (`CreateFrame`, `InCombatLockdown`, fonts, native frames) as small Lua
   tables that record calls;
2. loads the module under test from the path in `arg[1]` (some tests take extra module paths, and
   `test-hud.lua` is run again with a startup mode in `arg[2]`);
3. drives events and `OnUpdate` ticks, asserts on what the module painted, and prints `PASS: ...`
   lines.

The runner maps `test-foo-bar.lua` to `FooBar.lua` automatically; the exceptions (`hud`,
`calendar-controls`, extra modules and modes) are listed at the top of `tests/run.sh`.

Tests for third-party patches live in `tests/patches/` and run against the patched upstream file via
`tests/patches/check.sh`.
