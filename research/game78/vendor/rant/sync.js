function shuffle(n, rng) {
    const a = Array.from({
        length: n
    }, (_, i)=>i);
    for(let i = a.length - 1; i > 0; i--){
        const j = rng.int(i + 1);
        [a[i], a[j]] = [
            a[j],
            a[i]
        ];
    }
    return a;
}
export function parseSyncType(s) {
    const t = s.trim().toLowerCase();
    if (t === "locked" || t === "deck" || t === "cdeck" || t === "forward" || t === "reverse" || t === "no-repeat") {
        return t;
    }
    return "none";
}
export function pickSynced(ctx, name, count) {
    if (count <= 0) return 0;
    let state = ctx.syncs.get(name);
    if (!state) {
        state = {
            type: "none",
            index: 0,
            order: [],
            last: -1
        };
        ctx.syncs.set(name, state);
    }
    return nextIndex(state, count, ctx.rng);
}
export function ensureSync(ctx, name, type) {
    let state = ctx.syncs.get(name);
    if (!state) {
        state = {
            type,
            index: 0,
            order: [],
            last: -1
        };
        ctx.syncs.set(name, state);
    } else {
        state.type = type;
    }
    return state;
}
function nextIndex(state, count, rng) {
    switch(state.type){
        case "locked":
            if (state.last < 0 || state.last >= count) state.last = rng.int(count);
            return state.last;
        case "forward":
            {
                const i = state.index % count;
                state.index += 1;
                return i;
            }
        case "reverse":
            {
                const i = (count - 1 - state.index % count + count) % count;
                state.index += 1;
                return i;
            }
        case "deck":
        case "cdeck":
            {
                if (state.order.length === 0) state.order = shuffle(count, rng);
                const i = state.index % state.order.length;
                const picked = state.order[i] ?? 0;
                state.index += 1;
                if (state.index >= state.order.length) {
                    state.index = 0;
                    if (state.type === "deck") state.order = [];
                }
                return picked % count;
            }
        case "no-repeat":
            {
                if (count === 1) return 0;
                let i = rng.int(count);
                if (i === state.last) i = (i + 1) % count;
                state.last = i;
                return i;
            }
        default:
            return rng.int(count);
    }
}
