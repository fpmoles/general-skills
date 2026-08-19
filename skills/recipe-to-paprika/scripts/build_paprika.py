#!/usr/bin/env python3
"""
Build a .paprikarecipes import file from a recipe JSON description.

Usage:
    python build_paprika.py recipe.json "Output Name.paprikarecipes"

recipe.json schema (all fields optional except name/ingredients/directions):
{
  "name": "Recipe Name",
  "servings": "4",
  "difficulty": "",
  "prep_time": "20 min",
  "cook_time": "20 min",
  "total_time": "40 min",
  "source": "",
  "source_url": "",
  "description": "One or two sentence summary.",
  "categories": ["Category One", "Category Two"],
  "ingredients": "Section Header:\n1 cup thing\n...\n\nAnother Section:\n2 tbsp thing",
  "directions": "1. Step one.\n\n2. Step two.",
  "notes": "Storage, reheating, swaps, etc.",
  "nutritional_info": "Per serving (approx.): 500 calories, 40g protein, ..."
}

Notes on the Paprika format (reverse-engineered, not officially documented):
  - A .paprikarecipe (singular) file is a gzip-compressed UTF-8 JSON blob describing one recipe.
  - A .paprikarecipes (plural) file is a normal ZIP archive containing one or more
    .paprikarecipe entries. This is what Paprika's Import expects.
  - Ingredient lines that don't look like "<qty> <item>" (e.g. "Produce:") render as bold
    section headers in the Paprika UI — use that to group ingredients like a shopping list.
  - Directions is just a single string; number steps manually if you want numbered steps,
    separated by blank lines for readability.
"""

import argparse
import datetime
import gzip
import hashlib
import io
import json
import sys
import uuid
import zipfile


DEFAULTS = {
    "uid": None,  # generated below if not provided
    "servings": "",
    "difficulty": "",
    "prep_time": "",
    "cook_time": "",
    "total_time": "",
    "rating": 0,
    "source": "",
    "source_url": "",
    "image_url": None,
    "photo": None,
    "photo_large": None,
    "photo_hash": None,
    "photo_data": None,
    "photo_url": None,
    "in_trash": False,
    "on_favorites": False,
    "scale": None,
    "categories": [],
    "description": "",
    "notes": "",
    "nutritional_info": "",
}


def build_recipe(data: dict) -> dict:
    recipe = dict(DEFAULTS)
    recipe.update(data)
    recipe["uid"] = recipe.get("uid") or str(uuid.uuid4())
    recipe["created"] = recipe.get("created") or datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    for required in ("name", "ingredients", "directions"):
        if not recipe.get(required):
            raise ValueError(f"recipe.json is missing required field: {required}")

    recipe["hash"] = hashlib.sha256(
        json.dumps(recipe, sort_keys=True).encode("utf-8")
    ).hexdigest()
    return recipe


def write_paprikarecipes(recipe: dict, out_path: str) -> None:
    inner_name = recipe["name"].strip()
    if not inner_name.lower().endswith(".paprikarecipe"):
        inner_name += ".paprikarecipe"

    recipe_json = json.dumps(recipe, ensure_ascii=False).encode("utf-8")

    gz_bytes = io.BytesIO()
    with gzip.GzipFile(fileobj=gz_bytes, mode="wb", filename=inner_name) as gz:
        gz.write(recipe_json)
    gz_bytes.seek(0)

    if not out_path.lower().endswith(".paprikarecipes"):
        out_path += ".paprikarecipes"

    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr(inner_name, gz_bytes.read())


def verify(out_path: str) -> dict:
    """Round-trip the file to make sure Paprika will be able to read it back."""
    zf = zipfile.ZipFile(out_path)
    inner = zf.namelist()[0]
    decompressed = gzip.decompress(zf.read(inner))
    return json.loads(decompressed)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("recipe_json", help="Path to a recipe.json file matching the schema above")
    parser.add_argument("output", help="Output path, e.g. 'My Recipe.paprikarecipes'")
    args = parser.parse_args()

    with open(args.recipe_json, "r", encoding="utf-8") as f:
        data = json.load(f)

    recipe = build_recipe(data)
    write_paprikarecipes(recipe, args.output)

    out_path = args.output if args.output.lower().endswith(".paprikarecipes") else args.output + ".paprikarecipes"
    check = verify(out_path)
    assert check["name"] == recipe["name"], "round-trip verification failed"

    print(f"Wrote {out_path}")
    print(f"  name: {check['name']}")
    print(f"  servings: {check.get('servings')}")
    print(f"  categories: {check.get('categories')}")


if __name__ == "__main__":
    main()
