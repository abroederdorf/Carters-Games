from PIL import Image, ImageDraw

def surgical_fix_robot_v2(image_path):
    img = Image.open(image_path).convert("RGBA")
    # Target the point we found
    seed = (268, 642)
    p = img.getpixel(seed)
    if p[3] > 0 and p[0] > 240 and p[1] > 240 and p[2] > 240:
        print(f"Filling white gap at {seed}")
        # Use a low threshold to be safe
        ImageDraw.floodfill(img, seed, (255, 255, 255, 0), thresh=10)
    img.save(image_path)

if __name__ == "__main__":
    surgical_fix_robot_v2("assets/sprites/hide_seek/space/robot.png")
