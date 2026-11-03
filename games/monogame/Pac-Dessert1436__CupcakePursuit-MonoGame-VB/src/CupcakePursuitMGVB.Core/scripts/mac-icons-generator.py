#!/usr/bin/env python3

from os import path, makedirs
from sys import exit
import json
from PIL import Image


def get_user_confirmation(prompt: str) -> bool:
    """Get user confirmation with y/n input."""
    while True:
        response = input(prompt).strip().lower()
        if response in ['y', 'yes']:
            return True
        elif response in ['n', 'no']:
            return False
        else:
            print("Invalid input. Please enter 'y'/'yes' or 'n'/'no'.")


def resize_image(input_path: str, output_path: str, size: int) -> bool:
    """
    Resize an image to the specified size while maintaining aspect ratio.
    
    NOTE: The '-Z' option in 'sips' maintains aspect ratio, so we'll do the same.
    """
    try:
        with Image.open(input_path) as img:
            # Calculate aspect ratio preserving size
            img.thumbnail((size, size), Image.Resampling.LANCZOS)
            
            # Create a new square image with transparent background
            new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            
            # Calculate position to paste the resized image in the center
            paste_x = (size - img.width) // 2
            paste_y = (size - img.height) // 2
            
            # Paste the resized image
            new_img.paste(img, (paste_x, paste_y))
            
            # Save the result
            new_img.save(output_path, format='PNG')
        return True
    except Exception as e:
        print(f"Error resizing image: {e}")
        return False


def main() -> None:
    # Get the correct path to the Content folder
    SCRIPTS_DIR = path.dirname(path.abspath(__file__))

    # Declare constant variables
    TOP_LEVEL_PATH = path.join(SCRIPTS_DIR, "..\\..", "CupcakePursuitMGVB.Desktop\\AppIcon.xcassets")
    XCASSETS_PATH = path.join(TOP_LEVEL_PATH, "AppIcon.appiconset")
    CONTENT_DIR = path.join(SCRIPTS_DIR, "..", "Content")
    
    # Path to the source icon
    ICON_SOURCE_PATH = path.join(CONTENT_DIR, "icon-1024.png")
    
    # Verify source file exists
    if not path.exists(ICON_SOURCE_PATH):
        print(f"Error: Source icon file not found at {ICON_SOURCE_PATH}")
        exit(1)
    
    # Prompt for user confirmation
    if not get_user_confirmation(f"This script will delete your '{XCASSETS_PATH}' directory and recreate all the assets again. Are you sure you wish to proceed? [(y)es/(n)o]: "):
        print("Deletion canceled.")
        exit(0)
    
    # Check if the directory exists and delete it
    if path.exists(TOP_LEVEL_PATH):
        import shutil
        shutil.rmtree(TOP_LEVEL_PATH)
        print(f"'{TOP_LEVEL_PATH}' directory deleted successfully.")
    else:
        print(f"'{TOP_LEVEL_PATH}' directory does not exist. Continuing.")
    
    print("macOS Icon Generation Started!")
    
    # Create directory
    print(f"Creating {XCASSETS_PATH} directory")
    makedirs(XCASSETS_PATH, exist_ok=True)
    
    # Generate the required icon sizes
    print("Generating macOS icons")
    icon_sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_32x32.png"),
        (64, "icon_64x64.png"),
        (128, "icon_128x128.png"),
        (256, "icon_256x256.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_1024x1024.png")
    ]
    
    for size, filename in icon_sizes:
        output_path = f"{XCASSETS_PATH}/{filename}"
        if resize_image(ICON_SOURCE_PATH, output_path, size):
            print(f"Generated icon: {output_path}")
        else:
            print(f"Error generating icon {output_path}")
            exit(1)
    
    # Create the Contents.json file
    print("Generating Contents.json file")
    contents_json = {
        "images": [
            {
                "filename": "icon_16x16.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "16x16"
            },
            {
                "filename": "icon_32x32.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "16x16"
            },
            {
                "filename": "icon_32x32.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "32x32"
            },
            {
                "filename": "icon_64x64.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "32x32"
            },
            {
                "filename": "icon_128x128.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "128x128"
            },
            {
                "filename": "icon_256x256.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "128x128"
            },
            {
                "filename": "icon_256x256.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "256x256"
            },
            {
                "filename": "icon_512x512.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "256x256"
            },
            {
                "filename": "icon_512x512.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "512x512"
            },
            {
                "filename": "icon_1024x1024.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "512x512"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    contents_path = path.join(XCASSETS_PATH, "Contents.json")
    try:
        with open(contents_path, 'w') as f:
            json.dump(contents_json, f, indent=2)
        print(f"Generated Contents.json: {contents_path}")
    except IOError as e:
        print(f"Error writing Contents.json: {e}")
        exit(1)
    
    print("macOS Icon Generation Complete!")


if __name__ == "__main__":
    try:
        from PIL import Image
    except ImportError:
        print("Error: Pillow library not found. Please install it using 'pip install pillow'")
        exit(1)
    main()