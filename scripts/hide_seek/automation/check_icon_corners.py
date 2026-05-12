from PIL import Image

def check_corners(path):
    print(f"Checking {path}...")
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    corners = [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1)]
    for c in corners:
        print(f"  Pixel {c}: {img.getpixel(c)}")

if __name__ == "__main__":
    check_corners("assets/icons/Find-It_Icon.png")
    check_corners("assets/icons/Gone-Fishin_Icon.png")
