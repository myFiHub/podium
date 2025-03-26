#!/bin/bash

ENVIRONMENT_PARAM=$1
# Read version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

# Check if version was found
if [ -z "$VERSION" ]; then
    echo "Error: Could not find version in pubspec.yaml"
    exit 1
fi


if [ -z "$ENVIRONMENT_PARAM" ]; then
    ENVIRONMENT_PARAM="development"
fi

echo "ENVIRONMENT_PARAM: $ENVIRONMENT_PARAM"
# Path to production.env
ENV_FILE="env/$ENVIRONMENT_PARAM.env"

# Update development.env
if [ -f "$ENV_FILE" ]; then
    # Check if VERSION already exists in the file
    if grep -q "^VERSION=" "$ENV_FILE"; then
        # Replace existing VERSION line
        sed -i '' "s/^VERSION=.*/VERSION=$VERSION/" "$ENV_FILE"
    else
        # Add VERSION line if it doesn't exist
        echo "VERSION=$VERSION" >> "$ENV_FILE"
    fi
    echo "Successfully updated VERSION to $VERSION in $ENV_FILE"
else
    echo "Error: $ENV_FILE file not found"
    exit 1
fi
flutter build appbundle --obfuscate --split-debug-info=./debug-info  --release  --dart-define=ENVIRONMENT=$ENVIRONMENT_PARAM