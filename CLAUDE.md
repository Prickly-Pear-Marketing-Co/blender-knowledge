# Context for Claude

This repo is a curated Blender knowledge corpus consumed by Claude via
QMD. Scoped to **product visualization and short commercial 3D video** —
not full Blender coverage.

Purpose: close the bpy API knowledge gap and provide reusable workflow
recipes so Claude generates correct, version-appropriate Blender code
without hallucinating operators or shader properties.

## Session pickup — read these first

This is a multi-track project. On any new session:

1. **`dev/STATUS.md`** — current state: what's done, what's broken, where things live, open decisions
2. **`dev/ROADMAP.md`** — 6-phase plan across Tracks A (corpus), B (streaming harness), C (user-layer)
3. **`dev/RESEARCH.md`** — failure-mode taxonomy, BlenderRAG findings, Gemini Live vs Claude, pi.dev rationale, sources
4. `PERSONALIZATION.md` — two-layer KB design (this repo + per-user sibling)
5. `skills/blender-expert/SKILL.md` — Claude behavior during Blender sessions

Default next action per roadmap: **Phase 1 — build `scripts/eval_runner.py`** + run baseline vs corpus eval on the 15 tasks in `eval/tasks.md`. Measure first; author more chunks only where eval shows knowledge moves the needle.

Companion idea-machine topic for meta-insights: `knowledge-systems` (private). 7 insights persisted 2026-05-16.

## Scope

**In scope:**
- bpy API: mesh primitives, transforms, modifiers, materials
  (Principled BSDF), lights, cameras, render settings (Cycles, Eevee),
  keyframes, compositor basics, file I/O
- Manual sections covering modeling (hard-surface subset),
  materials/shading, rendering, lighting, camera, compositing basics,
  color management
- Version-diff gotchas, especially Blender 4.x ↔ 5.x

**Out of scope:** rigging, weight painting, IK, sculpting, retopology,
physics sims, Grease Pencil, VSE, character animation, NLA.

## Conventions

- Every doc has YAML frontmatter: `title`, `tags`, `when_to_consult`,
  `blender_version`, `last_reviewed`. Without this, QMD ranking suffers.
- One doc per topic. Don't bundle.
- API docs: signature + minimal example + version notes. Aim 100-300
  lines.
- Recipe docs: goal + bpy code + parameter explanation + gotchas. Aim
  100-400 lines.
- Gotcha docs: short, dense. 30-100 lines.
- Reference exact bpy operator paths (`bpy.ops.mesh.primitive_cube_add`).
- Cite Blender manual section or API ref URL at top of every doc.

## When the user edits the corpus

After any change under `docs/`, run `qmd embed` once so semantic search
indexes the new content. The BM25 index updates incrementally on every
`qmd update`.

## When to add a new doc

When Claude hallucinates an operator, gets a shader property wrong, or
needs a recipe written from scratch a second time — capture it here.

## Eval

`eval/tasks.md` defines 15 generic product-viz scenarios. Use
`scripts/eval_runner.py` (TBD) to score Claude+MCP performance with and
without this corpus loaded. Knowledge edits are validated against eval
delta, not vibes.

## Personalization — User Layer

This is the **foundational** layer. A sibling `blender-knowledge-user`
repo holds per-user customizations (preferences, project conventions,
custom assets, hard-won corrections). Both QMD collections are queried
on every Blender task; user layer wins on overlap.

See `PERSONALIZATION.md` for the full design and write-triggers.

**During a Blender session, watch for teaching events** — explicit
preferences, demonstrated workflows, corrections that fix Claude's
mistakes, custom assets the user owns. Propose writing to the user
layer (not this foundational repo) with one-sentence quoted summary
+ proposed filename + tags. Confirm before persisting. Never silently
write a misunderstanding to long-term memory.

If the learning is genuinely generic (applies to any product-viz user,
not just this user's projects), propose a PR to **this** foundational
repo instead. Use the `extends` frontmatter field on user-layer docs
that override or augment foundational ones, so reconciliation works
when foundational updates.

## Related

- Track B (Gemini Live streaming harness) lives separately. This corpus
  feeds either backend.
