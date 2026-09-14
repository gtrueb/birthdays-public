#!/bin/zsh
# Builds a signed Release build and installs it on the connected iPhone.
# Run this from your own Terminal: macOS may ask to allow codesign to use your key -> click "Always Allow".
set -e
cd "$(dirname "$0")/.."
DEVICE=$(xcrun devicectl list devices --json-output /tmp/devices.json >/dev/null 2>&1; python3 -c "
import json; d=json.load(open('/tmp/devices.json'))['result']['devices']
ok=[x for x in d if x.get('connectionProperties',{}).get('tunnelState')=='connected' or 'available' in str(x.get('connectionProperties',{}).get('pairingState','')) ]
print((ok or d)[0]['identifier'] if d else '')")
if [ -z "$DEVICE" ]; then echo "No connected iPhone found. Plug it in and unlock it."; exit 1; fi
echo "Building for iPhone…"
xcodebuild -project Birthdays.xcodeproj -scheme Birthdays -sdk iphoneos -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build/device -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration build 2>&1 | grep -E "error:|BUILD" | sort -u
APP=build/device/Build/Products/Release-iphoneos/Birthdays.app
[ -d "$APP" ] || { echo "Build failed."; exit 1; }
echo "Installing…"
xcrun devicectl device install app --device "$DEVICE" "$APP"
echo "Launching…"
xcrun devicectl device process launch --device "$DEVICE" com.giantrub.Birthdays >/dev/null
echo "Done. Birthdays is on your iPhone."
