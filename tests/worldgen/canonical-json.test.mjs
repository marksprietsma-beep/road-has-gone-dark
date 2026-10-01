import assert from "node:assert/strict";
import test from "node:test";
import {
  canonicalize,
  findLoneSurrogate,
  sanitizeUnicode,
  stringifyCanonical
} from "../../tools/worldgen/canonical-json.mjs";

test("replaces only unpaired UTF-16 surrogates", () => {
  assert.equal(sanitizeUnicode("a\ud800b\udc00c"), "a\uFFFDb\uFFFDc");
  assert.equal(sanitizeUnicode("\ud800\ud800\udc00\udc00"), "\uFFFD\ud800\udc00\uFFFD");
});

test("preserves valid Unicode including astral characters", () => {
  const value = "plain café 🗺️";
  assert.equal(sanitizeUnicode(value), value);
  assert.equal(findLoneSurrogate(value), -1);
});

test("sanitizes nested values and keys while sorting object keys", () => {
  assert.deepEqual(canonicalize({z: ["\udfff"], "bad\ud800": {a: "ok"}}), {
    "bad\uFFFD": {a: "ok"},
    z: ["\uFFFD"]
  });
  assert.equal(stringifyCanonical({z: 1, a: 2}), '{\n  "a": 2,\n  "z": 1\n}\n');
});

test("rejects object-key collisions caused by sanitization", () => {
  assert.throws(() => canonicalize({"x\ud800": 1, "x\udfff": 2}), /duplicate object key/);
});

test("reports the first malformed UTF-16 offset", () => {
  assert.equal(findLoneSurrogate("ok\ud800bad"), 2);
  assert.equal(findLoneSurrogate("ok\udc00bad"), 2);
});
