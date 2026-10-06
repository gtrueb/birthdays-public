#!/bin/zsh
# Builds a signed Release build and installs it on the connected iPhone.
# First run may ask to allow codesign to use your key -> click "Always Allow".
set -e
cd "$(dirname "$0")/.."

find_iphone() {
  xcrun devicectl list devices --json-output /tmp/birthdays-devices.json >/dev/null 2>&1 || return 1
  python3 - <<'PY'
import json
try:
    devices = json.load(open("/tmp/birthdays-devices.json"))["result"]["devices"]
except Exception:
    devices = []
# Only iPhones, and only ones the Mac can actually talk to right now.
phones = [d for d in devices
          if "iPhone" in d["deviceProperties"].get("name", "") + d["hardwareProperties"].get("deviceType", "")
          and d["connectionProperties"].get("tunnelState") == "connected"]
print(phones[0]["identifier"] if phones else "")
PY
}

echo "Looking for your iPhone…"
for i in $(seq 1 12); do
  DEVICE=$(find_iphone)
  [ -n "$DEVICE" ] && break
  sleep 5
done
if [ -z "$DEVICE" ]; then
  echo "No connected iPhone found."
  echo "Plug it in with a cable, unlock it, and tap Trust if asked. Then run this again."
  exit 1
fi

echo "Building…"
xcodebuild -project Birthdays.xcodeproj -scheme Birthdays -sdk iphoneos -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build/device -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration build 2>&1 | grep -E "error:|BUILD" | sort -u

APP=build/device/Build/Products/Release-iphoneos/Birthdays.app
[ -d "$APP" ] || { echo "Build failed."; exit 1; }

echo "Installing…"
xcrun devicectl device install app --device "$DEVICE" "$APP" 2>&1 | tail -2
echo "Opening…"
xcrun devicectl device process launch --device "$DEVICE" com.giantrub.Birthdays >/dev/null 2>&1 \
  || echo "Installed. Open Birthdays from the Home Screen (first time: Settings > General > VPN & Device Management > Trust)."
echo "Done."
