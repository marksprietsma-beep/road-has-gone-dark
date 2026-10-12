# GAME-118 Windows review delivery

[Draft PR88](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/88), stacked on unmerged draft PR81. PR80/81/88 remain drafts. No merge performed.

**[Download the self-contained Windows x64 build](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38223873830/artifacts/11736109448).** GitHub downloads an outer artifact ZIP: extract it, then extract `game118-playable-core-characters-windows-x64.zip`. Open its folder and run `road-has-gone-dark.exe`. Keep the helper/artwork beside it. No Godot or Node installation is required. Escape skips the intro. The build is unsigned.

Playable ZIP SHA-256:

```
19ab5adce02ca83ac9605c75aee9f7ff2ca19bd58cce5d32c06e2e85d5e8f980
```

Build/source commit: `de63453c83e6451b8929e708f3e1e5a9e559ca38`. Implementation commits: `1d7d26d6a9d5aada1374bbbee8591fb3c944abe8` (core content/default creator), `a461936ad25d4186cb8d94e0596dc072b06abfa3` (atomic fresh party/pin), `de63453` (pending card/class/portrait consistency). Later delivery commits contain documentation and evidence only; production equivalence is checked before publication.

Fresh-pack **actually playable starting counts**: **7 race families / 10 heritage records; 11 classes; 0 prestige classes; 18 feats**. Class progression and tactical powers are implemented/verified through six. Actual player journeys demonstrate three characters earning and committing level two after real combat XP. These are original TRHGD core-archetype adaptations, not complete tabletop conversions. The full 403 ancestry / 66 base / approximately 283 prestige catalogue remains open; its coverage spreadsheet is not counted as playable content.

## Exact player test

1. **New Game** → generate/select world → origin → hometown → creator. The first **Race & class** page must offer the eleven familiar classes and seven ancestry families without a content button or configuration.
2. Build a Dwarf Fighter, Half-elf Rogue and Elf Wizard. **Build** contains Attributes, Skills, Feats, Equipment, Spells and Progression. Review numerical ancestry effects and abilities in **Sheet**, save each, then **Party ready → Enter hometown**. Pending cards/biographies/sheets reflect edited choices before saving.
3. Prepare a contextual opportunity, scout/travel to a contested site and fight. Use class techniques and spells; the Wizard's individual prepared copies and total tier slots both limit casts. Win, return to regional play, return home.
4. **Characters → Advance**: earned 10 XP funds level two under the new core policy. Review skill ranks and any scheduled general/bonus feat, commit once. **Spellbook** changes prepared copies at home, preserves shared remaining slots and retains learned spontaneous spells.
5. Exit, relaunch and Resume. Identities, numerical traits, class history, equipment, spell selections/resources, XP and consequences must reload. Existing campaigns keep their original exact packs/policies and old options; use a fresh New Game to review this content. Do not delete existing saves.

More detail/scenes: [TESTING.md](TESTING.md). Features and explicit continuation: [IMPLEMENTATION.md](IMPLEMENTATION.md).

## Verified evidence

[Windows/Linux complete release workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38223873830) passed on the build source. Each OS passed:

- 5,064 core creation/progression/equipment/score/preparation checks, including all eleven classes across all ten heritages through six.
- 1,987 genuine tactical-power checks, exact state/log/RNG replay, prepared-copy exhaustion, save-for-half and Evasion.
- Frozen GAME32 **22,181** checks, **235** existing-save migration checks and **6** restart checks. Published v1/v2/v3 data and old XP policy remain unchanged.
- Prior v3 twenty-level combinations **3,721** checks; original builder **150 + 5 + 25 + 26**, atomic fresh-generation/interruption/retry **7** checks; original First Adventure combat/save and GAME83 presentation gates.
- Ten generated-world/fourty-context V1/V2 regressions and production journeys. Final native export: **998** journey checks and **54** separate-process restart checks, including original GAME99 campaign continuation. Empty PATH, bundled helper only, production executable launch, no diagnostic executable in the package.

All ten source workflows are successful, including separate [GAME32](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38223878874), [GAME83 UI](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38223878810), and [party/expedition native checks](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38223878827).

Local real Godot renders additionally passed **1,125** journey checks and **54** fresh-process checks; final creator/sheet capture driver **62** checks. Twenty-seven PNGs are retained under screenshots/, with individual hashes/source revisions in evidence/screenshots.json. Source geometry fixtures were reused for these focused visual captures; native release tests generated/select worlds through the normal offline controller.

Archive integrity independently checked: **7,062 files**, CRC valid, published checksum matches, executable/Node/helper/art attribution/immutable rule manifest/both progression policies present, QA executable absent. See evidence/windows-archive-verification.json and native Windows/Linux proofs/timings.

## Remaining scope

Human acceptance is pending. This is a low-level playable batch. Core progression beyond six, larger repertoires and parameterised domains/bloodlines/quarries, full companions/summons, advanced class/equipment/feat options and prestige paths remain programme work. Current regional opportunities are finite and limit organically attainable higher XP. World presence metadata remains the legacy prototype layer. LPC provides neutral humanoid fallbacks for unsupported ancestry anatomy and bear form; small bodies scale down and Monk presentation is unarmed. No completed final ancestry roster or complete source-catalogue conversion is claimed.

[Programme #82](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/82) and children #83–87 remain open, with concrete playable continuation recorded. No Linear update is claimed.
