#!/usr/bin/env bash
# Runs every Lua regression test in tests/ against the addon in ForeverHandheld/.
# Usage: tests/run.sh            (uses $LUA, else luajit, else lua5.1, else lua)
#        tests/run.sh hud comms  (run only the named tests)
set -u
here=$(cd "$(dirname "$0")" && pwd)
addon="$here/../ForeverHandheld"
LUA=${LUA:-$(command -v luajit || command -v lua5.1 || command -v lua)}
[ -n "$LUA" ] || { echo "No Lua interpreter found (set LUA=...)" >&2; exit 2; }

# test name -> module file (when it is not the CamelCase form of the test name)
module_for() {
  case "$1" in
    hud) echo ForeverHandheld.lua ;;
    calendar-controls) echo CalendarStyle.lua ;;
    *) echo "$1" | awk -F- '{for(i=1;i<=NF;i++) printf "%s%s", toupper(substr($i,1,1)), substr($i,2); print ".lua"}' ;;
  esac
}
# test name -> extra modes to run in addition to the default run
modes_for() {
  case "$1" in
    hud) echo "startup_failure startup_failure_late startup_combat" ;;
  esac
}
# test name -> extra module arguments
extra_for() {
  case "$1" in
    activity-feed|passive-chat) echo "$addon/FeedTiming.lua" ;;
  esac
}
# The module filename is case-sensitive on Linux; resolve it case-insensitively.
resolve() {
  local want; want=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  for f in "$addon"/*.lua; do
    [ "$(basename "$f" | tr '[:upper:]' '[:lower:]')" = "$want" ] && { echo "$f"; return; }
  done
}

if [ $# -gt 0 ]; then names=("$@"); else
  names=(); for t in "$here"/test-*.lua; do n=$(basename "$t" .lua); names+=("${n#test-}"); done
fi

pass=0; fail=0; failed=()
for name in "${names[@]}"; do
  test="$here/test-$name.lua"
  module=$(resolve "$(module_for "$name")")
  if [ -z "$module" ]; then echo "FAIL $name: no module for this test"; fail=$((fail+1)); failed+=("$name"); continue; fi
  for mode in "" $(modes_for "$name"); do
    label="$name${mode:+ ($mode)}"
    args=("$module"); extra=$(extra_for "$name")
    [ -n "$extra" ] && args+=("$extra")
    [ -n "$mode" ] && args+=("$mode")
    if out=$(cd "$here" && "$LUA" "$test" "${args[@]}" 2>&1); then
      pass=$((pass+1)); echo "ok   $label"
    else
      fail=$((fail+1)); failed+=("$label"); echo "FAIL $label"; printf '     %s\n' "${out//$'\n'/$'\n'     }"
    fi
  done
done
echo; [ $fail -gt 0 ] && printf 'failed: %s\n' "${failed[@]}"
echo "$pass passed, $fail failed ($("$LUA" -v 2>&1 | head -1))"
[ $fail -eq 0 ]
