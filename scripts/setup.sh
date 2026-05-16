#!/usr/bin/env bash
# Idempotent bootstrap for the blender-knowledge QMD collection.
# Registers docs/ as a collection, then embeds.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v qmd >/dev/null 2>&1; then
  echo "qmd not installed. Install with: npm i -g @tobilu/qmd" >&2
  exit 1
fi

if qmd collection list 2>/dev/null | grep -q '^blender-knowledge$'; then
  echo "Collection 'blender-knowledge' already present."
else
  qmd collection add "$REPO_DIR/docs" \
    --name blender-knowledge \
    --mask "**/*.md"
  qmd context add qmd://blender-knowledge \
    "Blender knowledge corpus scoped to product visualization. Query for bpy API reference, shader/material recipes, lighting setups, camera composition, render settings, version-drift gotchas. Consult any time Claude is operating Blender via MCP or generating bpy code."
fi

qmd update
qmd embed

echo "blender-knowledge collection ready. Query with: qmd query '<topic>' -c blender-knowledge"
