import sys
from pathlib import Path
from PIL import Image

def process_images(directory):
    for img_path in Path(directory).rglob('*.png'):
        try:
            img = Image.open(img_path).convert("RGBA")
            data = list(img.getdata()) # type: ignore
            
            new_data = [
                (255, 255, 255, 0) if r == 255 and g == 255 and b == 255 else (r, g, b, a) 
                for r, g, b, a in data
            ]
            
            if data != new_data:
                img.putdata(new_data)
                img.save(img_path, "PNG")
                print(f"Modified: {img_path}")
                
        except Exception as e:
            print(f"Error: {img_path} - {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    
    process_images(sys.argv[1])