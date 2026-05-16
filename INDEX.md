# Index

Topics covered, with the tag Claude uses to query them.

| Topic | Tag | Where |
|---|---|---|
| Specific bpy operator or function | `api`, `bpy:<module>` | `docs/api/` |
| Cycles render settings | `render`, `cycles` | `docs/recipes/render/` |
| Eevee render settings | `render`, `eevee` | `docs/recipes/render/` |
| PBR material recipe | `material`, `pbr` | `docs/recipes/material/` |
| Shader nodes / Principled BSDF | `material`, `shader-nodes` | `docs/recipes/material/` |
| 3-point lighting / studio setup | `lighting`, `studio` | `docs/recipes/lighting/` |
| HDRI environment lighting | `lighting`, `hdri` | `docs/recipes/lighting/` |
| Camera composition / focal length | `camera`, `composition` | `docs/recipes/camera/` |
| Depth of field | `camera`, `dof` | `docs/recipes/camera/` |
| Turntable / product reveal animation | `animation`, `turntable` | `docs/recipes/camera/` |
| Modifier stacks (subdiv, bevel, boolean) | `modeling`, `modifiers` | `docs/recipes/modeling/` |
| Compositor: glare, color grading | `compositing` | `docs/recipes/compositing/` |
| Color management (Filmic, ACES) | `render`, `color` | `docs/recipes/render/` |
| Blender 4.x → 5.x API rename | `gotcha`, `version-drift` | `docs/gotchas/` |
| Full hero shot end-to-end | `workflow`, `hero-shot` | `docs/workflows/` |

Query:

```bash
# Foundational layer (this repo)
qmd query "<topic>" -c blender-knowledge
qmd query "<topic>" -c blender-knowledge --files --min-score 0.3

# User layer (sibling repo, if set up)
qmd query "<topic>" -c blender-knowledge-user
```

For an actual Blender session, query **both** and merge results.
User-layer entries override foundational on overlap. See
`PERSONALIZATION.md`.
