#!/bin/bash
 flutter build appbundle   --release   --obfuscate --split-debug-info=./debug-info --dart-define-from-file=env/prod.json 
