"""Eval harness — score Claude+MCP performance on product-viz tasks.

Planned implementation. Not yet executable.

Reads `eval/tasks.md`, runs each task against a configured backend
(Claude + ahujasid MCP for v1), writes outputs to `eval/runs/<ts>/`:

```
eval/runs/2026-05-16T143000Z/
  config.json          # backend, model, corpus state
  task-01-perfume/
    transcript.jsonl   # full Claude turns
    renders/           # final + intermediate renders
    screenshots/       # viewport captures during run
    metrics.json       # tokens, iterations, errors, completion bool
  task-02-mug/
    ...
  summary.csv          # one row per task
  summary.md           # human-readable diff vs prior run
```

Backend abstraction:

```python
class Backend:
    def run(self, task: Task) -> RunResult: ...

class ClaudeMcpBackend(Backend):
    """Claude Sonnet 4.x via Claude Desktop + ahujasid blender-mcp."""

class ClaudeMcpQmdBackend(Backend):
    """Same as above + blender-knowledge QMD collection loaded."""

class GeminiLiveBackend(Backend):
    """Gemini 2.5 Flash Live API + pi-extension Blender bridge."""
    # Future: Track B
```

Comparison runs:
1. Baseline (no corpus)
2. +API chunks only
3. +API + recipes
4. +API + recipes + gotchas

Human scoring step: after each task, prompt user for 1-5 quality
rating on the final render. Capture in metrics.json. Render images
are presented blind (random task order, no backend label).
"""

if __name__ == "__main__":
    raise SystemExit("eval_runner.py not yet implemented. See docstring.")
