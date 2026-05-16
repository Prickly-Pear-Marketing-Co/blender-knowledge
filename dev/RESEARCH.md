# Research Notes

The basis for this project's design decisions. Captured here so
future work can be informed by the same evidence and revisit
conclusions when circumstances change.

## The problem we're solving

Claude (and similar LLMs) operate Blender inconsistently and often
incorrectly via current MCP tooling. Specific complaints across
forums, reviews, and developer blogs (2025–2026):

- Objects clip, float, scale wrong (the donut test: sprinkles went
  vertical and aggressive, coffee cup clipped into donut)
- Long sessions collapse — magenta renders, false completion claims
  after ~120k tokens
- Geometry Nodes generation is brittle, version-mismatched
- Sculpt / retopology / weight-paint unsupported
- First commands often fail; viewport screenshot broken on Linux

## Failure-mode taxonomy

Six categories, ranked by severity for product viz use case:

| Rank | Gap | Root cause | RAG fixes? |
|---|---|---|---|
| 1 | **Modality** (blind operator) | Viewport screenshot is on-demand, often broken. LLM reasons about scene it cannot see. | No |
| 2 | **Spatial reasoning** | Objects clip/float/scale wrong. No persistent dimensional model. | Partially (placement math chunks) |
| 3 | **Knowledge / stale API** | bpy API drift between 3.x→4.x→5.x. Geometry Nodes API churns. | **Yes — high leverage** |
| 4 | **Interface (thin MCP)** | ahujasid MCP = 4 inspection tools + `execute_blender_code` escape hatch. No structured material nodes, no edit mode, no modifier stack, no undo. | No |
| 5 | **Context exhaustion** | 60% of $200 Max plan burned in 2-hour donut test. | No (worsens if RAG dumped naively; tags + BM25 keep it lean) |
| 6 | **Topology reasoning** | No edge-loop awareness. Generates triangles not quads. | No |

## Why we believe RAG works

