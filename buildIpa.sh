#!/bin/bash
version=`grep 'version: ' pubspec.yaml | sed 's/version: //'`
flutter build ipa --release  --dart-define=VERSION=$version