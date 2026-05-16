"""Ingest bpy API docs into per-operator chunks.

Planned implementation. Not yet executable.

Strategy:
1. Scrape or clone `https://docs.blender.org/api/current/` HTML.
2. Filter to in-scope modules:
   - bpy.ops.mesh, bpy.ops.object, bpy.ops.material, bpy.ops.cycles,
     bpy.ops.render, bpy.ops.image, bpy.ops.anim, bpy.ops.camera,
     bpy.ops.transform, bpy.ops.export_scene, bpy.ops.import_scene
   - bpy.types.PrincipledBSDF, bpy.types.Light, bpy.types.Camera,
     bpy.types.RenderSettings, bpy.types.CyclesRenderSettings,
     bpy.types.WorldLighting, bpy.types.Object, bpy.types.Material
   - bpy.data shortcuts (objects, materials, lights, cameras, scenes)
   - mathutils.Vector, mathutils.Euler, mathutils.Matrix
3. For each operator or property page, emit one markdown file under
   `docs/api/<module>/<name>.md` with:
   - YAML frontmatter (title, tags=[api, bpy:<module>], when_to_consult,
     blender_version, last_reviewed, source_url)
   - Function signature
   - Parameters table
   - Return type
   - Minimal usage example
   - Version notes if any
4. Skip out-of-scope modules: bpy.ops.armature, bpy.ops.pose,
   bpy.ops.sculpt, bpy.ops.paint, bpy.ops.gpencil, bpy.ops.fluid,
   bpy.ops.cloth, bpy.ops.particle, bpy.ops.rigidbody, bpy.ops.sequencer.

Skip until v1 hand-authored recipes prove pattern + retrieval quality.

Reference prior art: BlenderRAG (arxiv 2605.00632) — chunked all 1,729
4.4 API HTML pages.
"""

if __name__ == "__main__":
    raise SystemExit("ingest_api.py not yet implemented. See docstring.")
