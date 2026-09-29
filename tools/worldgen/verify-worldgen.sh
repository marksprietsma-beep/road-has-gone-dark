#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$ROOT/tools/worldgen/.tmp"
SEED="${1:-game-11-determinism}"
FIXTURE_DIR="$ROOT/tests/worldgen/fixtures"
FIXTURE="$FIXTURE_DIR/game-11-determinism.json"
MANIFEST="$FIXTURE_DIR/game-11-determinism.meta.json"

mkdir -p "$TMP"
"$ROOT/tools/worldgen/generate-world.sh" --seed "$SEED" --output "$TMP/first.json"
"$ROOT/tools/worldgen/generate-world.sh" --seed "$SEED" --output "$TMP/second.json"

# Same seed + pinned provider must be byte-for-byte stable.
cmp "$TMP/first.json" "$TMP/second.json"
ACTUAL="$(sha256sum "$TMP/first.json" | awk '{print $1}')"
echo "$ACTUAL  $TMP/first.json"
node "$ROOT/tests/worldgen/validate-fixture.mjs" "$TMP/first.json"

# The canonical regression fixture is tied to the default acceptance seed.
if [[ "$SEED" == "game-11-determinism" ]]; then
  [[ -f "$FIXTURE" ]] || { echo "missing checked-in fixture: $FIXTURE" >&2; exit 1; }
  [[ -f "$MANIFEST" ]] || { echo "missing fixture manifest: $MANIFEST" >&2; exit 1; }

  EXPECTED="$(node -e 'const fs=require("fs"); console.log(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).sha256)' "$MANIFEST")"
  [[ "$ACTUAL" == "$EXPECTED" ]] || {
    echo "fixture hash mismatch: expected $EXPECTED, got $ACTUAL" >&2
    exit 1
  }

  cmp "$TMP/first.json" "$FIXTURE"
  node "$ROOT/tests/worldgen/validate-fixture.mjs" "$FIXTURE"
  echo "fixture matches generated output: $FIXTURE"
fi
