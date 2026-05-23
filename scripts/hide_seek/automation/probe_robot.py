from PIL import Image

def probe_robot(image_path):
    img = Image.open(image_path).convert("RGBA")
    w, h = img.size
    center_x = w // 2
    for y in range(h - 1, 0, -1):
        p = img.getpixel((center_x, y))
        if p[3] > 0:
            print(f"First opaque pixel at ({center_x}, {y}): {p}")
            break

if __name__ == "__main__":
    probe_robot("assets/sprites/hide_seek/space/robot.png")
