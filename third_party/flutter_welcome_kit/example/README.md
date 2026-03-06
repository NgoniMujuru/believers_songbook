# Flutter Welcome Kit Demo

An interactive demo showcasing the features of Flutter Welcome Kit package.

![Demo Preview](../docs/screenshots/demo.gif)

## Features Demonstrated

- Interactive tour guide
- Smart tooltip positioning
- Custom animations
- Responsive design
- Theme customization
- Keyboard navigation

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/usman-bhat/flutter_welcome_kit.git
```

2. Navigate to example directory:
```bash
cd flutter_welcome_kit/example
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the demo:
```bash
flutter run
```

## Live Demo

Try the web demo at: https://usman-bhat.github.io/flutter_welcome_kit

## Code Structure

- `lib/main.dart` - Main demo application
- `lib/screens/` - Demo screens
- `lib/widgets/` - Custom widgets
- `lib/utils/` - Helper utilities

## Usage Example

```dart
// Create global keys for widgets
final logoKey = GlobalKey();
final searchKey = GlobalKey();

// Define tour steps
final steps = [
  TourStep(
    key: logoKey,
    title: "Welcome!",
    description: "Let's explore the app.",
  ),
  TourStep(
    key: searchKey,
    title: "Search",
    description: "Find anything instantly.",
  ),
];

// Start the tour
TourController(steps: steps).start();
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
