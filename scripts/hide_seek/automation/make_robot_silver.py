from PIL import Image

def make_robot_silver(image_path):
    img = Image.open(image_path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # If it's very white (and opaque), turn it silver
            if a > 0 and r > 210 and g > 210 and b > 210:
                # Silver color (200, 200, 200)
                pixels[x, y] = (200, 200, 200, a)
                
    img.save(image_path)
    print(f"Made robot silver in {image_path}")

if __name__ == "__main__":
    make_robot_silver("assets/sprites/hide_seek/space/robot.png")
