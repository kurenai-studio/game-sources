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
    TOP_LEVEL_PATH = path.join(SCRIPTS_DIR, "..\\..", "CupcakePursuitMGVB.iOS\\AppIcon.xcassets")
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
    
    print("iOS Icon Generation Started!")
    
    # Create directory
    print(f"Creating {XCASSETS_PATH} directory")
    makedirs(XCASSETS_PATH, exist_ok=True)
    
    # Generate the required icon sizes
    print("Generating iOS icons")
    icon_sizes = [
        (20, "icon_20x20.png"),
        (29, "icon_29x29.png"),
        (40, "icon_40x40.png"),
        (58, "icon_58x58.png"),
        (60, "icon_60x60.png"),
        (76, "icon_76x76.png"),
        (80, "icon_80x80.png"),
        (87, "icon_87x87.png"),
        (120, "icon_120x120.png"),
        (152, "icon_152x152.png"),
        (167, "icon_167x167.png"),
        (180, "icon_180x180.png"),
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
                "filename": "icon_40x40.png",
                "idiom": "iphone",
                "scale": "2x",
                "size": "20x20"
            },
            {
                "filename": "icon_60x60.png",
                "idiom": "iphone",
                "scale": "3x",
                "size": "20x20"
            },
            {
                "filename": "icon_58x58.png",
                "idiom": "iphone",
                "scale": "2x",
                "size": "29x29"
            },
            {
                "filename": "icon_87x87.png",
                "idiom": "iphone",
                "scale": "3x",
                "size": "29x29"
            },
            {
                "filename": "icon_80x80.png",
                "idiom": "iphone",
                "scale": "2x",
                "size": "40x40"
            },
            {
                "filename": "icon_120x120.png",
                "idiom": "iphone",
                "scale": "3x",
                "size": "40x40"
            },
            {
                "filename": "icon_120x120.png",
                "idiom": "iphone",
                "scale": "2x",
                "size": "60x60"
            },
            {
                "filename": "icon_180x180.png",
                "idiom": "iphone",
                "scale": "3x",
                "size": "60x60"
            },
            {
                "filename": "icon_20x20.png",
                "idiom": "ipad",
                "scale": "1x",
                "size": "20x20"
            },
            {
                "filename": "icon_40x40.png",
                "idiom": "ipad",
                "scale": "2x",
                "size": "20x20"
            },
            {
                "filename": "icon_29x29.png",
                "idiom": "ipad",
                "scale": "1x",
                "size": "29x29"
            },
            {
                "filename": "icon_58x58.png",
                "idiom": "ipad",
                "scale": "2x",
                "size": "29x29"
            },
            {
                "filename": "icon_40x40.png",
                "idiom": "ipad",
                "scale": "1x",
                "size": "40x40"
            },
            {
                "filename": "icon_80x80.png",
                "idiom": "ipad",
                "scale": "2x",
                "size": "40x40"
            },
            {
                "filename": "icon_76x76.png",
                "idiom": "ipad",
                "scale": "1x",
                "size": "76x76"
            },
            {
                "filename": "icon_152x152.png",
                "idiom": "ipad",
                "scale": "2x",
                "size": "76x76"
            },
            {
                "filename": "icon_167x167.png",
                "idiom": "ipad",
                "scale": "2x",
                "size": "83.5x83.5"
            },
            {
                "filename": "icon_1024x1024.png",
                "idiom": "ios-marketing",
                "scale": "1x",
                "size": "1024x1024"
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
    
    print("iOS Icon Generation Complete!")


if __name__ == "__main__":
    try:
        from PIL import Image
    except ImportError:
        print("Error: Pillow library not found. Please install it using 'pip install pillow'")
        exit(1)
    main()