# Actual Godot review captures

All 69 captures come from Godot 4.6.3 with Mesa rendering, at 640×360, 1280×720 and 2560×1440. The file hashes and development-fixture labels are in [evidence/screenshots.json](evidence/screenshots.json). Gameplay/UI source: `215bbe8c416b0f2569f434d448ed98a9f0034a72`.

| Review point | 1280×720 capture | Evidence type |
|---|---|---|
| First-open creator | [Creator](screenshots/first-open-catalogue-1280x720.png) | Actual new campaign |
| Core and alternative classes | [Class selector](screenshots/available-core-and-alternative-classes-1280x720.png) | Actual new campaign |
| Ancestry choices | [Race selector](screenshots/available-ancestry-families-1280x720.png) | Actual new campaign |
| Tiefling Psion traits | [Psion](screenshots/create-psion-tiefling-1280x720.png) | Actual new campaign |
| Steelbound Warblade | [Warblade](screenshots/create-warblade-steelbound-1280x720.png) | Actual new campaign |
| Combat | [Battle](screenshots/new-classes-combat-1280x720.png) | Actual objective and saved commands |
| Mind Thrust | [Effect](screenshots/actual-psion-technique-1-effect-1280x720.png) | Actual saved combat action |
| Eldritch Blast | [Effect](screenshots/actual-warlock-technique-1-effect-1280x720.png) | Actual saved combat action |
| Warblade manoeuvre | [Effect](screenshots/actual-warblade-technique-1-effect-1280x720.png) | Actual saved combat action |
| Earned advancement | [Level two](screenshots/earned-new-class-level2-1280x720.png) | Already-earned XP, committed through the existing save owner |
| Wizard level 20 | [Sheet](screenshots/development-wizard-sheet-1280x720.png) | Explicit development fixture |
| Tier-nine prepared spells | [Spellbook](screenshots/development-tier9-spells-1280x720.png) | Explicit development fixture |
| Ordered prestige history | [Shadowdancer history](screenshots/development-shadowdancer-history-1280x720.png) | Explicit development fixture |

The isolated earned-action campaign completed another existing contextual cycle, reached 80 earned XP, used all three new class powers, matched authoritative command hashes and reloaded successfully (172 checks, zero errors). The original new-party capture passed 240 checks. Advanced fixtures show implemented high-level controls and saves; they do not claim that level 20 was earned in ordinary play. The separate sustainable-XP regression verifies genuinely earned prestige entry and advancement.

Raw failed diagnostic captures and final successful logs are retained in `evidence/`. Mesa VSync and ObjectDB diagnostic-shutdown warnings remain visible in those logs.
