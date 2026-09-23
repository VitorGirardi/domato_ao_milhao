#!/usr/bin/env bash
# Exercise the release through a real window manager and its normal close event.
set -euo pipefail
openbox >test-results/linux/release-openbox.log 2>&1 &
wm_pid=$!
exports/linux/DoMatoAoMilhao.x86_64 --audio-driver Dummy >test-results/linux/export-smoke.log 2>&1 &
game_pid=$!
trap 'kill "$game_pid" "$wm_pid" 2>/dev/null || true' EXIT
window_id=""
for attempt in $(seq 1 120); do
  kill -0 "$game_pid" "$wm_pid"
  # Openbox can be alive before it publishes _NET_CLIENT_LIST. Keep polling
  # within the same deadline; an exited game/WM still fails immediately.
  if window_id=$(wmctrl -lp 2>>test-results/linux/release-openbox.log | awk -v pid="$game_pid" '$3 == pid {print $1; exit}'); then
    [ -n "$window_id" ] && break
  fi
  sleep .5
done
[ -n "$window_id" ]
# Give the software renderer time to compile and draw the actual title screen.
sleep 20
kill -0 "$game_pid"
import -window root test-results/linux/export-title.png
wmctrl -ic "$window_id"
wait "$game_pid"
if grep -E 'SCRIPT ERROR|ERROR:' test-results/linux/export-smoke.log; then exit 1; fi
echo LINUX_EXPORTED_GUI_OK | tee -a test-results/linux/export-smoke.log
