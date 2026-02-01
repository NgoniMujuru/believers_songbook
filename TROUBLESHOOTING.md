# Troubleshooting — believers_songbook

This file collects common issues and fixes encountered while preparing and running this Flutter project.

## 1) `flutter: command not found`
- Cause: Flutter SDK is not installed or not on `PATH`.
- Fix:
  ```bash
  # install (example)
  git clone https://github.com/flutter/flutter.git -b stable "$HOME/development/flutter"
  echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
  source ~/.zshrc
  flutter doctor -v
  ```

## 2) `xcrun: error: unable to find utility "xcodebuild"` / iOS builds fail
- Cause: Full Xcode app is not installed (Command Line Tools alone are insufficient for simulator/iOS builds).
- Fix:
  - Install Xcode from the App Store (or via `mas` if you use it).
  - Then run:
    ```bash
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    sudo xcodebuild -runFirstLaunch
    ```

## 3) `pod: command not found` or CocoaPods errors
- Fix: install CocoaPods via Homebrew and re-run `pod install`:
  ```bash
  brew install cocoapods
  cd ios
  pod install --repo-update
  ```

## 4) Pod install post-install hook: `Flutter.xcframework must exist` error
- Message: `/.../flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework must exist. If you're running pod install manually, make sure "flutter precache --ios" is executed first`
- Fix:
  ```bash
  flutter precache --ios
  cd ios
  pod install --repo-update
  ```

## 5) Android cmdline-tools missing / `cmdline-tools component is missing`
- Fix (manual CLI):
  ```bash
  export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
  cd /tmp
  curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  unzip -o commandlinetools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
  sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --install "platform-tools" "platforms;android-36" "build-tools;36.0.0" "cmdline-tools;latest"
  yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --licenses
  flutter doctor --android-licenses
  ```

## 6) `Android license status unknown` / accept licenses
- Fix: run `flutter doctor --android-licenses` and accept prompts.

## 7) No devices found or simulator not detected
- Start simulator:
  ```bash
  open -a Simulator
  flutter devices
  flutter run -d <SIMULATOR-UUID>
  ```

## 8) If `flutter run -d macos` fails due to Xcode or plugins
- macOS builds may also require Xcode components for native plugins; make sure Xcode is installed and CocoaPods are set up.

## 9) General debugging
- Run `flutter doctor -v` and follow its recommendations.
- Use `flutter run -v` to see verbose logs for build failures.

If you hit an error not covered here, paste the exact error output and I will provide the specific fix.

## Developer pre-commit checklist
Run these before staging and committing code to reduce CI issues and lint warnings:

- `flutter pub get` — ensure dependencies are available
- `flutter analyze` — fix/inspect reported issues
- `dart fix --apply` — apply automatic fixes
- `dart format .` — format code
- `flutter test` — run tests

Then stage and commit changes:
```bash
git add -A
git commit -m "<type>(scope): short description"
```

Use the README's Best Practices section for recommended commit message style and branching.
