# Using this skill in ChatGPT

The instructions in `INSTRUCTIONS.md` and the script in `scripts/build_paprika.py` aren't
Claude-specific, so you can set the same behavior up in ChatGPT. Exact menu names below are
current as of mid-2026 and OpenAI moves things around, so if something's labeled slightly
differently, look for the closest equivalent.

## Setup (ChatGPT Projects)

1. In ChatGPT, create a new **Project**.
2. Open **Project instructions** and paste in the full contents of `INSTRUCTIONS.md`.
3. Add `scripts/build_paprika.py` to the project's files.
4. Start a chat inside the project and ask for a recipe as usual. Every conversation in the
   project inherits the instructions and has the script available.

## If ChatGPT can run the script for you

If code execution (sometimes called Code Interpreter / Advanced Data Analysis) is enabled for
your plan and turned on, ChatGPT can write `recipe.json`, run `build_paprika.py` against it,
and hand you the finished `.paprikarecipes` file directly in the chat — same end-to-end
experience as with Claude.

## If it can't (or you're not sure)

Ask for the recipe as normal. ChatGPT will still ask about categories and produce the
`recipe.json` content in a code block, plus the exact command to run. Save that block as
`recipe.json` next to `build_paprika.py` and run:

```
python build_paprika.py recipe.json "Recipe Name.paprikarecipes"
```

Any machine with Python 3 works — the script has no dependencies outside the standard
library. This also works as a manual fallback for any other assistant that can't execute code
itself.

## Custom GPTs (alternative to Projects)

The same instructions and file also work as a **Custom GPT**: paste `INSTRUCTIONS.md` into
the GPT's instructions field, upload `build_paprika.py` as a knowledge file, and enable the
Code Interpreter capability in the GPT's configuration if you want it to run the script
itself rather than handing you the command.
