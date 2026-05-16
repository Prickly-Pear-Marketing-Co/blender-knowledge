---
title: End-to-end hero shot — blank scene to rendered product image
tags: [workflow, hero-shot, end-to-end, product-viz]
when_to_consult: User asks for a complete product render from scratch ("render this perfume bottle", "make a hero shot of these headphones", "set up a product photo of X"); use as the orchestrating recipe that calls into material, lighting, camera, and render recipes
blender_version: "4.2+"
last_reviewed: 2026-05-16
---

# Hero shot — full pipeline from blank scene

Source: composite of `docs/recipes/material/*`, `docs/recipes/lighting/*`,
`docs/recipes/camera/*`, `docs/recipes/render/*`.

## Goal

Take a single product mesh and produce a publishable hero render in
one orchestrated bpy script. This is the **top-level entry point**
for any "make a product render" request. Sub-recipes are referenced
but inlined here for token-efficient single-shot generation.

## Inputs the caller must specify

- `mesh_path` — file path to a `.glb`, `.fbx`, `.obj`, or `.blend`
  containing the product mesh, OR `mesh_name` if already in scene.
- `subject_height` — approximate product height in meters (e.g. 0.15
  for a perfume bottle, 1.8 for a mannequin).
- `material_type` — one of `glass`, `metal`, `plastic`, `fabric`,
  `ceramic`, `default`. Picks the right recipe.
- `mood` — one of `bright`, `balanced`, `moody`, `dramatic`. Sets
  key:fill ratio.
- `backdrop` — one of `white`, `gradient`, `black`, `wood`, `marble`.
- `samples` — Cycles sample count. Default 256.

## Full pipeline

