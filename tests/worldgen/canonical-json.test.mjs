import assert from "node:assert/strict";
import test from "node:test";
import {canonicalize, sanitizeUnicode, serializeCanonicalJson} from "../../tools/worldgen/canonical-json.mjs";

test("preserves ordinary Unicode and valid surrogate pairs", () => {
  assert.equal(sanitizeUnicode("Café 🌍"), "Café 🌍");
});

test("replaces only unpaired UTF-16 surrogates", () => {
  assert.equal(sanitizeUnicode("a\ud800b\udc00c\ud83d\ude00d"), "a�b�c😀d");
  assert.equal(sanitizeUnicode("\ud800\ud800\udc00\udc00"), "�𐀀�");
});

test("recursively sanitizes values and object keys", () => {
  assert.deepEqual(canonicalize({"bad\ud800": ["x\udc00"]}), {"bad�": ["x�"]});
});

test("serializes object keys in stable lexical order", () => {
  assert.equal(serializeCanonicalJson({z: 1, a: {d: 2, b: 3}}),
    '{\n  "a": {\n    "b": 3,\n    "d": 2\n  },\n  "z": 1\n}\n');
});
