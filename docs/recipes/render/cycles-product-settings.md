---
title: Cycles render settings for product visualization
tags: [render, cycles, product-viz, recipe]
when_to_consult: Configuring Cycles render settings for a product hero shot, turntable, or short commercial clip; user mentions sample count, denoising, render time, or quality
blender_version: "4.2+"
last_reviewed: 2026-05-16
---

# Cycles render settings — product viz baseline

Source: Blender manual — Cycles
(`https://docs.blender.org/manual/en/latest/render/cycles/index.html`)

## Goal

Sane Cycles defaults that produce clean, low-noise product renders
without burning hours per frame. Tuned for typical hero-shot scenes
with glass, metal, or fabric on a simple backdrop.

## Code

```python
import bpy

def configure_cycles_for_product(samples=256, max_bounces=12,
                                 resolution=(2560, 1440),
                                 denoise=True, gpu=True):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'

    cy = scene.cycles
    cy.device = 'GPU' if gpu else 'CPU'
    cy.feature_set = 'SUPPORTED'  # use 'EXPERIMENTAL' only for adaptive subdiv

    # Sampling
    cy.samples = samples
    cy.use_adaptive_sampling = True
    cy.adaptive_threshold = 0.01  # lower = more samples in noisy areas
    cy.adaptive_min_samples = 0   # 0 = automatic

    # Light paths — these control caustics and bounce realism
    cy.max_bounces = max_bounces
    cy.diffuse_bounces = 4
    cy.glossy_bounces = 8           # high for chrome/glass scenes
    cy.transmission_bounces = 12    # high for glass; reduce to 4 if scene is opaque
    cy.transparent_max_bounces = 8
    cy.volume_bounces = 0           # raise only if you have volumetric mats

    # Caustics — off by default in Cycles; turn on for glass-with-sun scenes
    cy.caustics_reflective = True
    cy.caustics_refractive = True

    # Denoising
    cy.use_denoising = denoise
    cy.denoiser = 'OPENIMAGEDENOISE'  # OIDN; better quality than OPTIX for stills
    cy.denoising_input_passes = 'RGB_ALBEDO_NORMAL'
    cy.denoising_prefilter = 'ACCURATE'

    # Output resolution
    scene.render.resolution_x = resolution[0]
    scene.render.resolution_y = resolution[1]
    scene.render.resolution_percentage = 100

    # Color management — Filmic is the default since 2.80, AgX in 4.x default
    scene.view_settings.view_transform = 'AgX'  # falls back to 'Filmic' on <4.x
    scene.view_settings.look = 'AgX - Base Contrast'
    scene.view_settings.exposure = 0.0
    scene.view_settings.gamma = 1.0

    # File output
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.color_depth = '16'  # 16-bit for grading headroom

configure_cycles_for_product()
```

## Per-shot tuning

| Subject | Samples | Notes |
|---|---|---|
| Solid product, simple lighting | 128 | Denoise covers the rest |
| Glass / chrome / refractive | 512–1024 | Caustics need more samples |
| Hair / fur / volumetric | 1024+ | Denoiser struggles below this |
| Turntable animation | 64–128 + temporal denoise | Speed wins over per-frame quality |

## Critical gotchas

- **GPU device list must be enabled first.** In a fresh Blender, no
  GPU device is enabled even if hardware exists. Programmatic enable:
  ```python
  prefs = bpy.context.preferences.addons['cycles'].preferences
  prefs.compute_device_type = 'METAL'  # or 'CUDA', 'OPTIX', 'HIP', 'ONEAPI'
  prefs.refresh_devices()
  for d in prefs.devices:
      d.use = True
  ```
  Without this, `cy.device = 'GPU'` silently falls back to CPU.
- **AgX is 4.x default; Filmic for older.** Setting `view_transform='AgX'`
  on Blender 3.x will produce a warning and fall back. Use Filmic
  explicitly if generating cross-version code.
- **OPENIMAGEDENOISE vs OPTIX.** OIDN gives better still quality. OPTIX
  is faster and works during viewport. For final renders use OIDN. For
  viewport preview use OPTIX.
- **Transmission bounces ≥ 12 for glass.** Default of 8 produces
  visible darkening on thick glass (whiskey bottle, perfume bottle
  with thick walls). Bump to 12+ if glass looks darker than expected.
- **Caustics are off by default in 4.x.** Must be explicitly enabled
  with `caustics_reflective` and `caustics_refractive`. Without them,
  light through glass produces no projected pattern on the surface.
- **Color depth 16-bit for grading.** Default is 8-bit which clips
  highlights and bands shadows. Use 16 for product hero shots.

## Denoise quality vs speed

OIDN with `RGB_ALBEDO_NORMAL` input passes and `ACCURATE` prefilter
is the gold standard for product viz stills — clean output even at
128 samples for simple scenes. For complex caustics, raise samples
before reducing denoise strength.

## Eevee equivalent

For Eevee Next previews, the equivalent is much shorter (no light
path tuning; denoise is implicit in TAA). See
`docs/recipes/render/eevee-product-preview.md` (planned).
