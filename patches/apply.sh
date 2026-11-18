#!/usr/bin/env bash
# Apply the ForeverHandheld compatibility patches to an installed third-party addon.
#
#   patches/apply.sh RXPGuides "/path/to/World of Warcraft/_forever_/Interface/AddOns/RXPGuides"
#   patches/apply.sh --check RXPGuides <dir>     # dry run only
#   patches/apply.sh --revert RXPGuides <dir>    # undo
#
# The script refuses to touch an addon whose version does not match patches/<Addon>/UPSTREAM,
# and keeps a copy of every file it changes under <dir>/.forever-handheld-backup/.
set -euo pipefail
mode=apply
case "${1:-}" in --check) mode=check; shift ;; --revert) mode=revert; shift ;; esac
[ $# -eq 2 ] || { sed -n '2,9p' "$0" >&2; exit 2; }
name=$1; target=${2%/}
here=$(cd "$(dirname "$0")" && pwd)
dir="$here/$name"
[ -f "$dir/UPSTREAM" ] || { echo "Unknown patch set: $name (expected $dir/UPSTREAM)" >&2; exit 2; }
want=$(sed -n 's/^version=//p' "$dir/UPSTREAM")
toc=$(find "$target" -maxdepth 1 -name '*.toc' | head -1)
[ -n "$toc" ] || { echo "No .toc found in $target" >&2; exit 1; }
have=$(tr -d '\r' < "$toc" | sed -n 's/^## Version: *//p' | head -1)
if [ "$have" != "$want" ] && [ "v$have" != "$want" ] && [ "$have" != "v$want" ]; then
  echo "$name is version '$have' but these patches target '$want'. Not touching it." >&2
  echo "Update the patches (see patches/README.md) or install $name $want." >&2
  exit 1
fi
# WoW addon zips ship CRLF; the patches are LF. Patch an LF copy, then write it back.
work=$(mktemp -d)  # left for the OS temp cleaner
mkdir -p "$work/$name"
cp -R "$target"/. "$work/$name/"
find "$work/$name" -name '*.lua' -exec perl -pi -e 's/\r\n/\n/' {} +
flags=(-p1 -d "$work" --forward --no-backup-if-mismatch)
[ $mode = revert ] && flags=(-p1 -d "$work" --reverse --no-backup-if-mismatch)
for p in "$dir"/*.patch; do
  echo "== $(basename "$p")"
  patch "${flags[@]}" --dry-run --silent < "$p" || { echo "Does not apply cleanly; nothing changed." >&2; exit 1; }
done
[ $mode = check ] && { echo "All patches apply cleanly to $target"; exit 0; }
for p in "$dir"/*.patch; do patch "${flags[@]}" --silent < "$p"; done
backup="$target/.forever-handheld-backup"
mkdir -p "$backup"
sed -n "s|^+++ b/$name/||p" "$dir"/*.patch | cut -f1 | sort -u | while IFS= read -r f; do
  [ -f "$backup/$f" ] || { mkdir -p "$backup/$(dirname "$f")"; cp "$target/$f" "$backup/$f"; }
  cp "$work/$name/$f" "$target/$f"
  echo "${mode}: $f"
done
echo "Done. Originals are in $backup"
