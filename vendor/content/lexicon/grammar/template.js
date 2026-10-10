export function t(strings, ...interpolations) {
    let out = "";
    for(let i = 0; i < strings.length; i++){
        out += strings[i];
        if (i < interpolations.length) {
            const v = interpolations[i];
            if (typeof v === "string") {
                out += `#${v}#`;
            } else if (typeof v === "number" || typeof v === "boolean") {
                out += String(v);
            } else if (v == null) {
                out += "";
            } else {
                out += String(v);
            }
        }
    }
    return out;
}
