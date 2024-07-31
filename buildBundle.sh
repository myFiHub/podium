#!/bin/bash
 flutter build appbundle --obfuscate --split-debug-info=./debug-info  --release  --dart-define-from-file=env/prod.json 
