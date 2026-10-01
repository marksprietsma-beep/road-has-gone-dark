import assert from "node:assert/strict";
import test from "node:test";
import {
  canonicalizeForGodot,
  sanitizeGodotString,
  stringifyCanonicalJson
} from "../../tools/worldgen/canonical-json.mjs";

test("preserves ordinary Unicode and valid surrogate pairs", () => {
  assert.equal(sanitizeGodotString("Café 🌍"), "Café 🌍");
});

test("replaces only unpaired lead and trail surrogates", () => {
  assert.equal(sanitizeGodotString("a\ud800b\udc00c"), "a�b�c");
});

test("recursively sanitizes values and object keys", () => {
  assert.deepEqual(canonicalizeForGodot({"bad\ud800": ["value\udc00"]}), {
    "bad�": ["value�"]
  });
});

test("serializes with stable canonical ordering", () => {
  assert.equal(stringifyCanonicalJson({z: 1, a: {d: 4, b: 2}}), [
    "{",
    '  "a": {',
    '    "b": 2,',
    '    "d": 4',
    "  },",
    '  "z": 1',
    "}",
    ""
  ].join("\n"));
});
