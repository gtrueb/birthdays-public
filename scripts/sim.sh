#!/bin/zsh
# sim.sh boot            -> boots (creates if needed) the test iPhone and prints its UDID
# sim.sh install         -> installs the built app
# sim.sh launch [args]   -> launches the app with launch arguments
# sim.sh app <bundleid>  -> launches another app (e.g. com.apple.reminders)
# sim.sh shot <path.png> -> saves a screenshot
# sim.sh reset           -> erases the device (all data)
set -e
NAME="Gauntlet iPhone"
DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro"
cd "$(dirname "$0")/.."
udid() { xcrun simctl list devices -j | python3 -c "import json,sys; d=json.load(sys.stdin)['devices']; print(next((x['udid'] for v in d.values() for x in v if x['name']=='$NAME'),''))"; }
case "$1" in
  boot)
    U=$(udid)
    if [ -z "$U" ]; then
      RT=$(xcrun simctl list runtimes -j | python3 -c "import json,sys; r=[x for x in json.load(sys.stdin)['runtimes'] if x['platform']=='iOS' and x['isAvailable']]; print(r[-1]['identifier'])")
      U=$(xcrun simctl create "$NAME" "$DEVTYPE" "$RT")
    fi
    xcrun simctl bootstatus "$U" -b >/dev/null 2>&1 || true
    open -a Simulator --args -CurrentDeviceUDID "$U" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$U" >/dev/null
    echo "$U" ;;
  install) xcrun simctl install "$(udid)" build/Build/Products/Debug-iphonesimulator/Birthdays.app ;;
  launch) shift; xcrun simctl terminate "$(udid)" com.giantrub.Birthdays 2>/dev/null || true; xcrun simctl launch "$(udid)" com.giantrub.Birthdays "$@" ;;
  app) shift; xcrun simctl launch "$(udid)" "$1" >/dev/null ;;
  terminate) shift; xcrun simctl terminate "$(udid)" "$1" 2>/dev/null || true ;;
  shot) shift; mkdir -p "$(dirname "$1")"; xcrun simctl io "$(udid)" screenshot "$1" >/dev/null 2>&1; echo "$1" ;;
  reset) xcrun simctl shutdown "$(udid)" 2>/dev/null || true; xcrun simctl erase "$(udid)" ;;
  udid) udid ;;
  *) echo "unknown command"; exit 1 ;;
esac
