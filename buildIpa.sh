#!/bin/bash
version=`grep 'version: ' pubspec.yaml | sed 's/version: //'`
flutter build ipa --release  --dart-define-from-file=env/prod.json  --dart-define=VERSION=$version