import { buildTableIndex } from "./index-table.js";
export function isDictionary(value) {
    return Boolean(value && typeof value === "object" && "tables" in value && value.tables && typeof value.tables === "object");
}
export function indexDictionary(dict) {
    let changed = false;
    const tables = {};
    for (const [key, table] of Object.entries(dict.tables)){
        if (table.byClass && table.hasNsfw !== undefined) {
            tables[key] = table;
            continue;
        }
        changed = true;
        const { byClass, hasNsfw } = buildTableIndex(table.entries);
        tables[key] = {
            ...table,
            byClass,
            hasNsfw
        };
    }
    return changed ? {
        tables
    } : dict;
}