[BlenderRAG (arxiv 2605.00632, May 2025)](https://arxiv.org/abs/2605.00632)
proved API-doc RAG fixes #3:

- Tested Claude Sonnet 4.5, GPT-5, Gemini 3 Flash, Mistral Large
- Indexed 1,729 Blender 4.4 API HTML pages
- Code compile rate jumped **40.8% → 70.0%**
- Runs entirely CPU-side; no fine-tuning

This is the strongest single signal informing the bet on a knowledge
corpus.

## Why scope to product visualization

The 6-failure taxonomy applies broadly, but product viz is the
sub-domain where:

- Subject matter is hard-surface (cleanly mapped to bpy primitives +
  modifiers) — Claude already handles this OK
- Lighting is small (3-point studio or HDRI) — math is well-defined
- Materials are PBR via Principled BSDF — single shader, well-known
  inputs
- Camera composition is standard photo conventions (50–85mm,
  rule-of-thirds, DOF)
- Render = Cycles or Eevee with known settings recipes

In contrast, character animation, rigging, sculpting, and sims hit
multiple failure modes simultaneously and are out of scope.

Product viz is ~25-30% of Blender's surface area but ~80% of common
commercial Blender work (e-commerce, marketing renders, product
hero shots, turntables).

## Why Claude has no streaming video — and what does

| Model | Continuous video stream? | Tool calls during stream? | Cost @ 1fps |
|---|---|---|---|
| **Gemini 2.5 Flash Live** | Yes (WebSocket, 1fps cap, 263 tok/sec) | Yes | **~$2-3/hr** |
| GPT-4o Realtime | Audio yes, video no — client must inject frames at 2-4fps | Yes | varies |
| Claude (any) | **No.** Static images per turn only. GitHub req [#22903](https://github.com/anthropics/anthropic-cookbook/issues/22903) open, unimplemented. | n/a | n/a |
| Qwen2.5-VL / StreamingVLM / LLaVA-Video | Research-grade. vLLM/SGLang support batched. No turnkey stream server. | n/a | self-hosted |

The modality gap (#1 above) is **only fixable by switching to a
streaming-capable model**. Gemini Live API is the realistic option.

**Loop math (Gemini Live):**
- Frame capture ~50ms
- WebSocket roundtrip + inference ~300-800ms
- bpy exec ~10-100ms
- Total ~500ms-1s per decision → 1-2 actions/sec
- Cost: ~947K input tok/hr @ $2.10/1M = **~$2/hr stream + tool output**

## Existing Blender + LLM landscape

| Project | Approach | Status |
|---|---|---|
| [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp) | MCP server; `execute_blender_code` + 4 inspection tools | 21,700 stars; dominant |
| Anthropic Blender Connector | Repackaging of ahujasid for Claude Desktop | Official "Anthropic" path |
| [Blender Foundation MCP server](https://www.blender.org/lab/mcp-server/) | Distribution endpoint for the addon | Endorsed |
| CommonSenseMachines/blender-mcp | Adds Mixamo animation + CSM asset library | Niche |
| seehiong/blender-mcp-n8n | 70+ tools, granular per-operation | Niche but interesting |
| youichi-uda/blender-mcp-pro ($15) | 120+ tools incl. Geometry Nodes, rigging, UV, baking | Paid |
| [BlenderGPT](https://github.com/gd3kr/BlenderGPT) | Text → bpy code; no MCP | Pre-MCP era |
| [BlenderRAG](https://arxiv.org/abs/2605.00632) | Chunked API docs → RAG | Blueprint for Track A |
| [LL3M (arxiv 2508.08228)](https://arxiv.org/abs/2508.08228) | Multi-agent GPT-4o + Gemini critique | Closest to streaming feedback loop, but not real-time |
| [3D-Agent.com](https://3d-agent.com) | Commercial Blender plugin, viewport-aware code gen | Proprietary |

**Key gap nobody fills yet:** Continuous viewport stream → LLM → bpy →
loop, with an integrated knowledge corpus. Genuine white space.

## Why pi.dev for Track B

[pi.dev (earendil-works/pi)](https://github.com/earendil-works/pi) is
Mario Zechner's TypeScript multi-provider coding agent — essentially
a lighter, more extensible Claude Code clone:

- MIT licensed, 50k+ stars, v0.74 May 2026
- `pi-ai` supports 15+ providers including Google (Gemini)
- `defineTool()` runtime extension — write a TypeScript tool, register
  it without forking core
- 4 execution modes: TUI, print, RPC, SDK

**Caveats:**
- `pi-ai` is request/response abstraction. Gemini Live API is
  WebSocket bidirectional. Would need extension or sidecar.
- MCP not first-class (third-party adapter exists)

Plausible path: write `blender-tools` as pi extensions, and a
`gemini-live-bridge` extension that handles the WebSocket + injects
function calls into pi's tool loop. ~4-6 weeks solo.

## Why two-layer knowledge

A single user-editable corpus has two failure modes:
1. Personal preferences pollute the foundational layer
2. Foundational updates overwrite user customizations

Splitting into foundational + per-user user-layer collections solves
both. Both queried together; user-layer wins on overlap. Foundational
evolves via PRs (including promotions from user layers). User layer
captures taste, workflow, project conventions over time and is
portable across machines (just a git repo).

The pattern generalizes — should work for any expert domain where:
- A foundational reference exists (docs, manuals)
- Personal taste / project conventions matter
- The user accumulates expertise over months
- Multiple users want different specializations

Plausible future applications: Houdini, Cinema 4D, AutoCAD, music
production DAWs, video editing tools, statistical computing (R),
spreadsheet modeling.

## Why QMD (vs Pinecone / Chroma / Weaviate / etc.)

QMD constraints turn out to be features for this use case:

- **Local-only** — no cloud round-trip, no per-query cost, no API key
- **File-based** — `git diff`-able, PR-able, human-auditable
- **Hybrid BM25 + vector** — tags work even before embeddings exist
- **Markdown native** — content + index in the same format
- **Tobi-maintained** — active, MIT, npm-distributed
- **Has packaged skill** (`qmd skill show`) — Claude integration done

Trade-off: scale ceiling lower than dedicated vector DBs. Acceptable
for a corpus aiming at ~1,000-3,000 chunks total.

## Open research questions

1. Does the eval show product viz works without streaming, given a
   strong corpus + skill? If yes, Track B (streaming) is optional, not
   essential.
2. Is Gemini's bpy code generation quality competitive with Claude's
   on the same eval set? BlenderRAG showed Claude Sonnet 4.5 ahead on
   raw code-compile rate; streaming may not compensate.
3. What's the right token budget per shot iteration? Need numbers
   from eval to set ceiling.
4. Can the two-layer pattern be packaged as a generic Claude Code
   meta-skill (apply to any domain)?

## Sources

Primary:
- [BlenderRAG paper](https://arxiv.org/abs/2605.00632)
- [LL3M paper](https://arxiv.org/abs/2508.08228)
- [Gemini Live API docs](https://ai.google.dev/gemini-api/docs/live-api)
- [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
- [Anthropic Blender Connector tutorial](https://claude.com/resources/tutorials/using-the-blender-connector-in-claude)
- [Lush Binary guide (Apr 2026)](https://lushbinary.com/blog/claude-blender-mcp-connector-3d-modeling-guide/)
- [MindStudio real-world performance (May 2026)](https://www.mindstudio.ai/blog/claude-blender-mcp-real-world-performance)
- [MindStudio token burn test](https://www.mindstudio.ai/blog/claude-blender-mcp-60-percent-tokens-donut-test-results)
- [dev.to: Blender-MCP to 3D-Agent evolution](https://dev.to/glglgl/from-blender-mcp-to-3d-agent-the-evolution-of-ai-powered-blender-modeling-1m7d)
- [pi.dev / earendil-works/pi](https://github.com/earendil-works/pi)
- [QMD / tobi/qmd](https://github.com/tobi/qmd)

Secondary:
- Hackaday MCP Blender community thread
- Hacker News [44622374](https://news.ycombinator.com/item?id=44622374)
- GitHub: blender-orchestrator (spatial-reasoning patch project)
- GitHub: blender-mcp-Geometry_Nodes fork
