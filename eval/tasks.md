# Eval Tasks — Product Viz Baseline

15 generic product-viz scenarios. Used by `eval_runner.py` to score
Claude+MCP performance with and without `blender-knowledge` loaded.

Scoring rubric (per task):
- ✅ Completed without manual fix? (binary)
- ⏱  Iterations needed (model turns)
- 💰 Tokens consumed (input + output)
- 🖼  Render quality 1-5 (blind human rating)
- 🐛 `execute_blender_code` error count

Run conditions to compare:
1. **Baseline** — Claude + ahujasid MCP, no corpus
2. **+API chunks** — `blender-knowledge` corpus with `docs/api/` populated
3. **+API + recipes** — adds `docs/recipes/`
4. **+API + recipes + gotchas** — full corpus

---

## Tasks

### 1. Perfume bottle — white seamless studio
Generic frosted-glass perfume bottle on white seamless backdrop.
3-point softbox lighting. 50mm camera, eye-level. Cycles, Filmic.

### 2. Ceramic coffee mug — warm scene
Standard ceramic mug, matte finish, warm tan color. Soft window
light from camera-left, gentle shadow. Wood surface beneath.

### 3. Wireless earbuds — dark moody hero
Stylized wireless earbud pair on dark reflective surface. Single
rim light + low-fill key. Black-on-black hero shot. Cycles.

### 4. Wristwatch — gold on marble
Round-face wristwatch, gold case, leather strap. White marble surface,
top-down 3/4 angle. Bright soft daylight.

### 5. Wine bottle — reflective label
Standard wine bottle, dark glass, reflective foil label. Dark studio
backdrop, rim lights on bottle shoulders, label clearly readable.

### 6. Sneaker on plinth
Generic athletic shoe on cylindrical plinth, gradient grey backdrop.
Three studio lights. 85mm camera, slightly low angle.

### 7. Glass water bottle — caustics
Clear glass water bottle, partial water, on light wood. Sun-style key
light producing visible caustics on the surface. Cycles only.

### 8. Headphones — 360° turntable
Over-ear headphones, turntable animation 12 seconds at 24fps, full
360° rotation. Static 3-point lighting. White cyclorama background.
Render to image sequence.

### 9. Cosmetic jar — pastel
Small round cosmetic jar, gold lid, pastel pink background gradient.
Soft overhead key, fill bounce. Top-down 30° angle.

### 10. Mechanical keyboard — top-down hero
Compact mechanical keyboard, top-down dead-center. Dramatic side
lighting to emphasize key contours. Dark moody backdrop.

### 11. Smartwatch — wrist mannequin
Square-face smartwatch on a generic wrist mannequin form. Studio
lighting, clean white background, watchface clearly visible.

### 12. Whiskey glass with ice
Heavy-bottom rocks glass, amber liquid, cube-shaped ice. Faked — no
liquid sim. Backlit for amber glow. Dark moody backdrop.

### 13. Smartphone — edge-lit dark
Generic slab smartphone, screen off, dark scene. Two rim lights along
the long edges produce silhouette glow. Reflective floor.

### 14. Pen on wood desk — natural window light
Premium pen lying on wood desk surface. Simulated window light from
camera-left, soft directional. 50mm, shallow DOF, focus on nib.

### 15. Lipstick on reflective black
Lipstick tube, partially extended, on glossy black surface producing
clean reflection. Cinematic side-lighting. Bold color, jewelry-like
treatment.

---

## Acceptance per task

A task **passes** if:
- Render completes without manual scene fixing
- Subject is correctly identified and primary in frame
- Lighting matches the descriptor (e.g., "moody" vs "bright studio")
- Materials behave correctly (glass refracts, metal is metallic, etc.)
- Quality rating ≥ 3/5

A task **fails** if:
- Scene requires user to manually fix geometry, lighting, or materials
- Render shows obvious artifacts (intersecting objects, NaN, magenta
  missing textures)
- `execute_blender_code` errors more than 5 times before completion
