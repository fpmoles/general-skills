# general-skills

A personal collection of reusable AI skills and agents — not focused on development — that
get loaded automatically when a matching task comes up in conversation. Mirrors the install
mechanism of [`dev-pack`](https://github.com/fpmoles/dev-pack), minus the parts that repo
needs and this one doesn't (no scripts, no templates, no install modes): one folder per
skill/agent, copied into place by `install.sh`.

Skills here are written to work with more than one assistant where practical. The actual
logic lives in an assistant-agnostic `INSTRUCTIONS.md` (plain prose, no vendor-specific tool
names) plus any plain scripts it calls out to; each assistant gets a thin wrapper on top —
`SKILL.md` for Claude, `CHATGPT_SETUP.md` for ChatGPT. That way behavior can't drift between
assistants, since there's only one copy of the actual logic.

## Layout

```
general-skills/
  README.md
  install.sh
  uninstall.sh
  skills/
    <skill-name>/
      SKILL.md              # Claude wrapper: frontmatter + how to map INSTRUCTIONS.md to Claude's tools
      INSTRUCTIONS.md        # the actual logic, assistant-agnostic
      CHATGPT_SETUP.md       # optional: how to load INSTRUCTIONS.md into a ChatGPT Project or Custom GPT
      scripts/                # optional: plain scripts (no AI-vendor dependencies) the instructions call out to
  agents/
    <agent-name>/
      AGENT.md               # tool-agnostic agent definition
```

## Installation

1. Clone this repository.
2. Run the install script:
   ```bash
   cd general-skills
   ./install.sh
   ```

The installer copies every folder under `skills/` and `agents/` into each AI tool's expected
directory: `~/.claude`, `~/.codex`, `~/.copilot`, and (skills only) `~/.agents`. It tracks what
it installs in a manifest at `~/.general-skills/manifest/`, so re-running `install.sh` is safe
at any time — it cleans up anything removed from the repo and syncs anything new.

It'll also offer to enable this repo's tracked git hooks (`.github/hooks/`) via
`core.hooksPath`: `pre-commit`, `post-merge` (after `git pull`), and `pre-push` — all three
re-run `install.sh` to keep your local install in sync automatically.

Run `./uninstall.sh` to remove everything the installer placed on your machine.

ChatGPT setup (where a skill has a `CHATGPT_SETUP.md`) is manual — paste `INSTRUCTIONS.md`
into a ChatGPT Project or Custom GPT as described in that file.

## Skills in this repo

| Skill | Triggers on | What it does |
|---|---|---|
| `recipe-to-paprika` | Any request for a recipe | Asks which Paprika categories to apply, then builds a `.paprikarecipes` file ready to import into Paprika Recipe Manager. Works with Claude (automatic) or ChatGPT (Project/Custom GPT setup, see its `CHATGPT_SETUP.md`) |

## Agents in this repo

None yet.

## Adding a new skill

1. Write `skills/<skill-name>/INSTRUCTIONS.md` first — the actual logic, in plain language,
   with no assistant-specific tool names ("ask the user", "run the script", "deliver the
   file" rather than naming a specific tool call).
2. Add any helper scripts under `skills/<skill-name>/scripts/` — keep them dependency-free
   where possible so any assistant's code execution (or a person, manually) can run them.
3. Add `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`) that
   points at `INSTRUCTIONS.md` and maps its generic steps to Claude's actual tools. Keep the
   `description` specific — it's what Claude matches against to decide when to load the
   skill.
4. If it's useful in ChatGPT too, add `skills/<skill-name>/CHATGPT_SETUP.md` with setup steps
   for a Project or Custom GPT.
5. Run `./install.sh` to pick up the new skill, and update the table above.

## Adding a new agent

1. Add `agents/<agent-name>/AGENT.md` — a tool-agnostic agent definition.
2. Run `./install.sh` to pick up the new agent, and update the table above.
