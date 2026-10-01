/** Replace UTF-16 surrogate code units that cannot be represented by Godot's JSON parser. */
export function sanitizeGodotString(value) {
  let output = "";
  for (let index = 0; index < value.length; index++) {
    const code = value.charCodeAt(index);
    if (code >= 0xd800 && code <= 0xdbff) {
      const next = value.charCodeAt(index + 1);
      if (next >= 0xdc00 && next <= 0xdfff) {
        output += value[index] + value[index + 1];
        index++;
      } else {
        output += "\uFFFD";
      }
    } else if (code >= 0xdc00 && code <= 0xdfff) {
      output += "\uFFFD";
    } else {
      output += value[index];
    }
  }
  return output;
}

/** Recursively sanitize strings and keys, while sorting object keys canonically. */
export function canonicalizeForGodot(value) {
  if (typeof value === "string") return sanitizeGodotString(value);
  if (Array.isArray(value)) return value.map(canonicalizeForGodot);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.keys(value)
        .map(key => [sanitizeGodotString(key), canonicalizeForGodot(value[key])])
        .sort(([left], [right]) => left.localeCompare(right))
    );
  }
  return value;
}

export function stringifyCanonicalJson(value) {
  return `${JSON.stringify(canonicalizeForGodot(value), null, 2)}\n`;
}
