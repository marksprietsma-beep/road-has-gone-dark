# Review scope

The large generated diff contains complete immutable pack copies, source/native audit matrices and raw evidence. The actual repair is small enough to inspect separately:

- `PACK-DELTA.json` proves the v15→v16 data changes are limited to version/provenance, five contextual skill approaches and Archmage's requirement/description. All other definitions, including every base class, feat, ancestry and spell, remain unchanged.
- `RulesCompleteness` projects actual permanent spell access only when an entry requirement requests it; it does not cast spells, grant XP, mutate a character or write saves. Existing GAME-32 derivation/requirements remain authority. Prepared/rest-retrieved versus permanent spontaneous knowledge are distinguished; runtime grants are excluded.
- `OpportunityCycles` reuses frozen profiles, the existing private deterministic check seed, authored activity/outcome/timing contracts and the original writer/reward limits. New approach text is presentation metadata; the roll/result is not revealed before selection. Existing pinned campaigns retain their exact legacy choices/order.
- The existing expedition and sheet controllers expose action costs/purpose and skill uses. No new creator, combat engine, save writer, quest generator or ancestry framework is introduced.
- Registry/capability flags append v16, and fresh campaigns select it. The historical byte/pin guard verifies all accepted v1–v15 content. No automatic save migration occurs.
- Supplemental Godot audit sources are preserved as `.gd.txt` documentation, not new production scenes. Python reporting/audit scripts inspect evidence/archives; they never qualify builds or resolve mechanics.

Tests distinguish legal birth/advancement, direct RulesEffects execution, tactical actions, earned XP, separate-process restart, native export and human validation. Neither catalogue counts nor a successful fixture means every career choice/conditional effect is complete. No per-option human acceptance is claimed.

Wave Five documentation updates close stale delivery language using its already-successful seven post-merge Windows workflows and accepted native artifact; they add no Wave Five gameplay. Current GAME-126 delivery is separate and must have its own verified native source/artifact.

Recovery changes after83bc79a are strictly QA ingestion: canonicalize integral JSON pin numbers with the existing RulesJson helper, preserve full485-record/hash equality, reject malformed/wrong/missing pins, and report precise diagnostics. The committed historical fixture itself already contains top-level rules_ref and is unchanged. No gameplay changes are needed for this correction.
