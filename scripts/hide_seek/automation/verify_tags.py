"""
Validates that every item in every theme has at least one anchor with a matching tag.
This version parses the Godot .tres resources directly, ensuring manual edits in
the editor are respected.

Run from the project root: python scripts/hide_seek/automation/verify_tags.py
"""

import re
import sys
from pathlib import Path

RESOURCES_ROOT = Path("resources/hide_seek")

def parse_tres(path: Path):
    """
    Surgically parses a .tres file for anchors and items.
    Returns (anchors, items) where each is a list of dicts with 'name' and 'tags'.
    """
    content = path.read_text()
    
    # 1. Extract Anchors
    # Matches sub_resources with hide_seek_anchor script (ExtResource("1_rrvu8"))
    # We look for the tags array.
    anchors = []
    anchor_blocks = re.findall(r'\[sub_resource.*?script = ExtResource\("1_rrvu8"\).*?tags = Array\[String\]\(\[(.*?)\]\)', content, re.DOTALL)
    for tags_str in anchor_blocks:
        tags = [t.strip().strip('"') for t in tags_str.split(',') if t.strip()]
        anchors.append({"tags": tags})

    # 2. Extract Items
    # Matches sub_resources with hide_seek_item_data script (ExtResource("3_fy28n"))
    items = []
    item_blocks = re.findall(r'\[sub_resource.*?script = ExtResource\("3_fy28n"\).*?item_name = "(.*?)".*?tags = Array\[String\]\(\[(.*?)\]\)', content, re.DOTALL)
    for name, tags_str in item_blocks:
        tags = [t.strip().strip('"') for t in tags_str.split(',') if t.strip()]
        items.append({"name": name, "tags": tags})
        
    return anchors, items

def main():
    if not RESOURCES_ROOT.exists():
        print(f"ERROR: Resources directory not found: {RESOURCES_ROOT}")
        sys.exit(1)

    errors = []
    scenes_checked = 0
    items_total = 0

    # Iterate through all main scene .tres files
    for tres_path in RESOURCES_ROOT.glob("*.tres"):
        if tres_path.name == "mountains.tres.bak": continue
        
        scenes_checked += 1
        scene_name = tres_path.stem
        anchors, items = parse_tres(tres_path)
        items_total += len(items)

        # Build a set of all tags available on anchors in this scene
        anchor_tag_set = set()
        for a in anchors:
            for tag in a["tags"]:
                anchor_tag_set.add(tag)

        # Check each item
        for item in items:
            if not item["tags"]:
                errors.append(f"[{scene_name}] '{item['name']}' has no tags assigned")
                continue
            
            if not any(t in anchor_tag_set for t in item["tags"]):
                errors.append(
                    f"[{scene_name}] '{item['name']}' tags {item['tags']} match no anchor "
                    f"(scene has: {sorted(anchor_tag_set) if anchor_tag_set else 'NO TAGGED ANCHORS'})"
                )

    if errors:
        print(f"TAG VALIDATION FAILED — {len(errors)} error(s) in {scenes_checked} scenes:\n")
        for e in errors:
            print(f"  {e}")
        sys.exit(1)

    print(f"OK — {scenes_checked} scene(s), {items_total} item(s) validated via .tres resources.")

if __name__ == "__main__":
    main()
