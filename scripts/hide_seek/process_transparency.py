import os
from pathlib import Path
from PIL import Image

ASSET_ROOT = Path("assets/sprites/hide_seek")

def make_transparent(image_path, threshold=240):
    """
    Makes the white background of an image transparent.
    threshold: Any pixel where R, G, and B are all above this value will be made transparent.
    """
    print(f"Processing: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    datas = img.getdata()

    new_data = []
    for item in datas:
        # Check if pixel is "white enough"
        if item[0] >= threshold and item[1] >= threshold and item[2] >= threshold:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)

    img.putdata(new_data)
    img.save(image_path)

def main():
    # Iterate through all theme directories
    for theme_dir in ASSET_ROOT.iterdir():
        if not theme_dir.is_dir() or theme_dir.name == "shared":
            continue
            
        print(f"\n--- Theme: {theme_dir.name} ---")
        for img_path in theme_dir.glob("*.png"):
            # Skip background images
            if img_path.name == "bg.png" or img_path.name.startswith("bg_"):
                continue
                
            make_transparent(img_path)

    # Also process shared folder
    shared_dir = ASSET_ROOT / "shared"
    if shared_dir.exists():
        print("\n--- Shared Items ---")
        for img_path in shared_dir.glob("*.png"):
            make_transparent(img_path)

if __name__ == "__main__":
    main()
