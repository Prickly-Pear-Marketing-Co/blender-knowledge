# blender-knowledge

A curated Blender knowledge corpus indexed by [QMD](https://github.com/tobi/qmd)
so Claude can look up Blender-specific guidance on demand without
paying global context cost.

Scoped to **product visualization and short commercial 3D video**.
See `CLAUDE.md` for the scope rationale.

Contents are written **for Claude to read**, not for humans, though
humans can skim them. The Claude harness queries this collection via
the QMD MCP server.

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

## License

Recipes and gotchas: written here, MIT.
Ingested manual/API content: derived from Blender's CC-BY-SA / GPL
docs. Attribution preserved per-chunk.
