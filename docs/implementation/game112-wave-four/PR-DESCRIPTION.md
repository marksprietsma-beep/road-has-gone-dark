# Wave Four — first coherent v14 batch

The merged Wave Three baseline is retained. This first batch adds Erudite's saved distinct-powers-per-rest discipline, Divine Mind's mantle-restricted psychic support and Marshal's noncasting leadership. Maintained auras use ordinary actions/statuses/resources and project typed bonuses from live geometry through a thin inherited adapter. The frozen GAME-32 tactical source remains byte-for-byte unchanged; no action economy, targeting, turn order, XP policy or second save writer is introduced. v1–v13 bytes and saved pins remain unchanged.

New supporting adaptations: five-level Cognition Adept (bounded psychic hunter), Bugbear/Ogre/Half-giant/Troglodyte; eight feats, eight psychic powers with authored augmentation, two shared spell identities, two costed summons and Scaled Guardian form. Base tracks support1–20; prestige caps retain the existing5/10-level definitions. Eligibility is permanent and optional; prestige never starts at level1 or assigns itself, and ordinary advancement still requires earned XP.

| Category | v13 | v14 candidate |
|---|---:|---:|
| Base classes | 25 | 28 |
| Prestige paths | 12 | 13 |
| Ancestry families | 25 | 29 |
| Heritage records | 34 | 38 |
| Feats | 50 | 58 |
| Skills | 14 | 14 |
| Named spell identities | 87 | 89 |
| Class spell references | 125 | 133 |
| Selectable psychic powers | 21 | 29 |
| Other named ability identities | 312 | 332 |
| Other ability records | 328 | 356 |
| Creature definitions | 8 | 10 |
| Body forms | 11 | 12 |
| Scheduled choice groups | 133 | 189 |

Spell identities are conservatively grouped by display name, separately listing every class reference in REPERTOIRE.json. Other named/ability records include level-labelled techniques and are not a claim of that many different mechanics. Scheduled power choices are not counted as distinct specialisation concepts. All760 indexed research occurrences remain; eight candidate mappings stay implemented until native verification. Skills remain14 because no new skill is needed here.

Verification is in progress: frozen GAME-32 oracle passed22,181 kernel assertions plus235 migration/six reload; historical append-only guard9/0; actual Godot creator renders26/0 with18 captures at640/1280/2560. Current candidate mechanics, production journey, native Windows/Linux and full compatibility results must be verified before ready/merge. Historical successful runs are not final v14 acceptance.

This is below Wave Four's aspirational totals. Beguiler/Duskblade/Dragonfire Adept/Spirit Shaman, additional prestige, heritage, metamagic and companion options remain explicit continuation work. Neutral humanoid LPC fallbacks persist; large creatures still occupy one tile; no flight/swimming/environmental vision claims. No unrelated world/map/quest expansion. Programme #82 remains open. The owner authorises normal merge after current-head checks, never a bypass.
