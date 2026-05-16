"""Ingest Blender manual (RST) into chunked workflow docs.

Planned implementation. Not yet executable.

Strategy:
1. Clone `https://projects.blender.org/blender/blender-manual.git` as
   a git submodule under `sources/blender-manual/`.
2. Walk `manual/render/`, `manual/render/cycles/`, `manual/render/eevee/`,
   `manual/render/shader_nodes/`, `manual/render/lights/`,
   `manual/render/cameras/`, `manual/modeling/`, `manual/compositing/`,
   `manual/render/color_management.rst`.
3. Skip out-of-scope: physics, grease pencil, vse, animation/rigging
   (beyond keyframes), sculpting.
4. Parse RST, chunk at H2 boundaries (~300-600 tokens each).
5. Emit markdown files under `docs/workflows/` (or `docs/recipes/`
   where the section maps cleanly to a recipe category).
6. Preserve source path + URL in frontmatter for attribution.
7. Re-author rather than verbatim copy where possible (keeps it
   tight and avoids long narrative).

Skip until v1 hand-authored recipes prove pattern + retrieval quality.
"""

if __name__ == "__main__":
    raise SystemExit("ingest_manual.py not yet implemented. See docstring.")
