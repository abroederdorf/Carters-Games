import os
from pathlib import Path
from PIL import Image, ImageDraw

def fix_transparency(image_path, tolerance=50, white_threshold=210, remove_bottom_island=False, clear_internal_holes=True):
    """
    Removes white background and internal white holes.
    Optionally removes disconnected islands at the bottom.
    """
    if not os.path.exists(image_path):
        print(f"File not found: {image_path}")
        return

    print(f"Processing: {image_path}")
    img = Image.open(image_path).convert("RGBA")
    
    # 0. Initial crop to remove AI-generated frames/borders
    width, height = img.size
    border = 10
    if width > border * 2 and height > border * 2:
        img = img.crop((border, border, width - border, height - border))
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
        # Be more lenient with perimeter seeds since they are almost certainly background
        if pixel[0] >= 180 and pixel[1] >= 180 and pixel[2] >= 180:
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=tolerance)

    # 2. Internal Pass: Clear remaining very-white pixels
    if clear_internal_holes:
        data = img.getdata()
        new_data = []
        for item in data:
            # If it's extremely white and not yet transparent, clear it
            if item[3] > 0 and item[0] >= white_threshold and item[1] >= white_threshold and item[2] >= white_threshold:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        img.putdata(new_data)

    # 3. Remove disconnected bottom island (for shadows)
    if remove_bottom_island:
        alpha = img.getchannel('A')
        alpha_data = list(alpha.getdata())
        row_sums = [sum(alpha_data[i*width:(i+1)*width]) for i in range(height)]
        
        # Find all gaps (contiguous zero-alpha rows)
        gaps = []
        in_gap = False
        gap_start = -1
        for i in range(height):
            if row_sums[i] == 0:
                if not in_gap:
                    gap_start = i
                    in_gap = True
            else:
                if in_gap:
                    gaps.append((gap_start, i - 1))
                    in_gap = False
        if in_gap:
            gaps.append((gap_start, height - 1))
            
        # Find the widest gap that has content both above and below it
        widest_gap = None
        max_width = -1
        for start, end in gaps:
            width_gap = end - start + 1
            # Check if there is content above and below
            has_above = any(s > 0 for s in row_sums[:start])
            has_below = any(s > 0 for s in row_sums[end+1:])
            if has_above and has_below:
                if width_gap > max_width:
                    max_width = width_gap
                    widest_gap = (start, end)
        
        if widest_gap:
            gap_start, gap_end = widest_gap
            print(f"Removing content below widest gap (rows {gap_start}-{gap_end}, width {max_width})")
            # Clear everything from the start of the gap to the bottom
            draw = ImageDraw.Draw(img)
            draw.rectangle([0, gap_start, width, height], fill=(0, 0, 0, 0))

    # 4. Autocrop
    alpha = img.getchannel('A')
    bbox = alpha.getbbox()
    if bbox:
        img = img.crop(bbox)
        print(f"Autocropped to {img.size}")

    # Save back to the same path
    img.save(image_path, "WEBP")
    print(f"Successfully processed {image_path}")

if __name__ == "__main__":
    targets = [
        ("assets/sprites/hide_seek/beauty_salon/hair_clip.webp", False, True),
        ("assets/sprites/hide_seek/beauty_salon/hair_buzzer.webp", False, True),
        ("assets/sprites/hide_seek/classroom/pencil.webp", True, True),
        ("assets/sprites/hide_seek/classroom/potted_plant.webp", False, True),
        ("assets/sprites/hide_seek/beach/sand_bucket.webp", False, True),
        ("assets/sprites/hide_seek/beach/flip_flops.webp", False, True),
        ("assets/sprites/hide_seek/beach/swim_ring.webp", False, True),
        ("assets/sprites/hide_seek/beach/beach_chair.webp", False, True),
        ("assets/sprites/hide_seek/beach/beach_umbrella.webp", False, True),
        ("assets/sprites/hide_seek/beach/beach_ball.webp", False, True),
        ("assets/sprites/hide_seek/beach/snorkel.webp", False, True),
        ("assets/sprites/hide_seek/beach/sailboat.webp", False, False),
    ]
    for target, remove_island, clear_holes in targets:
        fix_transparency(target, remove_bottom_island=remove_island, clear_internal_holes=clear_holes)
