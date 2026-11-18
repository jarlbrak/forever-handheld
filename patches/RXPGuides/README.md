# RXPGuides patch

Target: [RXPGuides](https://github.com/RestedXP/RXPGuides) **v4.11.36**, file `GuideWindow.lua`.

## Why

RXPGuides can put a secure targeting button inside its legacy guide window. Once a secure child is
present, the game treats the guide window and its current-step frame as protected while you are in
combat. RXPGuides still resizes, shows, hides and re-anchors those frames whenever the guide advances
or you drag the window, so on a controller, where steps advance mid-fight constantly, combat fills up
with "Interface action failed because of an AddOn" errors and the window can end up the wrong size.

`0001-defer-guide-window-geometry-in-combat.patch` changes three things, and nothing else:

1. **Guide window size.** `updateGuideWindowSize` coalesces any size or visibility change requested in
   combat and applies the latest guide state once on `PLAYER_REGEN_ENABLED`.
2. **Current step frame.** `applyStepGeometry` defers height and visibility changes the same way, while
   the step text keeps updating live.
3. **Mouse drag and resize.** Drags cannot start in combat or while frames are locked, only the release
   of the button that started a drag finishes it, and a drag that was interrupted by combat is finalized
   (position saved, step re-anchored) once combat ends.

Guide logic, step completion and saved data are untouched. The regression test is
[`tests/patches/test-rxp-guidewindow.lua`](../../tests/patches/test-rxp-guidewindow.lua); CI applies the
patch to the pinned upstream file and runs it.

## License

RXPGuides is licensed under the
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/)
by RestedXP. The patch in this folder is an adaptation of RXPGuides and is shared under the same
license (CC BY-NC-SA 4.0), not under the MIT license that covers the rest of this repository. Changes
from upstream are exactly those shown in the patch file. See [LICENSE.md](LICENSE.md).
