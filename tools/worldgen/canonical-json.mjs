/** Replace malformed UTF-16 code units while preserving valid surrogate pairs. */
export function sanitizeUnicode(value) {
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

/** Recursively sanitize strings and sort object keys for stable serialization. */
export function canonicalize(value) {
  if (typeof value === "string") return sanitizeUnicode(value);
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.keys(value).sort().map(key => [sanitizeUnicode(key), canonicalize(value[key])])
    );
  }
  return value;
}

export function serializeCanonicalJson(value) {
  return `${JSON.stringify(canonicalize(value), null, 2)}\n`;
}
