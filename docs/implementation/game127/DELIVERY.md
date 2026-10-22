# GAME-127 — verified psychic-class delivery

Ardent, Lurk and Erudite now have bounded, evidence-backed functional acceptance. The full Windows native release passed at `a4ac918a18ed58b9e53e86fe6bcd62824cdf567d`; the generated 50-career matrix is **26 COMPLETE / 24 PARTIAL / 0 BLOCKED**. Human readability/balance acceptance and the wider GAME-123 milestone remain open.

Publication and integration ledger: [PR #145](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/145) and [milestone #101](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/101). Their live records contain the actual merge commit and post-merge Windows conclusions. This document pins the delivered binary and its verification source; subsequent delivery/evidence changes do not change that binary's source.

## Corrections and preserved mechanics

A lawful large-ancestry Lurk could use the authored adjacent ambush from two tiles because the generic weapon-strike adapter inherited normal weapon reach. New immutable **v25** appends typed `requires_adjacent` and `requires_melee` descriptors to Psychic ambush, consumed by the existing TacticalAuras eligibility adapter. Ordinary extra-reach attacks remain legal. The original direct psychic damage and off-balance still precede a separately rolled melee weapon attack: that weapon roll can miss. No action-economy or attack-engine rewrite was made.

Erudite's authority already rejected a new identity after the distinct-per-rest cap, but the real combat buttons and target feedback offered it anyway. Presentation now calls that same existing validator, including on historically pinned v14+ campaigns. It disables and explains the exhausted action while permitting affordable repeats and augmentation of a used identity. This read-only correction changes no accepted action set, resources, save pin or RNG.

Ardent's working mantle system was retained. Native acceptance covers every distinct starting mantle pair and every authored starting-power mantle union, temporary-feature rejection, deliberate offensive/support choices, WIS versus another manifester's INT origin, expenditure, exhaustion and eligible rest. Tier-nine ally support executes on the lawful level-20 development build.

Lurk's working veil spends main/focus for 25% weapon concealment over two global round starts. It is not invisibility. A later adjacent melee ambush spends main/focus/PP and consumes the veil. Tests advance through real turn-end commands, reject same-turn reuse, verify exact psychic damage on a weapon miss and added weapon damage on a hit, apply off-balance, exhaust focus and recover at eligible rest. Starting focus is two, enough for one sequence.

Erudite retains `1 + floor(Erudite level / 4)` distinct identities per eligible rest. Repetition and augmentation share an identity but still cost PP/actions. Encounters and cold restart do not reset the allowance; eligible rest does.

All **v1–v24 pack bytes and exact references remain frozen**. Old campaigns retain their old mechanics, including v24's original ambush reach; they are never silently migrated to v25. The original pre-fix reproduction is separately retained at `d5a611d` / [run 39739126204](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39739126204). Current native historical continuation verifies preserved mechanics and corrected Erudite display, not a fictitious new reproduction of the removed display bug.

## Windows executable

[Download the complete Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39744145580/artifacts/12412669328)

1. Extract the downloaded GitHub artifact ZIP.
2. Extract its inner `game127-psychic-identities-windows-x64.zip`.
3. Keep every support/helper/art/licence file beside `road-has-gone-dark.exe`; launch that executable. No installed Godot or Node is needed. Escape skips intro.
4. Use New Game for v25. Resume retains the exact original campaign pin. Follow [TESTING.md](TESTING.md) for mantle, veil/ambush, distinct-power, earned advancement and restart checks.

SHA-256 of the **inner playable ZIP**:

```text
083bb82f6018f00ff6985064cfe51f187a5d411e6b8383891e4857bb8b7a254c
```

Binary source: `a4ac918a18ed58b9e53e86fe6bcd62824cdf567d`.

Rules: `trhgd-character-v25`, content hash `c828f3cb74005a4b602bd5986fa96549905a0699dd780e75d7bb40c84b7c98a7`.

The independent [archive audit](evidence/archive-audit.json) verifies CRC integrity, 7,061 entries, AMD64 game and bundled Node, exact source manifest/core bytes, executable checksum, 121 licence/credit files and absence of the QA executable. Native execution used empty PATH/NODE_PATH, no source-helper override and no GODOT_BIN dependency. Production startup and separate-process state/replay checks passed. No Linux game validation was run.

## Evidence

Complete release: [Windows run 39744145580](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39744145580). [Original native evidence artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39744145580/artifacts/12413043799). Committed [full receipt](evidence/native-proof.json), [phase timings](evidence/native-timings.json), [original renders](screenshots/README.md) and [50-career matrix](../game129/READINESS.md) preserve actual outcomes and source pins.

All entries below are fresh native executable checks at the delivered source, with zero failures. Counts are per phase, not an inflated sum of repeated historical assertions.

| Acceptance | Warm / cold checks |
|---|---:|
| Ardent / Lurk / Erudite mechanics and exact state | 1,015 / 102 |
| Real production creator/combat controls | 147 |
| Genuine campaign advancement | 617 / 8 |
| Connected saved combat, resolution and rest | 34 / 133 |
| Current prepared casters | 1,634 / 97 |
| Current Bard / Beguiler / Spirit Shaman | 1,560 / 115 |
| Current supernatural signatures | 988 / 77 |
| Current martial signatures | 956 / 83 |
| Current mobile signatures | 622 / 33 |
| Current Psion / Wilder / Cerebremancer | 564 / 73 |
| Historical v24 mechanics and controls | 564 / 73; controls 114 |
| Historical v23 / v13 mechanics | 1,634 / 97; 1,792 / 6 |
| Historical v16 repair / compatibility | 818 / 4; 1,941 / 486 |
| All 32 base-class legal tracks, levels 1–20 | 2,598 / 65 |
| Historical v24 continuation display/mechanics | 71 |
| Prepared / performance production controls | 30 / 72 |
| Frozen GAME-32 oracle | 22,181 |
| Genuine Godot capture checks | 35; 23 original PNGs |

The final native campaign contains **three actual 490-XP / level-8 careers**. No campaign XP was injected; 490 XP cannot fund level nine. The separately saved connected encounter executes Ardent's power, Lurk's veil and Erudite's power through AdventureService and the original campaign writer, then verifies cold next-command/RNG equality, normal resolution, reward limits and rest. Level-20 histories and screenshots are explicitly **development fixtures**, not earned level-20 campaigns.

The earlier source-Godot journey [39740803359](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39740803359) and focused [39742269760](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39742269760) are additional labelled checkpoints. They are not substituted for the delivered executable's fresh checks.

## Counts and remaining work

No catalogue entries were added: **32 base classes / 18 prestige paths**, 37 ancestry families / 50 heritage records, 83 feats, 14 skills, 45 selectable psychic powers and 14 creature definitions. The three targeted base classes retain level cap 20. Ability-record totals are not unique executable spell counts.

The native-gated generator promotes only these three defining identities, producing **26 COMPLETE / 24 PARTIAL / 0 BLOCKED**. It preserves labelled historical acceptance, freshly rechecks inherited current consumers and uses unchanged aura projection/data only within its documented historical scope. COMPLETE means the bounded original adaptation, not every tabletop rule or human balance approval.

Small creator/combat viewports require scrolling through long descriptions. The large Lurk render shows both class actions; the extra small focus capture does not prove automatic scroll completion. Original humanoid art fallbacks and shared finite manifesting rules remain; no general invisibility, unsupported body traversal or complete tabletop conversion is claimed.

Next: [the finite completion queue](NEXT-WAVE.md), beginning with **Psychic Warrior, Divine Mind and Cognition Adept**. No world simulation or roster expansion was started. GAME-123 / GitHub #101 remain open. Linear has no callable connector in this session; GitHub and committed records are updated without claiming a direct Linear write.
