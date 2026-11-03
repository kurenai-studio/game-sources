#!/bin/zsh

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Declare constant variables
readonly resources_base_path="$SCRIPT_DIR/../../CupcakePursuitMGVB.Android/Resources"
readonly drawable_resources_path="$resources_base_path/drawable-"
readonly content_dir="$SCRIPT_DIR/../Content"

# Paths to the source images
readonly icon_source_path="$content_dir/icon-1024.png"
readonly splash_source_path="$content_dir/splash.png"

# Verify source files exist
if [ ! -f "$icon_source_path" ]; then
    echo "Error: Source icon file not found at $icon_source_path"
    exit 1
fi

if [ ! -f "$splash_source_path" ]; then
    echo "Error: Source splash file not found at $splash_source_path"
    exit 1
fi
readonly mdpi="mdpi"
readonly hdpi="hdpi"
readonly xhdpi="xhdpi"
readonly xxhdpi="xxhdpi"
readonly xxxhdpi="xxxhdpi"

echo "Generating Android icons"

echo "Generating Android splash screens"
mkdir -p "$drawable_resources_path$mdpi"
mkdir -p "$drawable_resources_path$hdpi"
mkdir -p "$drawable_resources_path$xhdpi"
mkdir -p "$drawable_resources_path$xxhdpi"
mkdir -p "$drawable_resources_path$xxxhdpi"

sips -Z 48 "$icon_source_path" -o "$drawable_resources_path$mdpi/icon.png"
sips -Z 72 "$icon_source_path" -o "$drawable_resources_path$hdpi/icon.png"
sips -Z 96 "$icon_source_path" -o "$drawable_resources_path$xhdpi/icon.png"
sips -Z 144 "$icon_source_path" -o "$drawable_resources_path$xxhdpi/icon.png"
sips -Z 192 "$icon_source_path" -o "$drawable_resources_path$xxxhdpi/icon.png"

sips -Z 470 "$splash_source_path" -o "$drawable_resources_path$mdpi/splash.png"
sips -Z 640 "$splash_source_path" -o "$drawable_resources_path$hdpi/splash.png"
sips -Z 960 "$splash_source_path" -o "$drawable_resources_path$xhdpi/splash.png"
sips -Z 1440 "$splash_source_path" -o "$drawable_resources_path$xxhdpi/splash.png"
sips -Z 1920 "$splash_source_path" -o "$drawable_resources_path$xxxhdpi/splash.png"

echo "Android Generation Complete!"