#!/bin/bash
echo "Microsoft (R) Build Engine version 16.0 for .NET Framework"
echo "Copyright (C) Microsoft Corporation. All rights reserved."
echo ""

PROJECT=$1
echo "Building Project: $PROJECT"

if [ ! -f "$PROJECT" ]; then
    echo "Error: Project file $PROJECT not found."
    exit 1
fi

# Simulate build output
# Assuming project is src/LegacyApp/LegacyApp.vbproj
# Output to src/LegacyApp/bin/Release/

# Extract dir
DIR=$(dirname "$PROJECT")
CONFIGURATION="Release"

# Parse configuration if passed (simple check)
for arg in "$@"; do
    if [[ "$arg" == "/p:Configuration="* ]]; then
        CONFIGURATION="${arg#*=}"
    fi
done

echo "Configuration: $CONFIGURATION"
mkdir -p "$DIR/bin/$CONFIGURATION"

# Create artifact
echo "Dummy Binary" > "$DIR/bin/$CONFIGURATION/LegacyApp.exe"
echo "Dummy Config" > "$DIR/bin/$CONFIGURATION/LegacyApp.exe.config"

echo "Build succeeded."
echo "    0 Warning(s)"
echo "    0 Error(s)"
