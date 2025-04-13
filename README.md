# Podium

A Flutter application with Firebase integration and Jitsi Meet video conferencing capabilities.

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Firebase CLI
- Xcode (for iOS development)
- Android Studio (for Android development)
- CocoaPods (for iOS dependencies)
- Git (for submodule management)

## Getting Started

### 1. Clone the Repository

```bash
git clone [repository-url]
cd podium
```

### 2. Initialize Submodules

The project uses a custom Jitsi Meet Flutter SDK as a submodule. Initialize it with:

```bash
git submodule update --init --recursive
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Firebase Setup

1. Install Firebase CLI:

```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase:

```bash
flutterfire configure
```

### 5. Environment Configuration

1. Copy the example environment file:

```bash
cp env/dev.example.json env/dev.json
```

2. Fill in the environment variables in `env/dev.json` with your configuration values.

### 6. Jitsi Plugin Configuration

The project uses a custom Jitsi Meet Flutter SDK located in the `jitsi-meet-flutter-sdk` directory. For Android, update the Jitsi plugin path in `jitsi_plugin/android/build.gradle`:

```gradle
url "your-project-path/jitsi_plugin/android/libs"
```

### 7. Running the App

#### Development Mode

```bash
flutter run --dart-define-from-file=env/dev.json
```

#### Building for Production

##### Android (App Bundle)

```bash
chmod +x buildBundle.sh
./buildBundle.sh [environment]
# Example: ./buildBundle.sh production
```

##### iOS (IPA)

```bash
chmod +x buildIpa.sh
./buildIpa.sh [environment]
# Example: ./buildIpa.sh production
```

The build scripts will automatically:

- Read the version from pubspec.yaml
- Update the environment file with the current version
- Build the app with the specified environment

### 8. Environment Options

- `development`: For local development
- `staging`: For testing in a staging environment
- `production`: For production deployment

## Project Structure

- `lib/`: Main application code
- `env/`: Environment configuration files
- `jitsi-meet-flutter-sdk/`: Custom Jitsi Meet Flutter SDK submodule
- `jitsi_plugin/`: Custom Jitsi Meet plugin
- `buildBundle.sh`: Script for building Android app bundles
- `buildIpa.sh`: Script for building iOS IPA files

## Troubleshooting

1. If you encounter any issues with Firebase configuration, try:

```bash
flutter clean
flutter pub get
flutterfire configure
```

2. For iOS build issues, ensure you have:

- Latest Xcode installed
- CocoaPods installed and updated
- Valid provisioning profiles and certificates

3. For Android build issues, ensure you have:

- Latest Android Studio installed
- Valid keystore file for signing
- Proper environment variables set

4. If you encounter submodule issues:

```bash
git submodule update --init --recursive
```

## Support

For any issues or questions, please contact the development team or create an issue in the repository.
