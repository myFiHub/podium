# podium

## Getting Started

in jitsi_plugin/android/build.gradle, change the line:
url "D:/my_projects/podium_fihub/jitsi_plugin/android/libs"
from D:/my_projects/podium_fihub/jitsi_plugin/android/libs, to "your project location"/jitsi_plugin/android/libs

add this to firebase realtime database rules

```json
{
  "rules": {
    "notifications": {
      ".indexOn": ["targetUserId"]
    }
  }
}
```

fill the environment variables in the env/dev.json file (like the example file env/dev.example.json) and run the following commands:

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
flutter run --dart-define-from-file=env/dev.json
```
