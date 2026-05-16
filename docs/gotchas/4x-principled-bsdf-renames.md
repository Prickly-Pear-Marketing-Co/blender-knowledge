---
title: Principled BSDF input renames — Blender 3.x → 4.x
tags: [gotcha, version-drift, material, shader-nodes, principled-bsdf]
when_to_consult: Generating or editing Principled BSDF shader code in Blender 4.2+ — many input names changed
blender_version: "4.2+"
last_reviewed: 2026-05-16
---

# Principled BSDF — 3.x → 4.x property renames

Source: Blender 4.0 release notes —
`https://developer.blender.org/docs/release_notes/4.0/python_api/`

The Principled BSDF was overhauled in 4.0. Any bpy code using 3.x
input names will fail silently or with `KeyError` in 4.2+.

## Rename table

| 3.x name | 4.x name | Notes |
|---|---|---|
| `Subsurface` | `Subsurface Weight` | Was a 0-1 mix factor; semantics unchanged |
| `Subsurface Color` | removed | Use `Base Color` instead |
| `Specular` | `Specular IOR Level` | Default 0.5; affects reflectivity at normal incidence |
| `Specular Tint` (float) | `Specular Tint` (color) | Now an RGB color, not a single float |
| `Transmission` | `Transmission Weight` | Function unchanged |
| `Sheen` | `Sheen Weight` | Function unchanged |
| `Sheen Tint` (float) | `Sheen Tint` (color) | Now an RGB color |
| `Clearcoat` | `Coat Weight` | Renamed "Clearcoat" → "Coat" throughout |
| `Clearcoat Roughness` | `Coat Roughness` | |
| `Clearcoat Normal` | `Coat Normal` | |
| (none) | `Coat IOR` | **New in 4.x.** Note: `Clearcoat IOR` never existed in 3.x — do not generate that name |
| `Emission` | `Emission Color` | Color part split out. **Trap:** setting Emission Color alone produces zero emission — must also set `Emission Strength` > 0 (defaults to 0 on new materials, 1 on Principled defaults — verify) |
| (new) | `Emission Strength` | Separate strength multiplier. Required > 0 for visible emission |
| (none) | `Metallic Roughness` | **New in 4.x**, separate from base `Roughness`. Used for the metallic GGX lobe. An LLM defaulting to only setting `Roughness` will get correct dielectric but wrong metal — for metallic materials, set both |

## Detection

If a script does `bsdf.inputs["Specular"].default_value = 0.5` in 4.2+,
Python raises:

```
KeyError: 'bpy_prop_collection[key]: key "Specular" not found'
```

The error is informative — Claude should map back to the table above
and retry with the correct 4.x name.

## Forward-compat code pattern

```python
def safe_set(bsdf, candidates, value):
    """Set the first input whose name exists in this Blender's BSDF."""
    for name in candidates:
        if name in bsdf.inputs:
            bsdf.inputs[name].default_value = value
            return name
    raise KeyError(f"None of {candidates} found in Principled BSDF inputs")

safe_set(bsdf, ["Transmission Weight", "Transmission"], 1.0)
safe_set(bsdf, ["Specular IOR Level", "Specular"], 0.5)
```

Use this when targeting code that should run across 3.x and 4.x. For
pure 4.2+ code, use the 4.x names directly.

## Why this matters for Claude

Training data heavily includes 3.x examples. Claude defaults to 3.x
names. When a `KeyError` surfaces from the MCP, the fix is almost
always a 3.x→4.x rename — not the user's scene or a missing addon.
Check this table first.
