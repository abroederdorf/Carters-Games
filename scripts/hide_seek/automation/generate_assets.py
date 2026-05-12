import argparse
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

CHARACTER_PREFIX = "Isolated full view, white background, centered, "
OBJECT_PREFIX = "Isolated full view, white background, centered, "

STYLE_SUFFIX = ", simple flat vector design, thick black outlines, bright saturated colors, friendly cartoon style, no people, no background, no shadows, no text."

HS_THEMES_JSON = Path("assets/data/hide_seek/themes.json")
HS_ASSET_ROOT = Path("assets/sprites/hide_seek")

def load_json(path: Path) -> dict:
    with open(path, "r") as f:
        return json.load(f)

def _make_transparent(image: Image.Image) -> None:
    width, height = image.size
    # Basic floodfill from corners
    seeds = [(x, 0) for x in range(width)] + [(x, height - 1) for x in range(width)]
    seeds += [(0, y) for y in range(1, height - 1)] + [(width - 1, y) for y in range(1, height - 1)]
    for seed in seeds:
        pixel = image.getpixel(seed)
        # Target white-ish pixels
        if pixel[3] > 0 and pixel[0] >= 235 and pixel[1] >= 235 and pixel[2] >= 235:
            ImageDraw.floodfill(image, seed, (255, 255, 255, 0), thresh=30)

def generate_image(prompt: str, output_path: Path, aspect_ratio: str = "1:1", transparent_bg: bool = True) -> bool:
    print(f"Generating: {output_path}...")
    try:
        response = client.models.generate_images(
            model=MODEL_NAME,
            prompt=prompt,
            config=types.GenerateImagesConfig(
                number_of_images=1,
                aspect_ratio=aspect_ratio,
                output_mime_type="image/png",
            ),
        )
        if not response.generated_images:
            print(f"  No images generated.")
            return False
        image_bytes = response.generated_images[0].image.image_bytes
        image = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
        if transparent_bg:
            _make_transparent(image)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        image.save(output_path)
        print(f"  Saved.")
        return True
    except Exception as e:
        print(f"  Error: {e}")
        return False

MAX_GENERATIONS_PER_RUN = 3 # Rigid limit for review cycles

def run_manifest(manifest_path: Path) -> None:
    """Generic mode: flat JSON array of {output, prompt, aspect_ratio?, transparent_bg?}"""
    entries = [e for e in load_json(manifest_path) if not Path(e["output"]).exists()]
    
    if not entries:
        print("No new assets to generate.")
        return

    # Enforce limit
    to_generate = entries[:MAX_GENERATIONS_PER_RUN]
    print(f"Plan: Generating {len(to_generate)} assets (Limit: {MAX_GENERATIONS_PER_RUN}).")
    
    for entry in to_generate:
        out = Path(entry["output"])
        ok = generate_image(
            prompt=entry["prompt"],
            output_path=out,
            aspect_ratio=entry.get("aspect_ratio", "1:1"),
            transparent_bg=entry.get("transparent_bg", True),
        )
        time.sleep(5 if ok else 10)
    
    print(f"\nBatch of {len(to_generate)} complete. Please review before generating more.")

def run_hide_seek(themes_json: Path = HS_THEMES_JSON, asset_root: Path = HS_ASSET_ROOT) -> None:
    """Hide & Seek mode: generates backgrounds + items from themes.json."""
    index = load_json(themes_json)
    for theme_name, data in index["themes"].items():
        theme_dir = asset_root / theme_name
        theme_dir.mkdir(parents=True, exist_ok=True)

        # 1. Generate Items First
        generated_items = []
        for item_data in data["items"]:
            if "shared" in item_data:
                continue
            item_path = theme_dir / f"{item_data['name']}.png"
            if not item_path.exists():
                prefix = CHARACTER_PREFIX if item_data.get("type") == "character" else OBJECT_PREFIX
                prompt = f"{prefix}{item_data['desc']}. {STYLE_SUFFIX}"
                ok = generate_image(prompt, item_path)
                if ok:
                    generated_items.append(item_data['name'])
                    time.sleep(5)
                else:
                    time.sleep(10)
            else:
                generated_items.append(item_data['name'])

        # 2. Generate Background with Item Context
        bg_path = theme_dir / "bg.png"
        if not bg_path.exists():
            # Build a style-matching prompt
            item_list = ", ".join(generated_items[:5]) # Mention first few items for style matching
            bg_prompt = f"{data['scene']}. {STYLE_SUFFIX} The environment should feature natural hiding spots and a color palette that perfectly matches the following objects: {item_list}."
            
            if generate_image(bg_prompt, bg_path, aspect_ratio="16:9", transparent_bg=False):
                time.sleep(5)

def main() -> None:
    parser = argparse.ArgumentParser(description="Generate game assets using Imagen")
    parser.add_argument(
        "--manifest", type=Path,
        help="Flat JSON manifest: array of {output, prompt, aspect_ratio?, transparent_bg?}",
    )
    parser.add_argument("--themes", type=Path, default=HS_THEMES_JSON, help="H&S themes.json path")
    parser.add_argument("--asset-root", type=Path, default=HS_ASSET_ROOT, help="H&S asset output root")
    args = parser.parse_args()

    if args.manifest:
        run_manifest(args.manifest)
    else:
        run_hide_seek(args.themes, args.asset_root)

if __name__ == "__main__":
    main()
