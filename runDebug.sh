version=`grep 'version: ' pubspec.yaml | sed 's/version: //'`

flutter run --dart-define-from-file=env/dev.json  --dart-define=VERSION=$version