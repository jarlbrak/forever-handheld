#!/usr/bin/env bash
# Downloads each pinned upstream file, checks its hash, applies the patch set with
# patches/apply.sh and runs the matching regression test against the result.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
LUA=${LUA:-$(command -v luajit || command -v lua5.1 || command -v lua)}
work=$(mktemp -d)

# RXPGuides
up="$root/patches/RXPGuides/UPSTREAM"
version=$(sed -n 's/^version=//p' "$up")
want=$(sed -n 's/^GuideWindow.lua=//p' "$up")
dir="$work/RXPGuides"; mkdir -p "$dir"
curl -fsSL "https://raw.githubusercontent.com/RestedXP/RXPGuides/$version/GuideWindow.lua" -o "$dir/GuideWindow.lua"
have=$( (sha256sum "$dir/GuideWindow.lua" 2>/dev/null || shasum -a 256 "$dir/GuideWindow.lua") | cut -d' ' -f1)
[ "$have" = "$want" ] || { echo "Upstream GuideWindow.lua $version hash changed: $have" >&2; exit 1; }
# Release zips ship CRLF; exercise that path too.
perl -pi -e 's/\n/\r\n/' "$dir/GuideWindow.lua"
printf '## Title: RXPGuides\r\n## Version: %s\r\n' "$version" > "$dir/RXPGuides.toc"
"$root/patches/apply.sh" RXPGuides "$dir"
"$LUA" "$root/tests/patches/test-rxp-guidewindow.lua" "$dir/GuideWindow.lua"
"$root/patches/apply.sh" --revert RXPGuides "$dir" > /dev/null
echo "RXPGuides patches: ok"
