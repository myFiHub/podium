#!/bin/bash


flutter packages get

version=`grep 'version: ' pubspec.yaml | sed 's/version: //'`

flutter clean

flutter pub run flutter_native_splash:create

 flutter build appbundle --release  --dart-define-from-file=env/prod.json 

#rm -rf ./z_androidApps/*

#cp  /app/build/app/outputs/apk/release/* ./z_androidApps
