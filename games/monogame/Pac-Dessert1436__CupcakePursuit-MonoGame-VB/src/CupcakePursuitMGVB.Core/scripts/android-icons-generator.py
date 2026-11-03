#!/usr/bin/env python3

from os import makedirs, path
from sys import exit
from enum import StrEnum, unique
from PIL import Image


@unique
class DpiCategory(StrEnum):
    MDPI = "mdpi"
    HDPI = "hdpi"
    XHDPI = "xhdpi"
    XXHDPI = "xxhdpi"
    XXXHDPI = "xxxhdpi"


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
    RESOURCES_BASE_PATH = path.join(SCRIPTS_DIR, "..\\..", "CupcakePursuitMGVB.Android\\Resources")
    DRAWABLE_RESOURCES_PATH = path.join(RESOURCES_BASE_PATH, "drawable-")
    CONTENT_DIR = path.join(SCRIPTS_DIR, "..", "Content")
    
    # Paths to the source images
    ICON_SOURCE_PATH = path.join(CONTENT_DIR, "icon-1024.png")
    SPLASH_SOURCE_PATH = path.join(CONTENT_DIR, "splash.png")
    
    # Verify source files exist
    if not path.exists(ICON_SOURCE_PATH):
        print(f"Error: Source icon file not found at {ICON_SOURCE_PATH}")
        exit(1)
    
    if not path.exists(SPLASH_SOURCE_PATH):
        print(f"Error: Source splash file not found at {SPLASH_SOURCE_PATH}")
        exit(1)
    
    print("Generating Android icons")
    print("Generating Android splash screens")
    
    # Create directories
    for density in DpiCategory:
        directory = f"{DRAWABLE_RESOURCES_PATH}{density.value}"
        makedirs(directory, exist_ok=True)
        print(f"Created directory: {directory}")
    
    # Generate icons
    icon_sizes = {
        DpiCategory.MDPI: 48,
        DpiCategory.HDPI: 72,
        DpiCategory.XHDPI: 96,
        DpiCategory.XXHDPI: 144,
        DpiCategory.XXXHDPI: 192
    }
    
    for density, size in icon_sizes.items():
        output_path = f"{DRAWABLE_RESOURCES_PATH}{density.value}\\icon.png"
        if resize_image(ICON_SOURCE_PATH, output_path, size):
            print(f"Generated icon: {output_path}")
        else:
            print(f"Failed to generate icon: {output_path}")
            exit(1)
    
    # Generate splash screens
    splash_sizes = {
        DpiCategory.MDPI: 470,
        DpiCategory.HDPI: 640,
        DpiCategory.XHDPI: 960,
        DpiCategory.XXHDPI: 1440,
        DpiCategory.XXXHDPI: 1920
    }
    
    for density, size in splash_sizes.items():
        output_path = f"{DRAWABLE_RESOURCES_PATH}{density.value}\\splash.png"
        if resize_image(SPLASH_SOURCE_PATH, output_path, size):
            print(f"Generated splash: {output_path}")
        else:
            print(f"Failed to generate splash: {output_path}")
            exit(1)
    
    print("Android Generation Complete!")


if __name__ == "__main__":
    try:
        from PIL import Image
    except ImportError:
        print("Error: Pillow library not found. Please install it using 'pip install pillow'")
        exit(1)
    main()