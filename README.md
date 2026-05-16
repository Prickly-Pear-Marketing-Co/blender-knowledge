# blender-knowledge

A curated Blender knowledge corpus indexed by [QMD](https://github.com/tobi/qmd)
so Claude (or Gemini, or any LLM with a QMD client) can look up
Blender-specific guidance on demand without paying global context
cost.

Scoped to **product visualization and short commercial 3D video**.
See `CLAUDE.md` for the scope rationale.

Contents are written **for an LLM to read**, not for humans, though
humans can skim them. The corpus is queried via the QMD MCP server
or the `qmd` CLI.

## Prerequisites

| Requirement | Why | Install |
|---|---|---|
| Node.js 20+ | QMD runtime | `brew install node` or [fnm](https://github.com/Schniz/fnm) |
| `@tobilu/qmd` ≥ 2.1.0 | Indexing + retrieval | `npm install -g @tobilu/qmd` |
| Blender 4.2+ | Target tool | https://www.blender.org/download/ |
| Blender MCP addon | LLM-to-Blender bridge | https://github.com/ahujasid/blender-mcp or paid alternatives (see `dev/RESEARCH.md`) |
| Claude Desktop or compatible harness | Tool-using LLM client | https://claude.ai/download |

Optional but recommended:

| Requirement | Why |
|---|---|
| `gh` CLI | Filing PRs to foundational, managing user-layer remote |
| QMD MCP server | Better retrieval than CLI; lets Claude search inline |

### Local setup tweaks

1. **Disable broad QMD collections that scan your home dir.** A
   `seth`-style collection rooted at `$HOME` or one rooted at
   `~/Documents/GitHub` (parent) will trip QMD's handelize bug on
   files like Nuxt routes `[...].ts`, Apple Notes with emoji
   filenames, etc. See QMD issue
   [#56](https://github.com/tobi/qmd/issues/56). Use repo-specific
   collections only.
2. **Enable a GPU device for Cycles** in your Blender install once,
   in Preferences → System → Cycles Render Devices. The corpus
   includes the programmatic enable boilerplate for cold-start
   sessions, but a one-time UI enable is faster for daily use.
3. **Install the Blender MCP addon** in your Blender. Open Blender →
   Edit → Preferences → Add-ons → drag-and-drop the
   [ahujasid addon](https://github.com/ahujasid/blender-mcp).
   Activate, then connect from the N-panel sidebar under "BlenderMCP".

## Quick start

```bash
# 1. Clone this repo
git clone https://github.com/Prickly-Pear-Marketing-Co/blender-knowledge.git
cd blender-knowledge

# 2. Register the QMD collection (one-time)
./scripts/setup.sh

# 3. (Optional) Set up your personal user-layer repo
./scripts/init-user-layer.sh

# 4. (Optional) Install the blender-expert skill so Claude uses
#    the corpus automatically
mkdir -p ~/.claude/skills
ln -s "$(pwd)/skills/blender-expert" ~/.claude/skills/blender-expert
```

After step 2, query from any shell:

```bash
qmd query "glass material pbr"           -c blender-knowledge
qmd query "studio lighting product"      -c blender-knowledge
qmd query "Cycles settings glass"        -c blender-knowledge
qmd query "Transmission KeyError"        -c blender-knowledge
qmd query "hero shot end to end"         -c blender-knowledge
```

After step 4, Claude will retrieve from this corpus automatically
during any Blender-related session.

## Usage for an LLM session

The intended flow when an LLM is asked to do a Blender task:

1. **Recognize the task** is Blender-related (the `blender-expert`
   skill auto-loads, or the LLM should query QMD voluntarily).
2. **Retrieve relevant chunks** by topic from both the foundational
   collection and the user-layer collection:
   ```bash
   qmd query "<task topic>" -c blender-knowledge
   qmd query "<task topic>" -c blender-knowledge-user
   ```
3. **Use the chunks as authoritative context.** They preempt common
   mistakes. The hero-shot workflow (`docs/workflows/`) is the
   single best entry point for "make a product render"-style
   requests — it inlines material, lighting, camera, and render
   in one orchestrated function.
4. **Generate bpy code** that respects the corpus's 4.x-name
   conventions and Eevee/Cycles gotchas.
5. **On teaching events**, propose a write to the user-layer repo.
   See `PERSONALIZATION.md` and `skills/blender-expert/SKILL.md` for
   the capture protocol.
6. **Cite chunks** used in the final response so the user can verify
   and edit the source.

## Structure

- `docs/api/` — One doc per `bpy` operator or function. Signature,
  parameters, return type, minimal usage example, version notes.
- `docs/recipes/` — Task-oriented workflow snippets.
  - `lighting/` — 3-point setups, HDRI rigs, area-light softboxes
  - `material/` — PBR recipes (glass, metal, plastic, fabric, etc.)
  - `camera/` — Composition, DOF, focal length, sensor framing
  - `render/` — Cycles / Eevee settings for product viz
  - `modeling/` — Hard-surface patterns, modifier stacks
  - `compositing/` — Glare, lens distortion, color grading basics
- `docs/gotchas/` — Version drift, recurring traps, API renames
- `docs/workflows/` — Multi-step end-to-end flows (e.g., "full studio
  hero shot from blank scene")
- `eval/` — Eval task list and run outputs

## Adding a doc

Every doc starts with YAML frontmatter:

```yaml
---
title: <short title>
tags: [<tag>, <tag>, ...]
when_to_consult: <one-sentence trigger>
blender_version: "4.2+ | 5.x | 4.x-only"
last_reviewed: YYYY-MM-DD
---
```

Then markdown. Be specific. Reference exact operators, property
paths, and Blender version. Avoid pasting external content
verbatim — re-author and cite source URL.

## Bootstrap

```bash
./scripts/setup.sh
```

Registers `docs/` as the `blender-knowledge` QMD collection and runs
`qmd embed`.

## Query

```bash
qmd query "<topic>" -c blender-knowledge
qmd query "<topic>" -c blender-knowledge --files --min-score 0.3
```

## Ingestion pipelines (planned, see scripts/)

- `ingest_manual.py` — clone `projects.blender.org/blender/blender-manual`,
  parse RST, emit chunks under `docs/api/` and `docs/workflows/` for
  in-scope sections only.
- `ingest_api.py` — scrape `docs.blender.org/api/current/`, emit one
  chunk per operator under `docs/api/`.
- `eval_runner.py` — execute `eval/tasks.md` scenarios via Claude+MCP,
  score completion, render quality, token cost, iteration count.

Initial chunks for v1 are hand-authored under `docs/recipes/` and
`docs/gotchas/` to prove pattern + retrieval before bulk ingestion.

## Personalization (user layer)

This repo is the **foundational** corpus. Each user can have a sibling
`blender-knowledge-user` repo for personal preferences, project-
specific workflows, custom assets, and corrections learned over time.
Both layers queried together; user layer wins on overlap.

Set up the user layer:

```bash
./scripts/init-user-layer.sh
```

See `PERSONALIZATION.md` for the full design.

## Project state and roadmap

This corpus is one part of a multi-part project. Project state lives
in `dev/`:

- `dev/STATUS.md` — what's done, what's broken, current state
- `dev/ROADMAP.md` — phased plan across tracks (KB, harness, skills)
- `dev/RESEARCH.md` — research findings, sources, decisions log

## License

Recipes and gotchas: written here, MIT.
Ingested manual/API content: derived from Blender's CC-BY-SA / GPL
docs. Attribution preserved per-chunk.
