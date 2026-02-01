# believers_songbook

A Flutter songbook application.


## First-time setup (after cloning)

Follow these steps to prepare and run the app locally after cloning the repository.

- **Clone the repository** (example destination `~/projects`):
	```bash
	git clone https://github.com/NgoniMujuru/believers_songbook.git ~/projects/believers_songbook
	cd ~/projects/believers_songbook
	```

- **Install Flutter SDK**: follow the official guide at https://docs.flutter.dev/get-started/install.
	- Recommended path: `~/development/flutter`
	- Add to PATH (example for `zsh`):
		```bash
		echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
		source ~/.zshrc
		```

- **Fetch packages**:
	```bash
	# run from the project root (where you cloned the repo)
	cd ~/projects/believers_songbook
	flutter pub get
	```

-- **macOS / iOS preparation** (only if you plan to run on macOS or the iOS simulator):
	- Install Xcode from the App Store (full app required for simulator and iOS builds).
	- After installing Xcode run:
		```bash
		sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
		sudo xcodebuild -runFirstLaunch
		```
	- Install CocoaPods (if not installed):
		```bash
		brew install cocoapods
		```
	- Precache iOS Flutter artifacts and install iOS pods (run from project root):
		```bash
		flutter precache --ios
		cd ios
		pod install --repo-update
		cd ..
		```

-- **Android preparation** (only if you plan to run on Android):
	- Install Android Studio and the Android SDK or install command-line tools.
	- Ensure `ANDROID_SDK_ROOT` or `ANDROID_HOME` points to your SDK (example):
		```bash
		export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
		```
	- Install command-line tools (if needed) and accept licenses:
		```bash
		# using sdkmanager from cmdline-tools
		sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0"
		yes | sdkmanager --licenses
		flutter doctor --android-licenses
		```

## Run the app

- Run on macOS desktop:
	```bash
	flutter run -d macos
	```

-- Run on the iOS Simulator (example uses detected simulator UUID):
	```bash
	# start Simulator (if not already running)
	open -a Simulator
	flutter devices
	# from project root
	flutter run -d <SIMULATOR-UUID>
	```

- Run on Chrome (web):
	```bash
	flutter run -d chrome
	```

- Run on an Android emulator:
	```bash
	flutter emulators --launch <emulator-id>
	flutter run -d <device-id>
	```

## More help
- If you encounter platform-specific problems, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Useful commands
- `git clone https://github.com/NgoniMujuru/believers_songbook.git` — clone the repo
- `flutter doctor -v` — diagnose environment
- `flutter pub get` — fetch dependencies
- `flutter precache --ios` — fetch iOS engine artifacts (needed before `pod install` sometimes)
- `pod install` — install iOS CocoaPods (run inside `ios/`)

## Best practices & Git workflow

Follow these recommended steps when developing and contributing to this project.

- Create a feature branch for each change:
	```bash
	git checkout -b feature/short-description
	```
- Keep changes small and focused. Run local checks before committing:
	```bash
	# fetch packages
	flutter pub get

	# run analyzer and apply automatic fixes
	flutter analyze
	dart fix --apply

	# run tests (if present)
	flutter test

	# format code
	dart format .
	```
- When working on iOS, ensure CocoaPods are up to date:
	```bash
	flutter precache --ios
	cd ios && pod install --repo-update && cd ..
	```
- Stage and commit with a concise message (use Conventional Commits style):
	```bash
	git add -A
	git commit -m "<type>(scope): short description\n\nMore detailed description if needed."
	```
	Example:
	```bash
	git commit -m "feat(collections): add FAB to create collections and swipe-to-delete songs"
	```

- Push your branch and open a Pull Request for review:
	```bash
	git push -u origin feature/short-description
	```

Following this workflow helps keep the repository clean and makes reviews easier.

## Clean / safe removal of build directories
- From the project root you can safely remove build artifacts and regenerate them:
	```bash
	# cleans Flutter build outputs
	flutter clean

	# remove iOS CocoaPods build files (will be reinstalled by `pod install`)
	rm -rf ios/Pods ios/Podfile.lock ios/Flutter/Flutter.framework

	# remove macOS build artifacts
	rm -rf macos/Build macos/Flutter/Flutter.framework
	```
