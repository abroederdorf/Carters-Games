import os
from pathlib import Path
from PIL import Image

def crop_artifact_borders(image_path, border_pixels=4):
    """
    Crops a few pixels off each side of an image to remove AI-generated 
    bounding box artifacts or 'square' outlines.
    """
    print(f"Cropping: {image_path}")
    img = Image.open(image_path)
    width, height = img.size
    
    if width <= border_pixels * 2 or height <= border_pixels * 2:
        print(f"  Skipping (too small): {image_path}")
        return

    # Crop (left, top, right, bottom)
    left = border_pixels
    top = border_pixels
    right = width - border_pixels
    bottom = height - border_pixels
    
    img_cropped = img.crop((left, top, right, bottom))
    img_cropped.save(image_path)

def main():
    # Targeted cleanup for fire_station items
    fire_station_dir = Path("assets/sprites/hide_seek/fire_station")
    
    if not fire_station_dir.exists():
        print("Fire station directory not found.")
        return

    print("\n--- Cleaning Fire Station Assets ---")
    for img_path in fire_station_dir.glob("*.png"):
        # Skip backgrounds
        if "bg" in img_path.name:
            continue
            
        crop_artifact_borders(img_path, border_pixels=10)

if __name__ == "__main__":
    main()
