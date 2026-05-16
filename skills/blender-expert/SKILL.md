---
name: blender-expert
description: Use whenever working in Blender or generating bpy Python — operating Blender via MCP, writing bpy code, debugging shader/render/light setups, or producing product visualization. Queries the blender-knowledge and blender-knowledge-user QMD collections for canonical recipes, API references, and gotchas before generating code, and captures teaching events to the user layer.
license: MIT
metadata:
  author: PPMC
  version: "0.1.0"
allowed-tools: Bash(qmd:*), mcp__qmd__*
---

# blender-expert

Companion skill to the `blender-knowledge` corpus. Loads when Claude
is operating Blender (via MCP or generating bpy code).

## When to invoke

Trigger this skill on any of:
- User mentions Blender, bpy, .blend, GLB/glTF, Cycles, Eevee, Geometry
  Nodes, Principled BSDF, HDRI, product viz, 3D render
- User invokes any `mcp__blender-mcp__*` tool (ahujasid MCP or fork)
- User pastes a Python traceback referencing the `bpy` module
- User asks for product photo, hero shot, turntable, or any 3D render

## Two-layer retrieval

Two QMD collections are queried together:

| Collection | Source | When it wins |
|---|---|---|
| `blender-knowledge` | Foundational, public, this repo | Generic case |
| `blender-knowledge-user` | Per-user, private, sibling repo | Overrides foundational on overlap |

Query both. Merge results. User-layer entries with matching topic/tag
beat foundational. Show the user when an override was applied (one
line citation).

### Query pattern

```bash
qmd query "<topic>" -c blender-knowledge
qmd query "<topic>" -c blender-knowledge-user
```

Or via the QMD MCP server when configured — preferred for token-
efficient hybrid (lex + vec + hyde) search.

### Retrieval priority

1. Workflow recipes (`docs/workflows/`) — orchestrating end-to-end docs.
   If a hero-shot or end-to-end workflow matches the user request,
   retrieve that **first** and inline its code. Don't reassemble
   sub-recipes manually.
2. Gotchas (`docs/gotchas/`) — load whenever generating bpy code,
   especially `4x-principled-bsdf-renames` for any Principled BSDF
   manipulation.
3. Recipes by domain (`docs/recipes/material|lighting|camera|render`).
4. API reference (`docs/api/`, when populated) — last resort fallback
   for specific operator signatures.

## Generation rules

- Default to Blender 4.2+ API names. If user explicitly says 3.x, fall
  back to 3.x names — flag the version mismatch.
- Always include the `bsdf is None` safety pattern when accessing
  `mat.node_tree.nodes.get("Principled BSDF")`. Materials may have
  renamed nodes.
- For Eevee transmission materials, always set
  `mat.blend_method = 'HASHED'`. Cycles ignores it.
- For Cycles GPU rendering, always include the device-enable
  boilerplate (`prefs.refresh_devices()`, enable each device). A
  bare `cy.device = 'GPU'` silently falls back to CPU.
- Cite chunks by relative path at end of response when corpus content
  shaped the output.

## Learning capture — write to user layer

During a session, watch for **teaching events** and propose persistence
to the user layer:

| Trigger phrase / event | Persist to |
|---|---|
| "I always use X" / "I prefer Y" | `docs/preferences/` |
| "Use these values for this material" | `docs/recipes/material/` |
| User demonstrates a workflow you didn't know | `docs/workflows/` |
| User corrects your code with a working fix | `docs/gotchas/` if generic, `docs/recipes/` if recipe-shaped |
| User defines a reusable custom asset/material | `docs/assets/` |
| Per-project / per-client convention | `docs/workflows/` tagged with project |

### Capture protocol

1. **Quote back** the learned content in one sentence.
2. **Propose** filename + tags + frontmatter. Use `extends:
   <foundational-path>` if it overrides or augments a foundational
   doc.
3. **Confirm** with user. Never silently persist long-term memory of
   a misunderstanding.
4. **Write** the file. Frontmatter required:

```yaml
---
title: <short title>
tags: [<tag>, <tag>, ...]
when_to_consult: <one-sentence trigger>
blender_version: "4.2+ | 5.x | etc."
source_session: YYYY-MM-DD
extends: <foundational/path/doc.md>   # if applicable
extends_reviewed: YYYY-MM-DD          # if extends is set
last_reviewed: YYYY-MM-DD
---
```

5. **Optionally commit** the user-layer repo. The user-layer is its
   own git repo. Commits stay local unless the user pushes.
6. After writing, run `qmd update` (or `./scripts/setup.sh` in the
   user-layer repo) so the new chunk is searchable next turn.

### When NOT to capture

- One-off fix unlikely to recur
- User explicitly says "just this once"
- Content is foundational-quality (universally applicable) — propose
  a PR to the foundational repo instead, not the user layer

## Foundational PR path

If the user teaches something genuinely generic (applies to any
product-viz user, not just their projects), propose a PR to the
foundational `blender-knowledge` repo. Use:

```bash
cd ~/Documents/GitHub/blender-knowledge
git checkout -b feature/<descriptive-slug>
# write doc to appropriate docs/ subdir with full frontmatter
git add -A && git commit -m "..."
gh pr create --base main
```

## Citations

When corpus content shapes output, cite the chunk paths at the end
of the response:

```
— sourced from blender-knowledge: docs/recipes/material/glass-pbr.md,
  docs/gotchas/4x-principled-bsdf-renames.md
```

This helps the user verify and notice when retrieval is missing or
out of date.
