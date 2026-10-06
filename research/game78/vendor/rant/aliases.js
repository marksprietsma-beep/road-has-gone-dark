export const TABLE_ALIASES = {
    name: "firstname",
    pro: "pron",
    with: "preposition"
};
export const ARG_ALIASES = {
    pl: "plural",
    dposs: "poss"
};
export function resolveTableName(name) {
    const lower = name.toLowerCase();
    return TABLE_ALIASES[lower] ?? lower;
}
export function resolveArgName(name) {
    const lower = name.toLowerCase();
    return ARG_ALIASES[lower] ?? lower;
}
