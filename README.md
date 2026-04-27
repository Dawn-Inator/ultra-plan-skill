# ultra-plan-skill

A portable skill for planning **large-scale, multi-module architectures** in
Claude Code and OpenAI Codex.

When a feature spans 5–15 modules and a single planning document would explode,
`ultra-plan` runs a 5-phase workflow that produces a *folder* of markdowns:
one global plan + one per module. Hand the folder to a fresh AI session and
let it execute module-by-module without losing the big picture.

This repo ships **two parallel versions** — one tuned for Claude Code (`Skill`
tool, `AskUserQuestion`), one tuned for Codex (`spawn_agent`,
`request_user_input`, 8-section module template). Pick the one matching your
client.

## When to use

- Architecture work spanning 5+ modules
- Cross-stack features (frontend + backend + AI service)
- Anything that needs more than one AI session to execute
- User says "ultra-plan", "/ultra-plan", "整套", "全套架构"

## When NOT to use

- Single-file fixes, single-module features, bug fixes
- Routine refactors → use a normal `/plan` (Claude) or Plan Mode (Codex)

---

## Install

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/Dawn-Inator/ultra-plan-skill/main/scripts/install.sh | bash -s claude

# Codex
curl -fsSL https://raw.githubusercontent.com/Dawn-Inator/ultra-plan-skill/main/scripts/install.sh | bash -s codex
```

Then trigger it in your AI client with `/ultra-plan <your large feature>`.

**Update**: re-run the same command. **Uninstall**: `rm -rf ~/.claude/skills/ultra-plan` (or `~/.codex/skills/ultra-plan`).

<details>
<summary>Prefer manual install?</summary>

```bash
git clone --depth 1 https://github.com/Dawn-Inator/ultra-plan-skill.git /tmp/ups
cp -R /tmp/ups/claude ~/.claude/skills/ultra-plan   # or codex → ~/.codex/skills/ultra-plan
rm -rf /tmp/ups
```

Or read [scripts/install.sh](scripts/install.sh) before running.

</details>

---

## The 5 phases

| Phase | What happens |
|---|---|
| 0 — Project probe | Reads `CLAUDE.md` / `AGENTS.md` / `.cursorrules` / `.github/copilot-instructions.md` and asks scope-clarifying questions |
| 1 — Parallel research | Dispatches 5–15 read-only subagents in parallel |
| 2 — Decomposition | Splits the feature into modules + a dependency graph |
| 3 — Document | Writes one global plan + one md per module (7 sections on Claude, 8 on Codex) |
| 4 — Execution decision | Asks the user how to execute (new window, inline, or stop) |
| 5 — Optional execution | Runs each module via subagent-driven-development |

## Platform differences (`claude/` vs `codex/`)

| Topic | `claude/` version | `codex/` version |
|---|---|---|
| Project config priority | `CLAUDE.md` first | `AGENTS.md` first |
| User-input tool | `AskUserQuestion` | `request_user_input` |
| Subagent dispatch | `general-purpose` subagent | `spawn_agent` (`worker` / `explorer`) |
| Module template | 7 sections | 8 sections |

Both versions are kept in sync structurally — only the platform-specific
verbs differ.

## Recommended companion skills

Works standalone, but cross-references prompt patterns from these
[superpowers](https://github.com/obra/superpowers) skills:

- `superpowers:dispatching-parallel-agents` — Phase 1 dispatch templates
- `superpowers:subagent-driven-development` — Phase 5 executor / reviewer
- `superpowers:writing-plans` — Plan-quality principles (No Placeholders, etc.)
- `superpowers:writing-skills` — For maintaining this skill itself
- `superpowers:systematic-debugging` — Bug-routing branch in Phase 0

## License

MIT — see [LICENSE](LICENSE).
