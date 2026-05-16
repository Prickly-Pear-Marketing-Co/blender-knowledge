# Personalization — Two-Layer Knowledge System

This corpus has two layers, queried together by Claude/Gemini during
Blender sessions:

1. **Foundational layer** — this repo (`blender-knowledge` QMD
   collection). Public, versioned, community-maintained. Generic
   product-viz knowledge.
2. **User layer** — a separate per-user repo
   (`blender-knowledge-user` QMD collection). Private, lives wherever
   the user chooses (default `~/Documents/GitHub/blender-knowledge-user/`).
   Captures personal preferences, workflows, custom assets, project-
   specific patterns the user teaches over time.

The user layer is **additive on top of foundational**. Foundational
updates do not destroy user customizations. User entries cite
foundational entries they extend, and reconciliation surfaces
conflicts after a foundational update.

## Why two layers

A single user-editable corpus would either pollute the public seed or
get overwritten on update. Splitting them lets foundational evolve
independently while a user's accumulated expertise compounds across
sessions and projects.

## Setup

After installing the foundational corpus:

```bash
./scripts/init-user-layer.sh
```

Creates the user-layer repo at the default location (override with
`--path`), registers `blender-knowledge-user` as a QMD collection,
and writes a CLAUDE.md telling Claude how to populate it.

## How Claude uses both layers

Any Blender query goes to **both** collections:

```bash
qmd query "<topic>" -c blender-knowledge        # foundational
qmd query "<topic>" -c blender-knowledge-user   # personal
```

The orchestrating skill (planned: `blender-expert` skill) merges
results. On overlap, **user layer wins** for the user's machine —
their explicit teaching beats the generic default.

## How Claude learns (write path)

During a Blender session, Claude watches for **teaching events**:

| Trigger | Persist to user layer |
|---|---|
| "Always do X here" / "I prefer Y" | New preference doc |
| "These values work for this material" | New recipe variant |
| User demonstrates a new technique | New workflow doc |
| User corrects Claude with a working fix | New gotcha or recipe |
| User defines a reusable asset/component | Asset reference doc |
| User describes a project-specific convention | Workflow doc tagged with project |

When a teaching event happens, Claude:

1. **Proposes** the write — quotes back what it learned in one
   sentence, suggests filename + tags.
2. **Confirms** with the user before writing. Never silent
   long-term persistence of a misunderstanding.
3. **Writes** to the user-layer repo. Frontmatter must include
   `source_session: <date>` and, if extending a foundational doc,
   `extends: <relative-path-in-foundational>`.
4. **Optionally commits** the user-layer repo. The user layer is its
   own git repo — commits are local to the user's machine unless they
   choose to push (typically private remote).

## What belongs in user layer vs foundational

| Belongs in user layer | Belongs in foundational |
|---|---|
| Personal aesthetic preferences (color temp, contrast ratios) | Universally-applicable bpy API reference |
| Per-project conventions (asset names, scale units) | Cross-version API renames |
| Custom asset libraries, materials, HDRIs the user owns | Generic recipes (PBR glass, 3-point lighting) |
| Workflows specific to user's product categories | Workflows that apply to any product |
| Per-client style guides | Public manual / API doc derivations |
| Notes about user's hardware (GPU, RAM constraints) | Render engine fundamentals |

Rule of thumb: if it generalizes to anyone shooting product viz in
Blender, it belongs in foundational and should be PR'd upstream. If
it's about *this user* or *this user's clients/projects*, user layer.

## Reconciliation after foundational update

When the user pulls a new version of foundational:

```bash
./scripts/reconcile-user-layer.sh
```

(Planned.) For each user-layer doc with an `extends: <path>`
frontmatter field, the script compares the foundational doc's
`last_reviewed` to the user-layer doc's `extends_reviewed`. Mismatch
= surfaces for the user to re-review whether their override still
applies. No automatic deletion.

## Promotion path — user layer → foundational

If a user-layer entry turns out to be widely applicable, the user can
promote it:

```bash
./scripts/promote-to-foundational.sh <user-doc-path>
```

(Planned.) Copies the doc to the foundational repo, opens a PR,
removes the user-layer version on merge. Foundational PRs require
the `last_reviewed` to be set and `extends` removed.

## Long-term outcome

Over months, a user's `blender-knowledge-user` repo becomes a
high-value personal asset — capturing taste, workflow, and lessons
learned. Portable across machines (it's just a git repo). Survives
session resets. Shared with collaborators by inviting them to the
private repo.

The foundational repo, meanwhile, evolves from PRs (including user
promotions), staying useful as a baseline for every new user.
