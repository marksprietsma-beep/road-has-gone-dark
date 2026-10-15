# Wave Four engineering assessment

Started from merged Wave Three main0f46194beabedf8b287795076f75800a3aef467b and preserved all existing work on the same branch/PR99. Baseline Wave Three main workflows subsequently passed; no upstream implementation was replaced.

The first cohort introduced Erudite, Divine Mind, Marshal, Cognition Adept and supporting inherited/effect content. Its native Windows/Linux jobs passed at06c8bfb. That was not the full approved expansion. The second cohort adds Beguiler, Dragonfire Adept, War Chanter, Archmage, Metamind, fourGenasi families/twoheritages, eightfeats/sixpowers/twocreatures and executable magic. Totals now reach30base/16prestige/33families/44heritages/66feats/35powers/12creatures. Definitions remain bounded original adaptations; all760 research occurrences remain tracked.

The existing history/requirements/resources/status/entity framework handles the cohort. A saved manifested-power ledger applies only tov14. TacticalAuras inherits frozen TacticalCombat command/turn/geometry/RNG authority and only projects live aura modifiers at seal/weapon boundaries. Earlier pack gates retain original behaviour. No alternate rules engine, creator or campaign writer was introduced.

Review exposed two correctedv14 defects: mixed StringName allocation keys changed advancement hashes after JSON reload, fixed by boundary normalisation; Cognition Adept accidentally copied an Erudite-only distinct-power formula, removed and regression-tested. Exact history/snapshot checks remain strict. Allv1–v13 bytes and the frozen tactical source are unchanged.

Sequence used: preserve/inspectCI → schema/level 20/focused effects → exact cold restart/earned optional prestige → actual creator/campaign renders → self-contained Windows/Linux → full compatibility → publication/merge gates. Superseded branch runs were cancelled only after preserving evidence and pushing verified corrections. Successful historical tests are labelled as such.

Duskblade is deferred honestly because hit-conditioned channeling needs structured hit events, not log parsing or spell damage on misses. Spirit Shaman needs a real rest-selection lifecycle. Those are concrete follow-up character mechanics, not cosmetic class renames. No world/map/quest or GAME105/GAME122 expansion. Skills stay14; scheduled choices and class spell references are not counted as unique mechanics.
