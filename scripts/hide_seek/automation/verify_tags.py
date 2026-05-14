"""
Validates that every item in every theme has at least one anchor with a matching tag.
Run from the project root: python scripts/hide_seek/automation/verify_tags.py
Exit code 1 if any errors are found.
"""

import json
import sys
from pathlib import Path

ANCHORS_JSON = Path("assets/data/hide_seek/anchors_data.json")
TAGS_JSON = Path("assets/data/hide_seek/item_tags.json")


def load(path: Path) -> dict:
    if not path.exists():
        print(f"ERROR: File not found: {path}")
        sys.exit(1)
    with open(path) as f:
        return json.load(f)


def main():
    anchors_data = load(ANCHORS_JSON)
    item_tags = load(TAGS_JSON)

    errors = []

    for theme, items in item_tags.items():
        if theme not in anchors_data:
            errors.append(f"[{theme}] No anchor data — run map_anchors.py first")
            continue

        anchor_tag_set = set()
        for anchor in anchors_data[theme]:
            for tag in anchor.get("tags", []):
                anchor_tag_set.add(tag)

        for item_name, item_info in items.items():
            if isinstance(item_info, list):
                tags = item_info
            elif isinstance(item_info, dict):
                tags = item_info.get("tags", [])
            else:
                continue

            if not tags:
                errors.append(f"[{theme}] '{item_name}' has no tags assigned")
                continue

            if not any(t in anchor_tag_set for t in tags):
                errors.append(
                    f"[{theme}] '{item_name}' tags {tags} match no anchor "
                    f"(scene has: {sorted(anchor_tag_set)})"
                )

    if errors:
        print(f"TAG VALIDATION FAILED — {len(errors)} error(s):\n")
        for e in errors:
            print(f"  {e}")
        sys.exit(1)

    themes_checked = len(item_tags)
    items_checked = sum(len(v) for v in item_tags.values())
    print(f"OK — {themes_checked} theme(s), {items_checked} item(s) validated.")


if __name__ == "__main__":
    main()
