# Recipe → Paprika import (assistant-agnostic instructions)

These instructions work the same regardless of which AI assistant is following them — Claude,
ChatGPT, or anything else that can hold a conversation and either run a Python script itself
or ask a person to run one. Nothing here depends on a specific vendor's tools.

## When this applies

Any time someone asks for a recipe, a meal prep plan, or anything else where the deliverable
is something to cook — not just written out, but also turned into a file that imports
directly into Paprika Recipe Manager.

## Steps

1. **Clarify the recipe itself first**, the way you normally would: servings, dietary
   constraints, flavor direction, any format preferences.
2. **Before building the import file, ask what Paprika categories to apply.** Do this every
   time — don't reuse categories from an earlier recipe without asking again. Offer a couple
   of suggestions drawn from the dish itself (e.g. "Meal Prep", "High Protein", a cuisine
   type, "Weeknight") as a starting point, but let the person choose or override.
3. **Write the recipe into a `recipe.json` file** matching this schema (all fields optional
   except `name`, `ingredients`, `directions`):

   ```json
   {
     "name": "Recipe Name",
     "servings": "4",
     "prep_time": "20 min",
     "cook_time": "20 min",
     "total_time": "40 min",
     "categories": ["Category One", "Category Two"],
     "description": "One or two sentence summary.",
     "ingredients": "Section Header:\n1 cup thing\n\nAnother Section:\n2 tbsp thing",
     "directions": "1. Step one.\n\n2. Step two.",
     "notes": "Storage, reheating, swaps, etc.",
     "nutritional_info": "Per serving (approx.): 500 calories, 40g protein, ..."
   }
   ```

   - Group `ingredients` into shopping-list sections using plain header lines with no
     leading quantity (e.g. `Produce:`) — Paprika renders these as bold section headers.
   - Number `directions` steps manually (`1. ...`, `2. ...`), separated by blank lines.
   - If nutrition wasn't given, estimate it from standard ingredient data and say so in
     `nutritional_info`.
   - Match ingredient quantities to how things are actually sold when told (e.g. "ground
     chicken comes in 1 lb packages") rather than a mathematically rounder number.

4. **Run `scripts/build_paprika.py`** against that `recipe.json`:

   ```
   python build_paprika.py recipe.json "<Recipe Name>.paprikarecipes"
   ```

   The script validates required fields and round-trips the output (decompresses it and
   re-parses the JSON) to confirm the file is well-formed before you hand it over — check its
   printed summary.

   - If you (the assistant) can execute code yourself, do this step directly and hand back
     the finished `.paprikarecipes` file.
   - If you can't execute code, give the person the `recipe.json` content in a code block and
     the exact command above, so they can run it themselves in any terminal with Python 3
     installed (no extra libraries needed — it's pure standard library).

5. **Deliver the file** and mention that it opens directly in Paprika — double-click on
   Mac/Windows, or File → Import; tap to open on iOS/Android.
6. If a written/printable version is also wanted (Word doc, plain text, etc.), build it from
   the same `recipe.json` content so quantities and instructions don't drift between the two.

## Format notes (why the file looks the way it does)

- The container extension matters: **singular** `.paprikarecipe` is a gzip-compressed JSON
  blob for one recipe; **plural** `.paprikarecipes` is a plain ZIP archive containing one or
  more `.paprikarecipe` entries. Paprika's importer expects the plural/ZIP form — that's what
  `build_paprika.py` produces.
- This is a reverse-engineered format (Paprika hasn't published an official spec), but it's
  stable and widely used by other import tools.
