# Roadmap

Phased plan across all three tracks. Order reflects dependency,
risk reduction, and measurable-value-first.

## Phase 1 — Prove the corpus moves the needle (week 1-2)

**Goal:** Quantify whether knowledge retrieval changes Claude's
Blender output quality. No more knowledge work until this is
measured.

| Step | Output | Track |
|---|---|---|
| Build `scripts/eval_runner.py` with `ClaudeMcpBackend` (Claude + ahujasid MCP, no corpus) | Working harness | A |
| Run baseline eval on 15 tasks — no corpus | Baseline metrics: completion rate, tokens/iteration, render quality | A |
| Run eval with corpus loaded (current 5 docs + skill) | Delta vs baseline | A |
| Analyze per-task failures | Targeted recipe authoring list | A |

**Exit criteria:** Have a number — "+X% completion / -Y tokens / +Z
quality with corpus." If delta is small, knowledge isn't the bottleneck.

## Phase 2 — Scale the corpus to where eval says it should (week 3-4)

Conditional on Phase 1 showing knowledge moves the needle.

| Step | Output | Track |
|---|---|---|
| Author 8-10 more recipes targeting Phase 1 failures (camera composition, HDRI lighting, metal/plastic/fabric materials, color management, compositor glare, AgX vs Filmic) | Filled `docs/recipes/` | A |
| Implement `ingest_api.py` for in-scope bpy modules | Populated `docs/api/` | A |
| Implement `ingest_manual.py` for in-scope manual sections | Populated `docs/workflows/` | A |
| Re-run eval | Iterate until quality ceiling reached | A |

**Exit criteria:** Marginal value of additional chunks approaches
zero, or eval quality plateaus.

## Phase 3 — User-layer activation (week 3-4, parallel to Phase 2)

| Step | Output | Track |
|---|---|---|
| Use the skill in real Blender sessions; observe what teaching events fire | Capture protocol validated in practice | C |
| Refine `blender-expert` skill based on real triggers | Updated `SKILL.md` | C |
| Author `scripts/reconcile-user-layer.sh` once user-layer has enough content to make reconciliation meaningful | Reconciliation tooling | C |
| Author `scripts/promote-to-foundational.sh` once a user-layer entry is genuinely promotion-worthy | PR-opening tool | C |

## Phase 4 — Track B feasibility spike (week 5)

| Step | Output | Track |
|---|---|---|
| Standalone Gemini 2.5 Flash Live spike — stream Blender viewport at 1 fps, function-call a primitive, close the loop | Confirms streaming architecture is viable | B |
| Measure real latency, cost, quality of decisions | Numbers vs Phase 1 baseline | B |
| Decide: commit to harness, or stop at Track A | Go/no-go on Phase 5 | B |

**Exit criteria:** Spike either proves viewport streaming closes the
modality gap meaningfully (vs Phase 1+2 ceiling), or it doesn't.

## Phase 5 — Streaming harness (week 6-10, conditional)

Conditional on Phase 4 spike succeeding.

| Step | Output | Track |
|---|---|---|
| Fork ahujasid MCP or write new TCP-server addon with structured returns, undo, screenshot-after-write, frame pump | Better Blender bridge | B |
| pi.dev extension: `blender-tools` | bpy tools as pi `defineTool()` entries | B |
| pi.dev extension: `gemini-live-bridge` | WebSocket Gemini Live → pi tool loop | B |
| pi.dev extension: `blender-knowledge-retrieval` | Wraps QMD into a pi tool | B |
| Run same eval suite on streaming harness | Compare Claude+MCP+corpus vs Gemini+Live+corpus | B |

## Phase 6 — Production readiness (week 11+)

| Step | Output | Track |
|---|---|---|
| Real product shoot test — replace 1-2 hours of human Blender operation on a real client deliverable | Production validation | All |
| Cost telemetry | Track $/shot vs human labor cost | All |
| Skill v1.0 — packaged Claude Code skill, ready for community | Distribution-ready | A+C |
| Foundational repo opening to community PRs | Public contribution flow | A |

## Out of scope (intentionally not on roadmap)

- Character animation, rigging, sculpting tooling
- Geometry Nodes deep coverage (use as needed only)
- Mobile / iPad Blender (Blender doesn't run there anyway)
- Real-time game-engine workflows (Unity, Unreal, Godot) — different problem
- Fine-tuning a model on bpy code — too expensive, RAG covers it
- Commercial-grade compositor work (DaVinci, Nuke pipelines)
