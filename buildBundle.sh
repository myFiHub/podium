#!/bin/bash
version=`grep 'version: ' pubspec.yaml | sed 's/version: //'`
flutter build appbundle --obfuscate --split-debug-info=./debug-info  --release  --dart-define-from-file=env/prod.json  --dart-define=VERSION=$version