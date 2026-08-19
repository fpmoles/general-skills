# Agents

Tool-agnostic AI agents, one per subdirectory. Empty for now — see "Adding a new agent" in
the top-level README.

```
agents/
  <agent-name>/
    AGENT.md   ← required entrypoint, tool-agnostic
```

`install.sh` copies each agent directory here into `~/.claude/agents`, `~/.codex/agents`, and
`~/.copilot/agents`.
