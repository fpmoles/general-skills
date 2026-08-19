---
name: recipe-to-paprika
description: "Use this skill whenever the user asks for a recipe, a meal prep plan, or anything else that results in a recipe (ingredients + directions), regardless of cuisine or dish. Triggers include 'give me a recipe', 'meal prep', 'I want a [dish]', or any request where the deliverable is something someone would cook from. Produces a .paprikarecipes file that imports directly into Paprika Recipe Manager, in addition to (or instead of) a written recipe."
license: Personal use
---

# Recipe → Paprika import

Read `INSTRUCTIONS.md` in this skill's folder and follow it — it's written to be
assistant-agnostic (it's shared with a ChatGPT setup of the same skill; see
`CHATGPT_SETUP.md`), so it talks in terms of "ask the user" / "run the script" / "deliver the
file" rather than naming specific Claude tools. Map those to your actual tools as you go:

- "ask the user" → use AskUserQuestion for the categories question (step 2), since it's a
  concrete multiple-choice-or-custom decision.
- "run the script" → use Bash to run `scripts/build_paprika.py` directly; you have code
  execution, so always do this yourself rather than asking the person to run it.
- "deliver the file" → use SendUserFile.

Everything else — the `recipe.json` schema, when to ask for categories, how to group
ingredients, the format notes — is in `INSTRUCTIONS.md` and applies exactly as written.
