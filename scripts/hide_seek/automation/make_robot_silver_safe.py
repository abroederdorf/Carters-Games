from PIL import Image

def make_robot_silver_safe(image_path):
    img = Image.open(image_path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    # Assume eyes are in the top 30% of the image
    eyes_y_threshold = int(h * 0.3)
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # If it's very white (and opaque)
            if a > 0 and r > 210 and g > 210 and b > 210:
                # If it's below the eyes threshold, turn it silver
                if y > eyes_y_threshold:
                    pixels[x, y] = (200, 200, 200, a)
                
    img.save(image_path)
    print(f"Made robot body silver (preserved eyes area) in {image_path}")

if __name__ == "__main__":
    make_robot_silver_safe("assets/sprites/hide_seek/space/robot.png")
