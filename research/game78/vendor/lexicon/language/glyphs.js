export function constraintMatches(pattern, sequence) {
    if (pattern.length > sequence.length) return false;
    for(let i = 0; i < pattern.length; i++){
        const p = pattern[i];
        if (p !== "*" && p !== sequence[i]) return false;
    }
    return true;
}
