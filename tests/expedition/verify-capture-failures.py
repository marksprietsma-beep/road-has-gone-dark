"""Expected failures must exit promptly, rather than abandon a live Godot tree."""
import os
from pathlib import Path
import subprocess
import time

root = Path(__file__).resolve().parents[2]
engine = os.environ.get("GODOT_BIN", "godot")
output = Path(os.environ.get("GAME97_EVIDENCE_ROOT", root/"docs/implementation/game97/evidence"))
output.mkdir(parents=True, exist_ok=True)
# Fresh Actions checkouts have no global GDScript class cache. Import before
# loading the inherited driver, rather than rely on a previous positive run.
imported = subprocess.run([engine, "--headless", "--audio-driver", "Dummy",
                           "--editor", "--path", str(root), "--quit"],
                          capture_output=True, text=True, encoding="utf-8", timeout=180)
import_log = imported.stdout + imported.stderr
(output/"capture-failure-import.log").write_text(import_log, encoding="utf-8")
assert imported.returncode == 0 and "ERROR:" not in import_log, import_log
for case, message in [("assertion", "GAME97 expected assertion failure"),
                      ("offscreen", "mouse target outside viewport after follow-focus")]:
    start = time.monotonic()
    run = subprocess.run([engine, "--audio-driver", "Dummy", "--path", str(root),
                          "--script", "tests/expedition/capture-failure.gd"],
                         env=dict(os.environ, GAME97_CAPTURE_FAILURE=case),
                         capture_output=True, text=True, encoding="utf-8", timeout=30)
    text = run.stdout + run.stderr
    (output/("expected-capture-"+case+".log")).write_text(text, encoding="utf-8")
    assert run.returncode == 1 and message in text, (case, run.returncode, text)
    assert "SCRIPT ERROR" not in text, text
    print(f"PASS expected {case} failure exits 1 in {time.monotonic()-start:.2f}s")
