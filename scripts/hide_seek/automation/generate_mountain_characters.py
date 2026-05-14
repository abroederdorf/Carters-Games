import os
import time
import io
import json
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
from google import genai
from google.genai import types
from PIL import Image, ImageDraw

API_KEY = os.environ.get("GEMINI_API_KEY", "")
MODEL_NAME = "imagen-4.0-fast-generate-001"
client = genai.Client(api_key=API_KEY)

MANIFEST_PATH = Path("scripts/hide_seek/automation/mountain_characters_manifest.json")

def _make_transparent(image: Image.Image) -> None:
    width, height = image.size
    seeds = [(x, 0) for x in range(width)] + [(x, height - 1) for x in range(width)]
    seeds += [(0, y) for y in range(1, height - 1)] + [(width - 1, y) for y in range(1, height - 1)]
    for seed in seeds:
        pixel = image.getpixel(seed)
        if pixel[3] > 0 and pixel[0] >= 235 and pixel[1] >= 235 and pixel[2] >= 235:
            ImageDraw.floodfill(image, seed, (255, 255, 255, 0), thresh=30)

def generate_image(prompt: str, output_path: Path) -> bool:
    print(f"Generating: {output_path}...")
    try:
        response = client.models.generate_images(
            model=MODEL_NAME,
            prompt=prompt,
            config=types.GenerateImagesConfig(
                number_of_images=1,
                aspect_ratio="1:1",
                output_mime_type="image/png",
            ),
        )
        if not response.generated_images:
            print(f"  No images generated.")
            return False
        image_bytes = response.generated_images[0].image.image_bytes
        image = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
        _make_transparent(image)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        image.save(output_path)
        print(f"  Saved.")
        return True
    except Exception as e:
        print(f"  Error: {e}")
        return False

def main():
    with open(MANIFEST_PATH, "r") as f:
        manifest = json.load(f)

    print(f"Starting generation for {len(manifest)} characters...")
    for entry in manifest:
        ok = generate_image(entry["prompt"], Path(entry["output"]))
        time.sleep(5 if ok else 10)

if __name__ == "__main__":
    main()
