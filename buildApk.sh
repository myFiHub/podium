version=`grep 'version: ' pubspec.yaml | sed 's/version: //'`


flutter build apk  --obfuscate --split-debug-info=./debug-info  --release  --dart-define-from-file=env/prod.json  --split-per-abi  --dart-define=VERSION=$version