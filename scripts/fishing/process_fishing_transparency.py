import os
from pathlib import Path
from PIL import Image, ImageDraw

# Target files and their directories
TARGETS = [
    ("assets/sprites/fishing", [
        "fish_plain_green.png", "fish_plain_orange.png", "fish_plain_purple.png",
        "fish_plain_red.png", "fish_plain_white.png", "fish_plain_yellow.png",
        "fish_sword.png", "fish_butterfly.png", "pelican.png", "octopus.png",
        "shark.png", "difficulty_easy.png", "difficulty_medium.png",
        "difficulty_hard.png", "mode_fish.png", "mode_math.png",
        "mode_spelling.png", "hourglass.png", "fishing_rod.png", "timer.png"
    ]),
    ("assets/sprites/ui", ["lock.png"])
]

def make_transparent(image_path, tolerance=50):
    """
    Robustly makes the background transparent. 
    Uses flood fill for the main background and a secondary pass for internal holes.
    """
    if not image_path.exists():
        print(f"Skipping (not found): {image_path}")
        return

    print(f"Processing: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    width, height = img.size
    
    # 1. Perimeter Floodfill (Safe background removal)
    seeds = []
    for x in range(width):
        seeds.append((x, 0))
        seeds.append((x, height - 1))
    for y in range(1, height - 1):
        seeds.append((0, y))
        seeds.append((width - 1, y))
        
    for seed in seeds:
        pixel = img.getpixel(seed)
        if pixel[3] == 0: continue
        # Threshold for identifying "whitish" background
        if pixel[0] >= 200 and pixel[1] >= 200 and pixel[2] >= 200:
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    # 2. Secondary Pass: Internal Holes
    # For "isolated on white" assets, any remaining very-white pixels are likely background holes
    # SKIP for assets that have intentionally white details (eyes, bodies, etc.)
    EXCLUDE_KEYWORDS = ["fish", "shark", "pelican", "octopus"]
    if all(kw not in str(image_path) for kw in EXCLUDE_KEYWORDS):
        data = img.getdata()
        new_data = []
        for item in data:
            # If it's extremely white and not yet transparent, clear it
            if item[3] > 0 and item[0] >= 245 and item[1] >= 245 and item[2] >= 245:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        img.putdata(new_data)

    # 3. Autocrop and Center with Alpha Thresholding
    alpha = img.getchannel('A')
    # Ignore pixels with very low alpha (stray pixels)
    alpha_mask = alpha.point(lambda p: 255 if p > 10 else 0)
    bbox = alpha_mask.getbbox()
    
    if bbox:
        # Crop to content
        img = img.crop(bbox)
        
        # Create a uniform 512x512 square canvas
        target_size = 512
        # Baseline padding
        padding_factor = 0.85
        
        # Individually calibrate shapes for visual weight parity
        if "difficulty_easy.png" in str(image_path):
            padding_factor = 0.70 # Circle is "bulky", keep it smallest
        elif "difficulty_medium.png" in str(image_path):
            padding_factor = 0.85 # Square is neutral
        elif "difficulty_hard.png" in str(image_path):
            padding_factor = 0.95 # Diamond has lot of "empty corners", make it biggest
            
        w, h = img.size
        # Scale to fit within the padded area
        max_dim = target_size * padding_factor
        ratio = min(max_dim / w, max_dim / h)
        new_w, new_h = int(w * ratio), int(h * ratio)
        img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Center on target_size square
        new_img = Image.new("RGBA", (target_size, target_size), (255, 255, 255, 0))
        new_img.paste(img, ((target_size - new_w) // 2, (target_size - new_h) // 2))
        img = new_img

    img.save(image_path)

if __name__ == "__main__":
    for dir_path, files in TARGETS:
        base_path = Path(dir_path)
        for filename in files:
            make_transparent(base_path / filename)
    print("Done processing transparency and centering for all targets.")
