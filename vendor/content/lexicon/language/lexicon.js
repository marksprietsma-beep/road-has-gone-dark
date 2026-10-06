import { generateWord } from "./phonotactics.js";
export function buildLexicon(culture, ctx) {
    const cultureCtx = ctx.child(`lang:${culture.id}`);
    const cache = new Map();
    const allMeanings = new Map();
    for (const pack of culture.meaningPacks){
        for (const meaning of pack.meanings){
            allMeanings.set(meaning.id, {
                class: meaning.class,
                tags: meaning.tags,
                label: meaning.label
            });
        }
    }
    return {
        cultureId: culture.id,
        formOf (meaningId) {
            let form = cache.get(meaningId);
            if (form !== undefined) return form;
            const wordCtx = cultureCtx.child(`word:${meaningId}`);
            form = generateWord(culture.glyphs, wordCtx);
            cache.set(meaningId, form);
            return form;
        },
        byClass (c, tag) {
            const result = [];
            for (const pack of culture.meaningPacks){
                for (const meaning of pack.meanings){
                    if (meaning.class !== c) continue;
                    if (tag && !meaning.tags.includes(tag)) continue;
                    result.push(meaning);
                }
            }
            return result;
        },
        materialize () {
            const result = new Map();
            for (const meaningId of allMeanings.keys()){
                result.set(meaningId, this.formOf(meaningId));
            }
            return result;
        }
    };
}
