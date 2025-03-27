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

    echo -e "\033[32mSuccessfully updated VERSION to $VERSION in $ENV_FILE\033[0m"
    # make the color red if the environment is production
    if [ "$ENVIRONMENT_PARAM" = "production" ]; then
        echo -e "\033[31mBuilding apk for $ENVIRONMENT_PARAM\033[0m"
    else
        echo -e "\033[32mBuilding apk for $ENVIRONMENT_PARAM\033[0m"
    fi
else
    echo "Error: $ENV_FILE file not found"
    exit 1
fi
# add ENVIRONMENT_PARAM as build argument
flutter build apk  --obfuscate --split-debug-info=./debug-info  --release   --split-per-abi  --dart-define=ENVIRONMENT=$ENVIRONMENT_PARAM