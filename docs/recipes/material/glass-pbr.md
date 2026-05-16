---
title: PBR glass material via Principled BSDF
tags: [material, pbr, shader-nodes, glass, recipe]
when_to_consult: Creating clear glass, frosted glass, or refractive transparent material on any object
blender_version: "4.2+"
last_reviewed: 2026-05-16
---

# Glass material — Principled BSDF recipe

Source: Blender manual — Principled BSDF
(`https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/principled.html`)

## Goal

A physically plausible clear glass material. Single Principled BSDF
node — no separate Glass BSDF needed for typical product viz.

## Code

```python
import bpy

def make_glass_material(name="Glass", color=(1.0, 1.0, 1.0, 1.0),
                        roughness=0.0, ior=1.45):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    # Eevee requires blend_method for transmission; Cycles ignores it
    mat.blend_method = 'HASHED'
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is None:
        # Either fresh material with renamed node, or non-default tree.
        # Find by type rather than label.
        bsdf = next(
            (n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'),
            None,
        )
    if bsdf is None:
        raise RuntimeError(f"Material {name} has no Principled BSDF node")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["IOR"].default_value = ior
    bsdf.inputs["Transmission Weight"].default_value = 1.0
    bsdf.inputs["Alpha"].default_value = 1.0  # do not lower for glass
    return mat

# Apply
obj = bpy.data.objects["MyBottle"]
obj.data.materials.clear()
obj.data.materials.append(make_glass_material("BottleGlass"))
```

## Parameters

| Input | Value | Why |
|---|---|---|
| Transmission Weight | 1.0 | Routes light through the surface |
| Roughness | 0.0 clear, 0.3+ frosted | Higher = more diffuse refraction |
| IOR | 1.45 (glass), 1.33 (water), 2.4 (diamond) | Index of refraction |
| Base Color | white default, tint for colored glass | Multiplied through transmission |
| Alpha | 1.0 — keep at 1.0 | Lowering breaks refraction in Cycles |

## Critical gotchas

- **Transmission Weight is the 4.x name.** In Blender 3.x and earlier
  it was just "Transmission". A bare "Transmission" property reference
  will fail in 4.2+. See `docs/gotchas/4x-principled-bsdf-renames.md`.
- **Eevee renders glass as solid black without `blend_method`.** Must
  set `mat.blend_method = 'HASHED'` (or `'BLEND'`). Cycles ignores
  this setting. Code above sets it unconditionally — keep it.
- **Cycles only for caustics.** Eevee Next renders refraction but
  not full caustics. For sun-through-glass on a surface, use Cycles.
- **Don't drop Alpha below 1.0.** It looks intuitive ("make it
  transparent") but in Principled, Alpha is a cutout. Transmission
  is what you want for glass.
- **Shadow catcher + glass = black transmission renders.** If the
  scene has a Cycles shadow catcher plane and the glass object's
  `cycles_visibility.camera` is False, transmission rays terminate
  black. Keep camera visibility on for glass objects; toggle shadow
  catcher selectively.
- **Two-sided geometry breaks refraction.** Glass needs solid mesh
  with proper normals. Apply a Solidify modifier (thickness 0.002 m)
  to thin shells like wine glasses or bottles.
- **Cycles sampling.** Glass needs ≥256 samples + denoising for clean
  refractions. See `docs/recipes/render/cycles-product-settings.md`.

## Frosted variant

For frosted glass, set `roughness=0.3` to `0.5`. Higher roughness =
more diffuse refraction. Do not add Sheen — Sheen is a fabric model
and produces noise on glass.

## Tinted variant

For colored glass (amber whiskey bottle, green wine bottle), set
`Base Color` to a saturated tint. The transmission multiplier carries
the color through the volume.

```python
amber = (0.6, 0.25, 0.05, 1.0)
green = (0.1, 0.45, 0.15, 1.0)
```
