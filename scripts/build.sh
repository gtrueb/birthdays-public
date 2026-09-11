#!/bin/zsh
# Builds the app for the simulator. Prints only errors and the result.
set -e
cd "$(dirname "$0")/.."
xcodegen generate >/dev/null
xcodebuild -project Birthdays.xcodeproj -scheme Birthdays -sdk iphonesimulator -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build build CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "error:|BUILD" | sed 's/^.*\/Birthdays\//Birthdays\//' | sort -u
