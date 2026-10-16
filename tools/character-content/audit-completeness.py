"""Inventory claims separately from production-kernel/native/player evidence.

This tool never evaluates rules, qualifies a build or resolves an effect. Dynamic
claims must come from the Godot witness runner using the existing authority.
"""
from pathlib import Path
import argparse, collections, hashlib, json, subprocess

ROOT = Path(__file__).resolve().parents[2]
STAGES = ["indexed", "defined", "selectable", "mechanically_functional", "automated_tested", "player_validated"]


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def walk(value, path=""):
    if isinstance(value, dict):
        yield path, value
        for key, child in value.items():
            yield from walk(child, path + "/" + str(key))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from walk(child, path + "/" + str(index))


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--pack", default="data/rules/trhgd-character-v15.json")
    parser.add_argument("--output", default="docs/implementation/game126/baseline")
    parser.add_argument("--witness", type=Path)
    parser.add_argument("--option-witness", type=Path)
    parser.add_argument("--prestige-witness", type=Path)
    parser.add_argument("--native-receipt", type=Path)
    args = parser.parse_args()
    pack_path = ROOT / args.pack
    pack = load(pack_path)
    ledger = load(ROOT / "docs/implementation/game104/COVERAGE.json")
    witness = load(args.witness) if args.witness else {}
    option_witness = load(args.option_witness) if args.option_witness else {}
    prestige_witness = load(args.prestige_witness) if args.prestige_witness else {}
    native = load(args.native_receipt) if args.native_receipt else {}
    manifest = load(ROOT / "data/rules/packs.json")
    expected_ref = next(p["rules_ref"] for p in manifest["packs"] if p["rules_ref"]["pack_id"] == pack["pack_id"])
    for supplied in [option_witness, prestige_witness, native]:
        if supplied: assert supplied["rules_ref"] == expected_ref, "Evidence must name the exact pack"
    if witness:
        assert witness["rules_ref"] == expected_ref, "Witness must name the exact immutable content"
        assert witness["authority"] == "RulesCharacter/RulesEffects/TacticalCombat"
    tables = {category: {r["id"]: r for r in rows} for category, rows in pack.items() if isinstance(rows, list)}
    by_production = collections.defaultdict(list)
    occurrences = []
    for row in ledger["entries"]:
        for variant in row.get("source_variants", []):
            production = variant.get("production_id", "")
            if production:
                by_production[production].append(variant["key"])
            occurrences.append({"ledger_id": row["id"], "category": row["category"], "source_name": row["source_name"],
                                "source_occurrence": variant, "intended_taxonomy": row.get("intended_implementation", {}),
                                "licensing": row.get("licensing", {}), "classification": "unresolved",
                                "note": "Index occurrence is not a playable production definition or verified sourcebook equivalence."})
    assert len(occurrences) == 760, "Preserve the complete occurrence ledger, including NPC families"
    source_nodes = [(category + "/" + row["id"] + path, node)
                    for category, rows in tables.items() for row in rows.values() for path, node in walk(row)]

    def stages(category, identifier):
        claims = {stage: {"status": "unverified", "evidence": []} for stage in STAGES}
        claims["indexed"] = {"status": "yes" if by_production[identifier] else "original_or_unmapped",
                             "evidence": by_production[identifier]}
        claims["defined"] = {"status": "yes", "evidence": [args.pack + "#" + category + "/" + identifier]}
        dynamic = witness.get("options", {}).get(category, {}).get(identifier, {})
        for stage in ["selectable", "mechanically_functional", "automated_tested"]:
            if stage in dynamic:
                claims[stage] = dynamic[stage]
        selected = option_witness.get("options", {}).get(category, {}).get(identifier, {})
        if selected.get("selectable"):
            claims["selectable"] = {"status": "yes", "evidence": [str(args.option_witness)], "scope": selected["scope"]}
            claims["mechanically_functional"] = {"status": "partial", "evidence": [str(args.option_witness)], "scope": "Derived consequences and lawful selection; conditional tactical effects need separate receipts."}
            claims["automated_tested"] = {"status": "yes", "evidence": [str(args.option_witness)], "scope": selected["scope"]}
        if native:
            claims["native_windows"] = {"status": "verified_scoped_harness", "evidence": [str(args.native_receipt)], "scope": "Exact exported harness; does not imply all conditional effects or human acceptance."}
        # Automated or general Windows acceptance never implies per-option player validation.
        return claims

    classes = []
    for row in pack["classes"]:
        if row.get("class_kind") != "base":
            continue
        identifier = row["id"]
        levels = []
        for level in range(1, 21):
            actual = witness.get("classes", {}).get(identifier, {}).get("levels", {}).get(str(level))
            decision = bool(actual and (actual.get("career_choices") or actual.get("feat") or actual.get("bonus_feats") or actual.get("attribute_increase")))
            levels.append({"level": level,
                           "scheduled_features": [f["id"] for f in row["features"] if f["at"] == level],
                           "scheduled_choices": [g for g in row.get("career_choices", []) if g["at"] == level],
                           "bonus_feat_scheduled": level in row.get("bonus_feat_levels", []),
                           "kernel_witness": actual,
                           "player_decision_scheduled": decision,
                           "status": "kernel_validated" if actual and actual.get("ok") else "kernel_unverified",
                           "interpretation": "No new owned action is not proof of an empty level: feats, attributes, resource/effect scaling and passive features also matter."})
        classes.append({"id": identifier, "name": row["name"], "level_cap": row["max_level"], "levels": levels,
                        "class_skills": row.get("class_skills", []), "proficiencies": row.get("proficiencies", []),
                        "recommended_equipment": row.get("recommended_equipment", []), "requirements": row["requirements"],
                        "signature_description": row.get("description", ""), "stages": stages("classes", identifier),
                        "spell_references_by_tier": {str(tier): [a["id"] for a in pack["abilities"] if a.get("casting_class") == identifier and a.get("spell_tier") == tier and "channel_spell" not in a] for tier in range(1, 10)},
                        "prestige_routes": {key: route for key, route in prestige_witness.get("validated", {}).items() if route["base_class"] == identifier}})
    prestige = [{"definition": c, "stages": stages("classes", c["id"])} for c in pack["classes"] if c.get("class_kind") == "prestige"]
    policy = load(ROOT / "data/sandbox/cycles-v1.json")
    skills = []
    for skill in pack["skills"]:
        identifier = skill["id"]
        families = [family for family, ids in policy["skill_map"].items() if identifier in ids]
        formula_refs = [path for path, node in source_nodes if node.get("op") == "skill_rank" and node.get("id") == identifier]
        prereq_refs = [path for path, node in source_nodes if node.get("op") == "skill" and node.get("id") == identifier]
        contextual = [a for a in pack["rules"].get("skill_approaches", []) if a["skill"] == identifier]
        skills.append({"definition": skill, "class_availability": [c["id"] for c in classes if identifier in c["class_skills"]],
                       "noncombat_check_families_v1": families, "formula_consumers": formula_refs,
                       "prerequisite_consumers": prereq_refs, "contextual_approaches": contextual, "gameplay_consumer_found": bool(families or formula_refs or contextual),
                       "consumer_evidence": ["scripts/sandbox/opportunity_cycles.gd:choices", "data/sandbox/cycles-v1.json"] if families else [],
                       "stages": stages("skills", identifier)})
    options = {}
    for category in ["feats", "features", "abilities", "psychic_powers", "ancestries", "creatures"]:
        options[category] = [{"definition": row, "stages": stages(category, row["id"]),
                              "production_references": [path for path, node in source_nodes
                                                        if node.get("op") in ["feat", "feature", "ancestry"] and node.get("id") == row["id"]]}
                             for row in pack.get(category, [])]
    for occurrence in occurrences:
        variant = occurrence["source_occurrence"]
        production = variant.get("production_id", "")
        ancestry = tables.get("ancestries", {}).get(production)
        if occurrence["category"] == "ancestry" and ancestry:
            occurrence["classification"] = "playable_heritage_record"
            occurrence["mechanical_definition"] = production
            occurrence["family"] = ancestry.get("people_id", "")
            occurrence["note"] = "Bounded original adaptation; custom anatomy art and complete sourcebook equivalence are not implied."
        elif occurrence["category"] == "ancestry" and variant.get("playable"):
            mapped = [a for a in pack["ancestries"] if a.get("people_id") == production]
            if mapped:
                occurrence["classification"] = "playable_ancestry_family"
                occurrence["mechanical_definitions"] = [a["id"] for a in mapped]
    result = {"schema_version": 1, "scope": "Defined inventory plus explicitly scoped production-kernel witnesses; not player acceptance",
              "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "rules_ref": expected_ref, "pack_file_sha256": hashlib.sha256(pack_path.read_bytes()).hexdigest(),
              "research_ledger_sha256": hashlib.sha256((ROOT / "docs/implementation/game104/COVERAGE.json").read_bytes()).hexdigest(),
              "stage_policy": "Native receipt scopes are explicit and never imply player validation. Unresolved research taxonomy remains unresolved.",
              "prestige_witness_scope": prestige_witness.get("scope", "No current-pack route witness supplied"),
              "stages": STAGES, "classes": classes, "prestige_paths": prestige, "skills": skills, **options,
              "research_occurrences": occurrences,
              "witness_scope": witness.get("scope", "No dynamic witness supplied; no executable claim is inferred from JSON or source references.")}
    output = ROOT / args.output
    output.mkdir(parents=True, exist_ok=True)
    (output / "MATRIX.json").write_text(json.dumps(result, indent=2) + "\n")
    summary = {"base_classes": len(classes), "prestige_paths": len(prestige), "skills": len(skills),
               "skills_with_check_or_formula_consumer": sum(s["gameplay_consumer_found"] for s in skills),
               "source_occurrences": len(occurrences), "player_validated_options": "unverified; no per-option human receipt supplied"}
    (output / "SUMMARY.json").write_text(json.dumps(summary, indent=2) + "\n")
    rows = []
    for cls in classes:
        actual = [v for v in cls["levels"] if v["status"] == "kernel_validated"]
        no_new_action = [str(v["level"]) for v in actual if not v["kernel_witness"]["new_owned_abilities"]]
        references = cls["spell_references_by_tier"]
        tiers = ", ".join(f"{t}:{len(ids)}" for t, ids in references.items() if ids) or "none"
        rows.append(f"| {cls['name']} | {len(actual)}/20 | {', '.join(no_new_action) or 'none'} | {tiers} | unverified |")
    report = """# Character completeness — reproducible baseline

This report inventories definitions and scoped production-kernel witnesses. It does not establish tabletop equivalence, complete career mechanics, native Windows acceptance of this new harness, or player validation. Every option has separate stage/evidence fields in MATRIX.json. No per-option human receipt has been supplied.

The legacy coverage ledger retains every source occurrence; unresolved taxonomy remains unresolved. Seven skills have actual opportunity checks. Nature also contributes to spell DC through Natural Scholar; Performance contributes to performance capacity. Formula consumers are not automatically claimed executed by this inventory tool. Baseline v15 leaves Athletics, Stealth, Acrobatics, Spellcraft and Animal Handling without direct consumers. In v16, typed contextual approaches in the immutable pack supply those consumers. Inspect the per-skill records for the selected pack; source references alone are not execution receipts.

## Class progression and repertoire

"No new owned action" is a review prompt, not an empty-level verdict. Inspect feats/attributes, career choices, resources, passives and existing effect scaling. Thin spell tiers are inventories, not automatic design failures. All dynamic records are development fixtures; XP-funded journeys are separate evidence.

| Class | Kernel levels | Levels without a new owned action | Spell references by tier | Player validation |
|---|---:|---|---|---|
""" + "\n".join(rows) + "\n\nPrestige compatibility must use actual permanent-prerequisite witnesses, path caps and legal continuation. Bounded searches cannot prove impossibility; heavily bridged careers must not be presented as natural prestige support for a base class.\n"
    if prestige_witness:
        report += "\n## Prestige compatibility\n\nThese are lawful full-cap development routes with total-level20 continuation, not earned levels or an exhaustive proof of impossibility. Single-class entry is separated from bridge-heavy entry. The original bounded576-pair search retains91 missing witnesses.\n\n| Base | Single-class entry | Multiclass routes | Bridge-dominated subset |\n|---|---|---|---|\n"
        for cls in classes:
            routes = list(cls["prestige_routes"].values())
            single = [r["path"] for r in routes if r["single_class_entry"]]
            bridge = [r["path"] for r in routes if not r["single_class_entry"]]
            dominated = [r["path"] for r in routes if r["bridge_dominates"]]
            report += "| "+cls["name"]+" | "+(", ".join(single) or "none witnessed")+" | "+(", ".join(bridge) or "none witnessed")+" | "+(", ".join(dominated) or "none")+" |\n"
    (output / "REPORT.md").write_text(report)
    print(json.dumps(summary))


if __name__ == "__main__":
    main()
