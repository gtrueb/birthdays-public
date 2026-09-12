#!/bin/zsh
# Builds the app for the simulator. Prints only errors and the result.
set -e
cd "$(dirname "$0")/.."
if [ ! -d Birthdays.xcodeproj ] || [ project.yml -nt Birthdays.xcodeproj/project.pbxproj ]; then xcodegen generate >/dev/null; fi
xcodebuild -project Birthdays.xcodeproj -scheme Birthdays -sdk iphonesimulator -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build build \
  2>&1 | grep -E "error:|BUILD" | sed 's/^.*\/Birthdays\//Birthdays\//' | sort -u
