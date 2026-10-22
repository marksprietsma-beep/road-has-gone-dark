# GAME-127 Windows acceptance

All game execution is on native Windows. Host scripts only inspect source, JSON, hashes, Git and archives.

Focused gate: `.github/workflows/verify-psychic-identities.yml` / `tests/psychic_identities/run-focused.py`. Historical v24 reproduction runs first; v25 mechanics, independent-process cold restart and production controls follow. Dispatch `journey=true` for three actual490XP/level8 campaigns, connected saved combat/cold and original Godot captures. Dispatch `release=true` only once the candidate is stable for the complete self-contained native executable, inherited current/historical suites, frozen GAME-32 oracle, screenshots and archive/source checks. No reused native source receipts substitute for the changed v25 authority.

## Manual review

1. Extract the outer GitHub artifact and the inner playable ZIP; retain all support/helper/art/licence files beside `road-has-gone-dark.exe`. Launch it without Godot/Node installed. Escape skips intro.
2. New Game, choose/generate a world, origin and hometown. Choose Ardent, Lurk and Erudite for the three characters. Build > Specialisation / Powers exposes persistent class choices. Ardent's different mantles enable different powers; powers outside both selected mantles are locked and explained. Duplicate mantles and powers are rejected.
3. Review numerical sheets and known powers. Finish the party; follow an opportunity into combat. Confirm augmentation expenditure cannot exceed manifesting level and ability-specific class attributes stay separate in multiclass builds.
4. Lurk: Psychic veil consumes main action/focus, grants25% weapon concealment for two global rounds. It is not invisibility. A later adjacent melee ambush costs focus/PP/main and consumes veil; direct psychic damage/off-balance precede a separate weapon roll. Extra ancestry reach still extends ordinary attacks but never ambush. A level-one Lurk has two focus: enough for one veil/ambush sequence before eligible rest.
5. Erudite: use a known power, then repeat or augment the same identity. Repetition still costs PP/main. After `1 + floor(Erudite level/4)` identities, a new one has a disabled action and visible explanation; it cannot highlight legal targets. Starting another encounter or saving/reloading cannot reset the allowance. Return home and use eligible rest; reserves and allowance recover.
6. Earn opportunity XP, return home and commit advancement. The test journeys reach level8 with490 actual XP; level20 images are development fixtures. Level9 must remain unfunded at490XP.
7. Save, fully exit, relaunch and Resume. Confirm class choices, mantle origins, resources, veil duration, distinct identities, positions, battle logs and the next deterministic command persist. Continue an older campaign and confirm its exact original rules pin, never an automatic upgrade.

Human visual/balance review remains separate from signal-driven production controls and fixture acceptance. No claim of a general invisibility/stealth engine, complete tabletop catalogue or flight/environment simulation is made.