```python
import bpy
import math
from mathutils import Vector

def make_hero_shot(mesh_path=None, mesh_name=None, subject_height=0.15,
                   material_type='default', mood='balanced',
                   backdrop='white', samples=256,
                   resolution=(2560, 1440), output_path='/tmp/hero.png'):

    # ---- 1. Scene reset
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene

    # ---- 2. Import or locate subject
    if mesh_path:
        ext = mesh_path.split('.')[-1].lower()
        if ext == 'glb' or ext == 'gltf':
            bpy.ops.import_scene.gltf(filepath=mesh_path)
        elif ext == 'fbx':
            bpy.ops.import_scene.fbx(filepath=mesh_path)
        elif ext == 'obj':
            bpy.ops.wm.obj_import(filepath=mesh_path)
        elif ext == 'blend':
            with bpy.data.libraries.load(mesh_path) as (src, dst):
                dst.objects = src.objects
            for obj in dst.objects:
                if obj: scene.collection.objects.link(obj)
        subject = next((o for o in bpy.context.selected_objects
                        if o.type == 'MESH'), None)
    else:
        subject = bpy.data.objects.get(mesh_name)
    if subject is None:
        raise RuntimeError("No subject mesh resolved")

    # ---- 3. Center subject and place at origin
    bpy.ops.object.select_all(action='DESELECT')
    subject.select_set(True)
    bpy.context.view_layer.objects.active = subject
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY')
    subject.location = (0, 0, 0)
    # Scale to expected height
    bbox_h = (max(v.co.z for v in subject.data.vertices) -
              min(v.co.z for v in subject.data.vertices)) * subject.scale.z
    if bbox_h > 0:
        subject.scale *= (subject_height / bbox_h)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    # ---- 4. Material — dispatch to recipe by type
    subject.data.materials.clear()
    if material_type == 'glass':
        mat = _make_glass()
    elif material_type == 'metal':
        mat = _make_metal()
    elif material_type == 'plastic':
        mat = _make_plastic()
    elif material_type == 'ceramic':
        mat = _make_ceramic()
    elif material_type == 'fabric':
        mat = _make_fabric()
    else:
        mat = _make_default()
    subject.data.materials.append(mat)

    # ---- 5. Backdrop — seamless cyclorama or surface
    _add_backdrop(backdrop, subject_height)

    # ---- 6. Lighting — three-point with mood-based ratio
    target_z = subject_height * 0.5
    _add_three_point(target_z, mood)

    # ---- 7. Camera — 50mm at 3/4 angle for typical product
    _add_camera(subject_height, target_z)

    # ---- 8. Cycles render config
    _configure_cycles(samples, resolution)

    # ---- 9. Render to file
    scene.render.filepath = output_path
    bpy.ops.render.render(write_still=True)
    return output_path

# --- Material recipes (see docs/recipes/material/) ---

def _make_glass():
    mat = bpy.data.materials.new("Glass")
    mat.use_nodes = True
    mat.blend_method = 'HASHED'
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs["Base Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.0
    bsdf.inputs["IOR"].default_value = 1.45
    bsdf.inputs["Transmission Weight"].default_value = 1.0
    return mat

def _make_metal():
    mat = bpy.data.materials.new("Metal")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs["Base Color"].default_value = (0.85, 0.85, 0.88, 1.0)
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.18
    return mat

def _make_plastic():
    mat = bpy.data.materials.new("Plastic")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs["Base Color"].default_value = (0.6, 0.6, 0.62, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.4
    bsdf.inputs["Specular IOR Level"].default_value = 0.5
    return mat

def _make_ceramic():
    mat = bpy.data.materials.new("Ceramic")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs["Base Color"].default_value = (0.9, 0.88, 0.85, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.25
    bsdf.inputs["Coat Weight"].default_value = 0.3
    return mat

def _make_fabric():
    mat = bpy.data.materials.new("Fabric")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs["Base Color"].default_value = (0.5, 0.45, 0.4, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Sheen Weight"].default_value = 0.4
    return mat

def _make_default():
    mat = bpy.data.materials.new("Default")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs["Base Color"].default_value = (0.7, 0.7, 0.72, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.4
    return mat

# --- Backdrop ---

def _add_backdrop(kind, height):
    bpy.ops.mesh.primitive_plane_add(size=10, location=(0, 2, -height * 0.5))
    plane = bpy.context.object
    plane.name = "Backdrop"
    # Bend into cyclorama using Solidify + curve modifier (omitted for brevity)
    mat = bpy.data.materials.new(f"BG_{kind}")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    colors = {
        'white':    (0.95, 0.95, 0.95, 1.0),
        'gradient': (0.5,  0.5,  0.55, 1.0),  # tune w/ a gradient node for real grad
        'black':    (0.02, 0.02, 0.03, 1.0),
        'wood':     (0.35, 0.22, 0.12, 1.0),
        'marble':   (0.92, 0.90, 0.88, 1.0),
    }
    bsdf.inputs["Base Color"].default_value = colors.get(kind, (0.5, 0.5, 0.5, 1.0))
    bsdf.inputs["Roughness"].default_value = 0.6 if kind != 'marble' else 0.15
    plane.data.materials.append(mat)

# --- Lighting (see docs/recipes/lighting/three-point-studio.md) ---

def _add_three_point(target_z, mood):
    ratios = {'bright': 2, 'balanced': 3, 'moody': 6, 'dramatic': 12}
    ratio = ratios.get(mood, 3)
    key_power = 800
    fill_power = key_power / ratio
    rim_power = 500
    target = (0, 0, target_z)

    def add(name, loc, power, sx, sy, color):
        bpy.ops.object.light_add(type='AREA', location=loc)
        L = bpy.context.object
        L.name = name
        L.data.shape = 'RECTANGLE'
        L.data.size = sx
        L.data.size_y = sy
        L.data.energy = power
        L.data.color = color
        L.data.spread = math.radians(120)
        direction = Vector(target) - Vector(loc)
        L.rotation_mode = 'QUATERNION'
        L.rotation_quaternion = direction.to_track_quat('-Z', 'Y')

    add("Key",  (-2.5, -2.0, 2.8), key_power,  1.8, 1.8, (1.0, 0.95, 0.88))
    add("Fill", ( 2.0, -1.5, 2.0), fill_power, 2.5, 2.5, (0.92, 0.95, 1.0))
    add("Rim",  ( 1.5,  2.5, 2.5), rim_power,  0.6, 1.0, (1.0, 0.95, 0.85))

# --- Camera (see docs/recipes/camera/) ---

def _add_camera(subject_height, target_z):
    distance = max(subject_height * 8, 1.5)
    cam_loc = (distance * 0.4, -distance, target_z + subject_height * 0.5)
    bpy.ops.object.camera_add(location=cam_loc)
    cam = bpy.context.object
    cam.name = "Camera"
    cam.data.lens = 50  # 50mm for natural perspective; 85mm for compression
    cam.data.sensor_width = 36  # full-frame
    cam.data.dof.use_dof = True
    cam.data.dof.aperture_fstop = 4.0
    # Aim camera at subject
    direction = Vector((0, 0, target_z)) - Vector(cam_loc)
    cam.rotation_mode = 'QUATERNION'
    cam.rotation_quaternion = direction.to_track_quat('-Z', 'Y')
    bpy.context.scene.camera = cam

# --- Cycles (see docs/recipes/render/cycles-product-settings.md) ---

def _configure_cycles(samples, resolution):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    cy = scene.cycles
    cy.device = 'GPU'
    cy.samples = samples
    cy.use_adaptive_sampling = True
    cy.adaptive_threshold = 0.01
    cy.max_bounces = 12
    cy.glossy_bounces = 8
    cy.transmission_bounces = 12
    cy.caustics_reflective = True
    cy.caustics_refractive = True
    cy.use_denoising = True
    cy.denoiser = 'OPENIMAGEDENOISE'
    cy.denoising_input_passes = 'RGB_ALBEDO_NORMAL'
    cy.denoising_prefilter = 'ACCURATE'
    scene.render.resolution_x = resolution[0]
    scene.render.resolution_y = resolution[1]
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = 'AgX'
    scene.view_settings.look = 'AgX - Base Contrast'
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.color_depth = '16'

# Entry point
# make_hero_shot(mesh_name="MyBottle", subject_height=0.18,
#                material_type='glass', mood='balanced',
#                backdrop='white', samples=512)
```

## Why this is the entry-point recipe

A user request like "render this perfume bottle as a hero shot" maps
to a single call to `make_hero_shot()`. Sub-recipes (material,
lighting, camera, render) are inlined here so the LLM does not need
to retrieve and integrate 4 separate chunks. For specialized tweaks
(custom backdrop curve, multi-light cyclorama, specific lens
characteristics) the LLM still retrieves the sub-recipe.

## Common failures

- **Subject not at origin after import.** The `origin_set` +
  `location = (0,0,0)` step is mandatory. Imported assets often have
  arbitrary origins.
- **Scale wrong.** The bbox normalization assumes the longest axis
  is Z. For sideways products (a phone lying flat), re-orient before
  calling this function.
- **No backdrop curve.** The flat plane backdrop reads as a wall in
  the render. For real cyclorama effect, add a Solidify + Bend modifier
  or use a curved plane mesh.
- **GPU not actually enabled.** See `docs/recipes/render/cycles-product-settings.md`
  for the device-enable boilerplate. `cy.device = 'GPU'` alone is not
  enough on a fresh Blender install.
