#!/usr/bin/env bash
set -Eeuo pipefail

runtime_directory="/tmp/monogame-runtime-$(id -u)"
cache_directory="${XDG_CACHE_HOME:-/tmp/monogame-cache}"
mkdir -p "${runtime_directory}" "${cache_directory}"
chmod 700 "${runtime_directory}"
export XDG_RUNTIME_DIR="${runtime_directory}"

background_pids=()

cleanup() {
    local process_id
    for process_id in "${background_pids[@]:-}"; do
        kill "${process_id}" 2>/dev/null || true
    done
}
trap cleanup EXIT INT TERM

Xvfb "${DISPLAY}" -screen 0 1280x720x24 -nolisten tcp \
    >/tmp/monogame-xvfb.log 2>&1 &
background_pids+=("$!")

for _ in $(seq 1 50); do
    if xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

if ! xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
    echo "The virtual X display did not start." >&2
    exit 1
fi

openbox-session >/tmp/monogame-openbox.log 2>&1 &
background_pids+=("$!")

x11vnc \
    -display "${DISPLAY}" \
    -forever \
    -shared \
    -nopw \
    -rfbport 5900 \
    -quiet \
    >/tmp/monogame-x11vnc.log 2>&1 &
background_pids+=("$!")

websockify \
    --web=/usr/share/novnc \
    6080 \
    localhost:5900 &
background_pids+=("$!")

echo "MonoGame display: http://localhost:${NOVNC_PORT:-6080}/vnc.html?autoconnect=1&resize=scale"

if [ "$#" -eq 0 ]; then
    set -- dotnet run --project src/ElectricTruckOutRun.Game/ElectricTruckOutRun.Game.csproj
fi

"$@"
