# GAME-86 standalone research

Resume the original 19,456-battle design on Linux, Python 3.12+, standard library only:

```sh
python3 -m unittest discover -s research/game86 -v
python3 research/game86/run.py --workers 4
python3 research/game86/report.py
```

Run from the repository root. Existing committed checkpoints are validated and reused; a fresh independent run needs a new `--output` directory. A changed simulator/runner/diagnostic source or case design rejects stale checkpoints. `--group PREFIX` shards explicitly and reports partial completion. Do not remove scheduled seeds to obtain a passing report.

See [runtime/checkpoint evidence](../../docs/research/game86/RUNTIME.md), [results](../../docs/research/game86/SIMULATION-RESULTS.md), [candidate comparison](../../docs/research/game86/MODEL-COMPARISON.md), [recommended values and class answers](../../docs/research/game86/RECOMMENDATION.md) and the GAME-32–35 contracts in that directory.

Raw deterministic artifacts, per-group resumable records, timings and original-code equivalence proofs are retained in `results/`. The latest `timing.json` may describe a resume; use `timings/` for fresh-run measurements. `.runner.lock`, interrupted temporary files and Python bytecode are local outputs. No production game logic, Godot scenes or save schemas are implemented here.
