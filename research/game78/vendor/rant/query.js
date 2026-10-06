import { resolveTableName } from "./aliases.js";
import { buildTableIndex } from "./dictionary/index-table.js";
function tableOf(dictionary, name) {
    if (!name) return undefined;
    const mapped = resolveTableName(name);
    return dictionary.tables[mapped] ?? dictionary.tables[name];
}
function matchesClass(entry, cls) {
    const classes = entry.classes;
    if (classes.includes(cls)) return true;
    if (cls === "male" && classes.includes("male?")) return true;
    if (cls === "female" && classes.includes("female?")) return true;
    if (cls === "neutral") {
        return classes.includes("neutral") || classes.includes("male?") && classes.includes("female?");
    }
    return false;
}
function formOf(entry, index) {
    if (entry.forms.length === 0) return "";
    return entry.forms[index] ?? entry.forms[0] ?? "";
}
function intersectSorted(a, b) {
    const out = [];
    let i = 0;
    let j = 0;
    while(i < a.length && j < b.length){
        const av = a[i];
        const bv = b[j];
        if (av === bv) {
            out.push(av);
            i += 1;
            j += 1;
        } else if (av < bv) i += 1;
        else j += 1;
    }
    return out;
}
function indexOf(table) {
    if (table.byClass && table.hasNsfw !== undefined) {
        return {
            byClass: table.byClass,
            hasNsfw: table.hasNsfw
        };
    }
    return buildTableIndex(table.entries);
}
function selectEntries(table, classes, exclude, nsfw) {
    const { byClass, hasNsfw } = indexOf(table);
    const wantNsfw = nsfw || classes.includes("nsfw");
    let idxs;
    for (const cls of classes){
        if (cls === "nsfw") continue;
        const bucket = byClass[cls];
        if (!bucket || bucket.length === 0) return [];
        idxs = idxs ? intersectSorted(idxs, bucket) : bucket;
    }
    let list;
    if (idxs) list = idxs.map((i)=>table.entries[i]);
    else list = table.entries;
    if (hasNsfw && !wantNsfw) {
        list = list.filter((e)=>!e.classes.includes("nsfw"));
    }
    for (const cls of exclude){
        list = list.filter((e)=>!matchesClass(e, cls));
    }
    return list;
}
export function resolveQuery(query, ctx) {
    if (query.carrier && query.carrierKind !== "unique") {
        const hit = ctx.matchCarriers.get(query.carrier);
        if (hit) return hit;
    }
    if (query.carrier && !query.table && query.carrierKind !== "unique") {
        return ctx.matchCarriers.get(query.carrier) ?? "";
    }
    if (!query.table) {
        return query.carrier ? "" : `<${query.raw}>`;
    }
    const table = tableOf(ctx.dictionary, query.table);
    if (!table) return `<${query.raw}>`;
    let formIndex = 0;
    const classes = [];
    for (const arg of query.args){
        const subIdx = table.subs.indexOf(arg);
        if (subIdx >= 0) formIndex = subIdx;
        else classes.push(arg);
    }
    let entries = selectEntries(table, classes, query.exclude, ctx.nsfw);
    if (query.carrier && query.carrierKind === "unique") {
        const used = ctx.uniqueCarriers.get(query.carrier) ?? new Set();
        entries = entries.filter((e)=>!used.has(formOf(e, formIndex)));
    }
    if (entries.length === 0) return `<${query.raw}>`;
    const entry = ctx.rng.pick(entries);
    const value = formOf(entry, formIndex);
    if (query.carrier) {
        if (query.carrierKind === "unique") {
            const used = ctx.uniqueCarriers.get(query.carrier) ?? new Set();
            used.add(value);
            ctx.uniqueCarriers.set(query.carrier, used);
        } else {
            ctx.matchCarriers.set(query.carrier, value);
        }
    }
    if (ctx.trace) {
        ctx.trace.push({
            table: table.name,
            args: query.args,
            value,
            carrier: query.carrier
        });
    }
    return value;
}
