#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$ROOT/tools/worldgen/.tmp"
SEED="${1:-game-11-determinism}"
mkdir -p "$TMP"
"$ROOT/tools/worldgen/generate-world.sh" --seed "$SEED" --output "$TMP/first.json"
"$ROOT/tools/worldgen/generate-world.sh" --seed "$SEED" --output "$TMP/second.json"
cmp "$TMP/first.json" "$TMP/second.json"
sha256sum "$TMP/first.json"
node "$ROOT/tests/worldgen/validate-fixture.mjs" "$TMP/first.json"
