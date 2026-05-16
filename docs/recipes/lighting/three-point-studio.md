---
title: Three-point studio lighting for product shots
tags: [lighting, studio, three-point, recipe, product-viz]
when_to_consult: Setting up studio lighting for a single hero product (perfume bottle, watch, headphones, etc.); user wants "clean studio" or "3-point" look
blender_version: "4.2+"
last_reviewed: 2026-05-16
---

# Three-point studio lighting — Blender area lights

Source: Creative Shrimp lighting fundamentals; Blender manual — Lights
(`https://docs.blender.org/manual/en/latest/render/lights/light_object.html`)

## Goal

Standard photographic three-point setup: key, fill, rim. Using area
lights configured as softboxes. Cycles or Eevee.

## Setup

Position relative to a subject placed at world origin, with the camera
on the +Y axis looking toward -Y.

| Light | Type | Position (XYZ) | Rotation toward subject | Power | Size | Color (RGB) |
|---|---|---|---|---|---|---|
| Key | Area, RECTANGLE | (-2.5, -2.0, 2.8) | aim at origin | 800 W | 1.8 × 1.8 m | (1.0, 0.95, 0.88) warm |
| Fill | Area, RECTANGLE | (2.0, -1.5, 2.0) | aim at origin | 250 W | 2.5 × 2.5 m | (0.92, 0.95, 1.0) cool |
| Rim | Area, RECTANGLE | (1.5, 2.5, 2.5) | aim at origin | 500 W | 0.6 × 1.0 m | (1.0, 0.95, 0.85) warm |

Key sits camera-left and elevated, providing primary form definition.
Fill sits camera-right at slightly lower elevation and lower power
(~3:1 key:fill ratio for moderate contrast; 6:1 for moody). Rim sits
behind subject opposite key to provide edge highlight separating
product from background.

**Color temperature matters.** Pure white lights (1, 1, 1) look
clinical and dated. Warm key + cool fill is the standard product
photo look — it gives the subject dimension and reads as professional.
The values in the Color column are good defaults; tune ±5% for taste.

**The aim target** at `(0, 0, 0.5)` is for typical bottle-sized product
~10 cm tall sitting on a surface. For taller subjects (1.5–2 m mannequin,
furniture) scale the Z target proportionally to subject height / 2.
For flat subjects (watch face on table) lower the Z target toward
the surface (0.05–0.1).

## Code

```python
import bpy
from mathutils import Vector

def add_area_light(name, location, target, power, size_x, size_y=None,
                   color=(1.0, 1.0, 1.0), spread_deg=120.0):
    bpy.ops.object.light_add(type='AREA', location=location)
    light = bpy.context.object
    light.name = name
    light.data.shape = 'RECTANGLE'
    light.data.size = size_x
    light.data.size_y = size_y if size_y else size_x
    light.data.energy = power
    light.data.color = color
    # spread controls beam angle — default 180° wraps too much for tabletop
    import math
    light.data.spread = math.radians(spread_deg)
    direction = Vector(target) - Vector(location)
    light.rotation_mode = 'QUATERNION'
    light.rotation_quaternion = direction.to_track_quat('-Z', 'Y')
    return light

# Subject at world origin; target slightly above for product ~10 cm tall.
# Scale Z proportionally for taller subjects.
target = (0, 0, 0.5)

add_area_light("Key",  (-2.5, -2.0, 2.8), target, power=800, size_x=1.8, size_y=1.8,
               color=(1.0, 0.95, 0.88))                      # warm
add_area_light("Fill", ( 2.0, -1.5, 2.0), target, power=250, size_x=2.5, size_y=2.5,
               color=(0.92, 0.95, 1.0))                      # cool
add_area_light("Rim",  ( 1.5,  2.5, 2.5), target, power=500, size_x=0.6, size_y=1.0,
               color=(1.0, 0.95, 0.85))                      # warm
```

## Tuning

- **Ratio (key:fill):** 2:1 bright/airy, 3:1 balanced (default), 6:1
  moody, 12:1 dramatic. Adjust fill power, never raise key past 1000 W
  for typical product distance.
- **Softness:** Light size controls softness, not power. Larger
  light = softer shadows. For tabletop product (10-20 cm), a 1.5-2.5 m
  light at 1-3 m distance gives smooth gradients.
- **Distance falloff:** Inverse square. Doubling distance quarters the
  light. Re-check power values if you move the rig.
- **Rim placement:** Watch for lens flare. Position rim so it does not
  point directly into camera lens or add a flag (large Plane mesh) to
  block direct path.

## Variant: high-key (white background)

Add a fourth Area light pointing at the seamless cyclorama:

```python
add_area_light("BG", (0, 4, 3), (0, 5, 1), power=1500, size_x=4, size_y=3)
```

Blow out the background to pure white. Useful for catalog / e-commerce
hero shots.

## Variant: low-key (dark moody)

Drop fill to 50 W or remove entirely. Raise rim to 700-1000 W. Add a
flag (Plane with black material, hidden from camera but visible to
rays) opposite the rim to keep the other side falling into shadow.

## Cycles vs Eevee

Cycles for final render (shadow gradients, caustics, color bleed).
Eevee Next for fast iteration previews.

## Common failures

- **All lights at default 1000 W** — scene blows out. Match the table.
- **Point lights instead of Area** — hard shadows, looks unprofessional.
  Always area lights for product viz.
- **Light shape SQUARE not RECTANGLE** — limits aspect ratio control.
  Use RECTANGLE with explicit size_x and size_y.
- **No fill light** — one-sided harsh look. Always include fill even
  at low power.
