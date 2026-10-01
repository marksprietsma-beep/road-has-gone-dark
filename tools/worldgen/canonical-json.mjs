const LEAD_SURROGATE_START = 0xd800;
const LEAD_SURROGATE_END = 0xdbff;
const TRAIL_SURROGATE_START = 0xdc00;
const TRAIL_SURROGATE_END = 0xdfff;

const isLeadSurrogate = code => code >= LEAD_SURROGATE_START && code <= LEAD_SURROGATE_END;
const isTrailSurrogate = code => code >= TRAIL_SURROGATE_START && code <= TRAIL_SURROGATE_END;

/** Replace malformed UTF-16 code units while leaving valid surrogate pairs intact. */
export function sanitizeUnicode(value) {
  let output = "";
  for (let index = 0; index < value.length; index++) {
    const code = value.charCodeAt(index);
    if (isLeadSurrogate(code)) {
      const next = value.charCodeAt(index + 1);
      if (isTrailSurrogate(next)) {
        output += value[index] + value[index + 1];
        index++;
      } else {
        output += "\uFFFD";
      }
    } else {
      output += isTrailSurrogate(code) ? "\uFFFD" : value[index];
    }
  }
  return output;
}

/** Recursively prepare provider data for stable, valid-Unicode canonical JSON. */
export function canonicalize(value) {
  if (typeof value === "string") return sanitizeUnicode(value);
  if (Array.isArray(value)) return value.map(canonicalize);
  if (!value || typeof value !== "object") return value;

  const output = {};
  for (const key of Object.keys(value).sort()) {
    const safeKey = sanitizeUnicode(key);
    if (Object.hasOwn(output, safeKey)) {
      throw new Error(`Unicode sanitization produced duplicate object key: ${JSON.stringify(safeKey)}`);
    }
    output[safeKey] = canonicalize(value[key]);
  }
  return output;
}

export function stringifyCanonical(value) {
  return `${JSON.stringify(canonicalize(value), null, 2)}\n`;
}

/** Return the UTF-16 offset of the first lone surrogate, or -1. */
export function findLoneSurrogate(value) {
  for (let index = 0; index < value.length; index++) {
    const code = value.charCodeAt(index);
    if (isLeadSurrogate(code)) {
      if (isTrailSurrogate(value.charCodeAt(index + 1))) index++;
      else return index;
    } else if (isTrailSurrogate(code)) {
      return index;
    }
  }
  return -1;
}
