# Vestel Multicooker Watch

A watchOS app for controlling a smart multicooker from an Apple Watch, designed in a Human-Computer Interaction (HCI) course. The interface is built around quick glances and minimal interaction on a small screen.

## Features

- Browse and choose recipes, with a confirmation step before cooking starts
- Live cooking screen with heat level and status
- Notifications page for cooking events
- Settings page

## Tech stack

Swift, SwiftUI, watchOS

## Requirements

- Xcode
- A watchOS Simulator

## Running with Xcode

1. Open `VestelMulticookerWatch.xcodeproj` in Xcode.
2. Select the `VestelMulticookerWatch` scheme.
3. Choose a watchOS Simulator as the target.
4. Press Run.

## Building from the terminal

```zsh
xcodebuild -scheme VestelMulticookerWatch -workspace VestelMulticookerWatch.xcodeproj/project.xcworkspace -destination 'platform=watchOS Simulator,name=<simulator name>' build
```

## Running on the simulator from the terminal

Set the app bundle path first:

```zsh
APP_PATH="$HOME/Library/Developer/Xcode/DerivedData/VestelMulticookerWatch-<id>/Build/Products/Debug-watchsimulator/VestelMulticookerWatch.app"
BUNDLE_ID="com.berfin.vestelmulticooker.watchkitapp"
```

Then install and launch the app:

```zsh
xcrun simctl install booted "$APP_PATH" && xcrun simctl launch booted "$BUNDLE_ID"
```

To find the correct DerivedData path after a build:

```zsh
find ~/Library/Developer/Xcode/DerivedData -path '*VestelMulticookerWatch.app' -print
```
