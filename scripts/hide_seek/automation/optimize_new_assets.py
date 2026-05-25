#!/usr/bin/env python3
import subprocess
import os
import sys
from pathlib import Path

# Configuration
ASSET_ROOT = Path("assets/sprites/hide_seek")
RESOURCES_ROOT = Path("resources/hide_seek")
QUALITY = "90"

def optimize_directory(target_dir):
    """Converts all PNGs in a directory to WebP and updates Godot imports."""
    png_files = list(target_dir.rglob("*.png"))
    if not png_files:
        print(f"No PNG files found in {target_dir}")
        return
    
    print(f"Found {len(png_files)} PNG files to convert to WebP.")
    
    for img_path in png_files:
        webp_path = img_path.with_suffix(".webp")
        print(f"  Optimizing: {img_path.name} -> {webp_path.name}")
        
        # 1. Convert to WebP
        subprocess.run(["cwebp", "-q", QUALITY, str(img_path), "-o", str(webp_path)], check=True, capture_output=True)
        
        # 2. Create Godot .import file (Lossless mode to prevent PCK bloat)
        webp_import_path = webp_path.parent / (webp_path.name + ".import")
        import_content = f"""[remap]
importer="texture"
type="CompressedTexture2D"

[deps]
source_file="res://{webp_path}"

[params]
compress/mode=0
process/fix_alpha_border=true
"""
        with open(webp_import_path, "w") as f:
            f.write(import_content)
            
        # 3. Cleanup original PNG and its import file
        img_path.unlink()
        old_import = img_path.parent / (img_path.name + ".import")
        if old_import.exists():
            old_import.unlink()

    # 4. Update all .tres files to point to the new .webp paths
    update_tres_paths(target_dir)

def update_tres_paths(asset_dir):
    """Surgically updates .tres files to point to .webp instead of .png."""
    print("Updating resource path references...")
    
    # Map of old png paths to new webp paths
    # We only care about assets that were just converted in asset_dir
    webp_files = list(asset_dir.rglob("*.webp"))
    replacements = {}
    for webp in webp_files:
        png_path = webp.with_suffix(".png")
        replacements[f"res://{png_path}"] = f"res://{webp}"

    count = 0
    for tres_file in RESOURCES_ROOT.rglob("*.tres"):
        with open(tres_file, "r") as f:
            content = f.read()
        
        original_content = content
        for old, new in replacements.items():
            content = content.replace(old, new)
            
        if content != original_content:
            with open(tres_file, "w") as f:
                f.write(content)
            count += 1
            
    print(f"  Updated {count} .tres files.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # User passed specific theme or file
        for arg in sys.argv[1:]:
            p = Path(arg)
            if not p.exists():
                p = ASSET_ROOT / arg
            
            if p.exists():
                optimize_directory(p if p.is_dir() else p.parent)
    else:
        # Run on everything in hide_seek
        optimize_directory(ASSET_ROOT)
