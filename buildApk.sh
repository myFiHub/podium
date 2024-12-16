version=`grep 'version: ' pubspec.yaml | sed 's/version: //'`


flutter build apk  --obfuscate --split-debug-info=./debug-info  --release   --split-per-abi  --dart-define=VERSION=$version