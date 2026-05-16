#!/usr/bin/env bash
# Initialize a user-layer Blender knowledge repo.
# Sibling to this foundational repo. Registers `blender-knowledge-user`
# as a QMD collection. Per-user, private.

set -euo pipefail

DEFAULT_PATH="$HOME/Documents/GitHub/blender-knowledge-user"
USER_PATH="${1:-$DEFAULT_PATH}"

if [ -d "$USER_PATH" ]; then
  echo "User-layer repo already exists at $USER_PATH"
  echo "Skipping creation. Re-running QMD registration."
else
  echo "Creating user-layer repo at $USER_PATH"
  mkdir -p "$USER_PATH"/{docs/{recipes,gotchas,workflows,preferences,assets},scripts}

  cat > "$USER_PATH/CLAUDE.md" <<'EOF'
# Context for Claude — user-layer Blender knowledge

This repo is the **user-layer** companion to `blender-knowledge`.
Foundational knowledge lives in that repo. This repo captures
personal preferences, project-specific workflows, custom assets,
and lessons the user has taught Claude over time.

## Write triggers

During a Blender session, propose writing here when:
- The user states an explicit preference ("I always use 6:1 key-fill")
- The user demonstrates a personal workflow
- The user corrects Claude with a fix that should be remembered
- The user defines a reusable custom material, HDRI, or asset
- The user describes a per-project convention

Confirm with the user before persisting. Quote back the learned
content in one sentence and propose the filename + tags.

## Frontmatter

Every doc needs:

```yaml
---
title: <short title>
tags: [<tag>, <tag>, ...]
when_to_consult: <one-sentence trigger>
blender_version: "4.2+ | 5.x | etc."
source_session: YYYY-MM-DD
extends: <foundational/path/doc.md>   # optional, if overriding/augmenting
extends_reviewed: YYYY-MM-DD          # only if extends is set
last_reviewed: YYYY-MM-DD
---
```

## Query

Foundational + user layers are queried together. User layer entries
win on overlap.

```bash
qmd query "<topic>" -c blender-knowledge        # foundational
qmd query "<topic>" -c blender-knowledge-user   # this repo
```
EOF

  cat > "$USER_PATH/README.md" <<'EOF'
# blender-knowledge-user

Per-user Blender knowledge layer. Sibling to the foundational
`blender-knowledge` repo. Private — keep this repo unpublished or
on a private remote.

## Structure

- `docs/recipes/` — Personal recipes (overrides or new)
- `docs/gotchas/` — Lessons learned the hard way
- `docs/workflows/` — Personal end-to-end flows
- `docs/preferences/` — Aesthetic preferences (lighting ratios, color, etc.)
- `docs/assets/` — Notes on custom materials, HDRIs, models the user owns

## QMD collection

```bash
./scripts/setup.sh
```

Registers this repo as the `blender-knowledge-user` QMD collection.
EOF

  cat > "$USER_PATH/scripts/setup.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v qmd >/dev/null 2>&1; then
  echo "qmd not installed. Install with: npm i -g @tobilu/qmd" >&2
  exit 1
fi

if qmd collection list 2>/dev/null | grep -q '^blender-knowledge-user$'; then
  echo "Collection 'blender-knowledge-user' already present."
else
  qmd collection add "$REPO_DIR/docs" \
    --name blender-knowledge-user \
    --mask "**/*.md"
  qmd context add qmd://blender-knowledge-user \
    "User-specific Blender knowledge layered on top of blender-knowledge. Personal preferences, custom assets, per-project workflows, corrections learned over time. Query alongside blender-knowledge for any Blender task."
fi

qmd update
qmd embed

echo "blender-knowledge-user collection ready."
EOF
  chmod +x "$USER_PATH/scripts/setup.sh"

  cat > "$USER_PATH/.gitignore" <<'EOF'
node_modules/
.DS_Store
.qmd/
.idea/
.vscode/
EOF

  touch "$USER_PATH/docs/recipes/.gitkeep" \
        "$USER_PATH/docs/gotchas/.gitkeep" \
        "$USER_PATH/docs/workflows/.gitkeep" \
        "$USER_PATH/docs/preferences/.gitkeep" \
        "$USER_PATH/docs/assets/.gitkeep"

  cd "$USER_PATH" && git init -b main >/dev/null
  echo "Initialized git repo at $USER_PATH"
fi

# Always register the collection (idempotent)
"$USER_PATH/scripts/setup.sh"

echo ""
echo "User-layer ready at: $USER_PATH"
echo ""
echo "Next steps:"
echo "  1. (Optional) Add a private GitHub remote:"
echo "       cd $USER_PATH"
echo "       gh repo create <your-user>/blender-knowledge-user --private --source=. --push"
echo "  2. During Blender sessions, Claude will propose writes to this repo"
echo "     when you teach it preferences or workflows."
