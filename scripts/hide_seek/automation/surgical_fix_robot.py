from PIL import Image, ImageDraw

def surgical_fix_robot(image_path):
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    print(f"Robot size: {w}x{h}")
    
    # Target points: bottom center, slightly above the very bottom edge
    # to avoid the black outline if there is one.
    seeds = [
        (w // 2, h - 15),
        (w // 2, h - 30),
        (w // 2 - 10, h - 20),
        (w // 2 + 10, h - 20)
    ]
    
    for seed in seeds:
        p = img.getpixel(seed)
        print(f"Checking seed {seed}: {p}")
        # Only fill if it's very white (R,G,B > 240)
        if p[3] > 0 and p[0] > 240 and p[1] > 240 and p[2] > 240:
            print(f"  Filling white gap at {seed}")
            ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=30)
            
    img.save(image_path)

if __name__ == "__main__":
    surgical_fix_robot("assets/sprites/hide_seek/space/robot.png")
