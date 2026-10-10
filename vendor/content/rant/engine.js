import { parse } from "./parse/parser.js";
import { interpret } from "./interpret.js";
import { createRng } from "./rng.js";
import { isDictionary, indexDictionary } from "./dictionary/types.js";
import { createContext } from "./runtime.js";
const CACHE_CAP = 32;
let defaultDictionary;
export function setDefaultDictionary(dict) {
    defaultDictionary = indexDictionary(dict);
}
function resolveDictionary(value) {
    const dict = value ?? defaultDictionary;
    if (!dict) {
        throw new Error('rantjs: no dictionary. Pass { dictionary } or import from "rantjs".');
    }
    return value ? indexDictionary(value) : dict;
}
function optionsFromSecond(second) {
    if (second == null) return {};
    if (isDictionary(second)) return {
        dictionary: second
    };
    return second;
}
function runAst(ast, options, rng, trace = null) {
    const dict = resolveDictionary(options.dictionary);
    const ctx = createContext(rng, dict, options.nsfw ?? false, trace);
    return interpret(ast, ctx);
}
export function compile(pattern, defaults = {}) {
    const ast = parse(pattern);
    return {
        run (options = {}) {
            const merged = {
                dictionary: options.dictionary ?? defaults.dictionary,
                nsfw: options.nsfw ?? defaults.nsfw,
                seed: options.seed ?? defaults.seed
            };
            return runAst(ast, merged, createRng(merged.seed));
        }
    };
}
export function createRant(options = {}) {
    const defaultRng = createRng(options.seed);
    const baseDict = resolveDictionary(options.dictionary);
    const baseNsfw = options.nsfw ?? false;
    const cache = new Map();
    function astFor(pattern) {
        const hit = cache.get(pattern);
        if (hit) return hit;
        const ast = parse(pattern);
        if (cache.size >= CACHE_CAP) {
            const first = cache.keys().next().value;
            if (first !== undefined) cache.delete(first);
        }
        cache.set(pattern, ast);
        return ast;
    }
    const instance = {
        run (pattern, runOptions = {}) {
            const rng = runOptions.seed !== undefined ? createRng(runOptions.seed) : defaultRng;
            return runAst(astFor(pattern), {
                dictionary: runOptions.dictionary ?? baseDict,
                nsfw: runOptions.nsfw ?? baseNsfw
            }, rng);
        },
        compile (pattern) {
            const ast = astFor(pattern);
            return {
                run (runOptions = {}) {
                    const rng = runOptions.seed !== undefined ? createRng(runOptions.seed) : defaultRng;
                    return runAst(ast, {
                        dictionary: runOptions.dictionary ?? baseDict,
                        nsfw: runOptions.nsfw ?? baseNsfw
                    }, rng);
                }
            };
        }
    };
    return instance;
}
export function rant(pattern, second) {
    const options = optionsFromSecond(second);
    return compile(pattern, options).run();
}
export function explain(pattern, second) {
    const options = optionsFromSecond(second);
    const ast = parse(pattern);
    const picks = [];
    const text = runAst(ast, options, createRng(options.seed), picks);
    return {
        text,
        picks
    };
}
