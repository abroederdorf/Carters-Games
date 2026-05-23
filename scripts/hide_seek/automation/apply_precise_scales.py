import re
import json
from pathlib import Path

# Paths
TRES_PATH = Path("resources/hide_seek/pet_shop.tres")
ITEM_RESOURCES_DIR = Path("resources/hide_seek/pet_shop")
ITEM_TAGS_PATH = Path("assets/data/hide_seek/item_tags.json")

def update_tres_scales():
    # Load scales from item_tags.json
    with open(ITEM_TAGS_PATH, "r") as f:
        scales_data = json.load(f)["pet_shop"]
    
    # Update main scene manifest (pet_shop.tres)
    if TRES_PATH.exists():
        content = TRES_PATH.read_text()
        
        # Split into blocks
        blocks = re.split(r'(\[sub_resource)', content)
        new_blocks = [blocks[0]]
        
        for i in range(1, len(blocks), 2):
            header = blocks[i]
            body = blocks[i+1]
            
            # Check if this block is an item resource
            name_match = re.search(r'item_name = "(.*?)"', body)
            if name_match:
                item_name = name_match.group(1)
                if item_name in scales_data:
                    new_scale = scales_data[item_name]["base_scale"]
                    # Replace base_scale
                    body = re.sub(r'base_scale = \d+\.\d+', f'base_scale = {new_scale}', body)
            
            new_blocks.append(header)
            new_blocks.append(body)
        
        TRES_PATH.write_text("".join(new_blocks))
        print(f"Updated {TRES_PATH} with precise scales.")

    # Update individual item resources
    for item_path in ITEM_RESOURCES_DIR.glob("*.tres"):
        content = item_path.read_text()
        name_match = re.search(r'item_name = "(.*?)"', content)
        if name_match:
            item_name = name_match.group(1)
            if item_name in scales_data:
                new_scale = scales_data[item_name]["base_scale"]
                content = re.sub(r'base_scale = \d+\.\d+', f'base_scale = {new_scale}', content)
                item_path.write_text(content)
                print(f"  Updated {item_path.name}")

if __name__ == "__main__":
    update_tres_scales()
