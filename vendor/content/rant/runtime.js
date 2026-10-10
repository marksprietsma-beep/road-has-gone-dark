export function defaultAttrs() {
    return {
        rep: 1,
        chance: 100
    };
}
export function createContext(rng, dictionary, nsfw, trace = null) {
    return {
        rng,
        dictionary,
        nsfw,
        matchCarriers: new Map(),
        uniqueCarriers: new Map(),
        caseMode: "default",
        numfmt: "normal",
        chunks: [],
        capture: null,
        attrs: defaultAttrs(),
        syncs: new Map(),
        pendingArticle: false,
        repIndex: 0,
        trace
    };
}
export function write(ctx, s) {
    if (!s) return;
    if (ctx.capture) {
        ctx.capture[ctx.capture.length - 1] = (ctx.capture[ctx.capture.length - 1] ?? "") + s;
        return;
    }
    ctx.chunks.push(s);
}
export function capture(ctx, fn) {
    ctx.capture = ctx.capture ?? [];
    ctx.capture.push("");
    fn();
    const s = ctx.capture.pop() ?? "";
    if (ctx.capture.length === 0) ctx.capture = null;
    return s;
}
export function finish(ctx) {
    return ctx.chunks.join("");
}
