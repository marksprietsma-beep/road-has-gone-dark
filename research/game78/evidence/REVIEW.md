# GAME-78 combined content-system review

This is an isolated research implementation. All examples are actual deterministic output anchored to original source IDs. No game mechanics, live quests or canonical world edits. Generated history is explicitly TRHGD fiction; present-day source culture is not proof of historical authorship.

## Breadth and measured quality

| Domain / provider | Records | Name-independent fact variants | Public prose variants | Duplicate prose |
|---|---:|---:|---:|---:|
| sha-staged/site | 1000 | 1000 | 1000 | 0 |
| sha-staged/origin | 1000 | 1000 | 942 | 58 |
| sha-staged/character | 1000 | 1000 | 1000 | 0 |
| sha-staged/npc | 200 | 200 | 200 | 0 |
| sha-staged/mundane | 1000 | 1000 | 1000 | 0 |
| sha-staged/rare | 1000 | 1000 | 1000 | 0 |
| sha-staged/contract | 200 | 199 | 200 | 0 |
| sha-staged/group | 200 | 127 | 200 | 0 |
| lexicon-staged/site | 1000 | 1000 | 1000 | 0 |
| lexicon-staged/origin | 1000 | 999 | 941 | 59 |
| lexicon-staged/character | 1000 | 1000 | 1000 | 0 |
| lexicon-staged/npc | 200 | 200 | 200 | 0 |
| lexicon-staged/mundane | 1000 | 1000 | 1000 | 0 |
| lexicon-staged/rare | 1000 | 1000 | 1000 | 0 |
| lexicon-staged/contract | 200 | 200 | 200 | 0 |
| lexicon-staged/group | 200 | 137 | 200 | 0 |

Semantic counts remove incidental names and owner IDs; they still count genuine changed event/occupation/material/trait facts. Group counts are intentionally modest. [First 50 sequential outputs, extremes and detected repetition](REVIEW-CORPUS.md) and [raw compressed batches](batches/) are durable and reproducible.

## Examples: source → structured meaning → public prose

### site / markers:51/site:review

Source: original markers ID 51, cell 2651; Ruined Stronghold.

The border storehouse survives with an intact roof, braced masonry, a rusted door bar, worn stone paving, tree roots around the footings. Later accounts say it added a sheltered porch; later, it had its records moved elsewhere; later, it became a meeting place; later, it had the surviving roof weatherproofed; later, it gained a small memorial stone.

<details><summary>Structured generated facts</summary>

```json
{
  "marker_type": "ruins",
  "source_name": "Ruined Stronghold",
  "purpose": "border-storehouse",
  "age_band": "several-generations",
  "history": [
    {
      "index": 0,
      "event": "foundation-laid",
      "state": "standing",
      "actor": "original-workers",
      "years_before": 150
    },
    {
      "index": 1,
      "event": "porch-added",
      "state": "standing",
      "previous_state": "standing",
      "actor": "later-keepers",
      "years_before": 120
    },
    {
      "index": 2,
      "event": "records-moved",
      "state": "abandoned",
      "previous_state": "standing",
      "actor": "later-keepers",
      "years_before": 82
    },
    {
      "index": 3,
      "event": "meeting-reuse",
      "state": "reused",
      "previous_state": "abandoned",
      "actor": "local-workers",
      "years_before": 37
    },
    {
      "index": 4,
      "event": "roof-tarred",
      "state": "reused",
      "previous_state": "reused",
      "actor": "later-occupants",
      "years_before": 19
    },
    {
      "index": 5,
      "event": "memorial-added",
      "state": "reused",
      "previous_state": "reused",
      "actor": "later-keepers",
      "years_before": 9
    }
  ],
  "conditions": [
    "roof-intact",
    "walls-braced",
    "entrance-barred",
    "floor-paved",
    "surrounds-trees"
  ],
  "structural_damage": [],
  "current_state": "reused",
  "tags": [
    "military",
    "ruins"
  ]
}
```

</details>

Rumours (truth metadata is developer-only):

- **Rumour:** The site once held the belongings of several households.
- **Rumour:** One sealed room has remained untouched since the first keepers left.

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "historical_detail": "misdated-lintel",
  "enclosed_space": "disused-cellar",
  "inventory": {
    "household_goods": true,
    "wealth": false
  },
  "continuous_keepers": false,
  "repair_account": "missing-page"
}
```

</details>

### origin / settlements:771/origin:review

Source: original settlements ID 771, cell 1621; Maura.

People in Maura remember how households collected vessels for carrying water during repairs. That work is still recalled by a row of old carrying jars. Local households share part of the first loaf from a repaired oven.

<details><summary>Structured generated facts</summary>

```json
{
  "hometown": "Maura",
  "memory": {
    "event": "water-vessel",
    "actors": "households",
    "legacy": "a row of old carrying jars",
    "period": "within-living-memory"
  },
  "tradition": {
    "practice": "first-loaf",
    "occasion": "oven care",
    "participants": "local-households"
  },
  "public_craft": {
    "occupation": "book-binder",
    "visibility": "widely-known-local-practice"
  },
  "local_figure": {
    "role": "keeper-of-shared-tools",
    "name": "Kosbota",
    "claim": "generated-local-figure"
  }
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "memory_detail": "The surviving account omits a disagreement over the shared contribution."
}
```

</details>

### character / settlements:771/character:review

Source: original settlements ID 771, cell 1621; Maura.

Kagra grew up in Maura, in an extended household. Early work involved sorting salvaged materials. Kagra learned the work of a brewer from a household friend. Early in that work, they forgot an agreed meeting, but later taught a younger worker patiently. Now they hope to learn unfamiliar crafts.

<details><summary>Structured generated facts</summary>

```json
{
  "name": "Kagra",
  "naming": {
    "model": "Lexicon native phonotactics with original profiles",
    "culture_id": 10,
    "confidence": "research-approximation"
  },
  "birthplace": {
    "id": 771,
    "name": "Maura",
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5"
  },
  "age_band": "adult",
  "occupation": "brewer",
  "training": "a-household-friend",
  "family": "extended-household",
  "childhood": "sorting-salvaged-materials",
  "value": "remembering-absent-neighbours",
  "habit": "counts-tools-before-leaving",
  "concern": "forgetting-names-and-obligations",
  "contact": {
    "id": "settlements:771/character:review/contact",
    "name": "Meli",
    "role": "a-repair-customer",
    "relationship": "known-person"
  },
  "traits": [
    "reserved",
    "reckless"
  ],
  "keepsake": "a-short-measuring-cord",
  "local_knowledge": {
    "kind": "public-origin",
    "burg_id": 771,
    "cell_id": 1621,
    "hidden_pois": []
  },
  "first_failure": "forgot-an-agreed-meeting",
  "first_success": "taught-a-younger-worker-patiently",
  "motivation": "learn-unfamiliar-crafts",
  "hometown_relationship": "leaving-with-unfinished-obligations"
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "private_fact": "failed-to-deliver-a-household-message"
}
```

</details>

### npc / settlements:771/npc:review

Source: original settlements ID 771, cell 1621; Maura.

Dedis works as a metalworker in Maura. They are known to be reckless and private. Dedis values patience with learners and turns a ring when thinking. One visible detail is a worn plain ring. They hope to see how other places manage shared work.

<details><summary>Structured generated facts</summary>

```json
{
  "name": "Dedis",
  "naming": {
    "model": "Lexicon native phonotactics with original profiles",
    "culture_id": 10,
    "confidence": "research-approximation"
  },
  "birthplace": {
    "id": 771,
    "name": "Maura",
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5"
  },
  "age_band": "young-adult",
  "occupation": "metalworker",
  "training": "a-demanding-workshop-keeper",
  "family": "two-parent-household",
  "childhood": "caring-for-younger-children",
  "value": "patience-with-learners",
  "habit": "turns-a-ring-when-thinking",
  "concern": "becoming-dependent-on-strangers",
  "contact": {
    "id": "settlements:771/npc:review/contact",
    "name": "Kibna",
    "role": "a-former-apprentice",
    "relationship": "known-person"
  },
  "traits": [
    "reckless",
    "private"
  ],
  "keepsake": "a-short-measuring-cord",
  "local_knowledge": {
    "kind": "public-origin",
    "burg_id": 771,
    "cell_id": 1621,
    "hidden_pois": []
  },
  "role": "metalworker",
  "desire": "see-how-other-places-manage-shared-work",
  "speech_style": "careful",
  "physical_identifier": "a worn plain ring"
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "private_fact": "copied-a-private-letter-without-permission"
}
```

</details>

### mundane / settlements:771/mundane:review

Source: original settlements ID 771, cell 1621; Maura.

Made from bronze, this mirror came from a retired maker working at home. It is compactly made and stained by ordinary work. It was bought from a retired worker; afterward, a storage cover was replaced. It remains an ordinary possession for ordinary grooming.

<details><summary>Structured generated facts</summary>

```json
{
  "base": {
    "type": "mirror",
    "category": "household",
    "material": "bronze",
    "secondary_material": "wood"
  },
  "quality": "compactly-made",
  "condition": "stained-by-ordinary-work",
  "maker": {
    "role": "a-retired-maker-working-at-home",
    "culture_id": 10,
    "place": {
      "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5",
      "burg_id": 771
    },
    "identity": "settlements:771/mundane:review/maker"
  },
  "age_band": "several-generations",
  "use": "ordinary grooming",
  "visible_mark": "a-small-stamped-circle",
  "ownership": [
    {
      "owner": "settlements:771/mundane:review/owner:0",
      "role": "first-household",
      "event": "created",
      "index": 0
    },
    {
      "owner": "settlements:771/mundane:review/owner:1",
      "from": "settlements:771/mundane:review/owner:0",
      "role": "later-household",
      "event": "bought-from-a-retired-worker",
      "index": 1
    }
  ],
  "repair": {
    "event": "a-storage-cover-was-replaced",
    "after_owner": "settlements:771/mundane:review/owner:1"
  },
  "small_detail": "recorded-in-an-ordinary-account"
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{}
```

</details>

### rare / settlements:771/rare:review

Source: original settlements ID 771, cell 1621; Maura.

This brooch, made from bronze, first belonged to a person appointed to maintain shared equipment. It was held in place of a small debt, then returned after being lent for a season, then given to someone who had repaired it. At a later repair, a loose joint was tightened. It is used as a comparison piece by later makers; its surface bears a patched maker’s label.

<details><summary>Structured generated facts</summary>

```json
{
  "base": {
    "type": "brooch",
    "category": "jewellery",
    "material": "bronze",
    "secondary_material": null
  },
  "quality": "compactly-made",
  "condition": "wrapped-for-careful-storage",
  "maker": {
    "role": "a-shared-workroom",
    "culture_id": 10,
    "place": {
      "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5",
      "burg_id": 771
    },
    "identity": "settlements:771/rare:review/maker"
  },
  "age_band": "one-generation",
  "use": "fastening clothing",
  "visible_mark": "a-patched-maker-s-label",
  "ownership": [
    {
      "owner": "settlements:771/rare:review/owner:0",
      "role": "a-person-appointed-to-maintain-shared-equipment",
      "event": "created",
      "index": 0
    },
    {
      "owner": "settlements:771/rare:review/owner:1",
      "from": "settlements:771/rare:review/owner:0",
      "role": "a-keeper-of-shared-records",
      "event": "held-in-place-of-a-small-debt",
      "index": 1
    },
    {
      "owner": "settlements:771/rare:review/owner:2",
      "from": "settlements:771/rare:review/owner:1",
      "role": "a-witness-to-communal-agreements",
      "event": "returned-after-being-lent-for-a-season",
      "index": 2
    },
    {
      "owner": "settlements:771/rare:review/owner:3",
      "from": "settlements:771/rare:review/owner:2",
      "role": "a-former-apprentice-who-became-a-maker",
      "event": "given-to-someone-who-had-repaired-it",
      "index": 3
    }
  ],
  "repair": {
    "event": "a-loose-joint-was-tightened",
    "after_owner": "settlements:771/rare:review/owner:3"
  },
  "reputation": "used-as-a-comparison-piece-by-later-makers"
}
```

</details>

Rumours (truth metadata is developer-only):

- **Rumour:** The object has never left its first household.

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "private_history": "an-early-repair-account-omits-a-failed-first-attempt",
  "exceptional_property": null
}
```

</details>

### contract / settlements:771/contract:review

Source: original settlements ID 771, cell 1621; Maura.

A book binder asks someone to check a damaged inventory. The difficulty is that the issuer lacks a complete inventory. A repair tally may help establish what happened. The proposed reward is a small payment.

<details><summary>Structured generated facts</summary>

```json
{
  "status": "research-proposal",
  "issuer": {
    "id": "settlements:771/contract:review/issuer",
    "role": "book-binder"
  },
  "goal": "check-a-damaged-inventory",
  "reason": "preserve-or-return-ordinary-property",
  "known_complication": "the-issuer-lacks-a-complete-inventory",
  "target": {
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5",
    "burg_id": 771,
    "kind": "public-document",
    "identity": "settlements:771/contract:review/target"
  },
  "evidence": "a-repair-tally",
  "alternate_resolution": "compare-accounts-with-a-second-witness",
  "reward_theme": "a-small-payment",
  "time_sensitivity": "unspecified",
  "related_site": {
    "source_kind": "markers",
    "source_id": 51,
    "cell_id": 2651,
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5",
    "enrichment_id": "markers:51/site:review"
  }
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "complication": "The issuer has not disclosed an incomplete ownership account."
}
```

</details>

### group / settlements:771/group:review

Source: original settlements ID 771, cell 1621; Maura.

The Bitse Circle is a burial society. Its public purpose is to keep contributions fairly recorded. Its members use a plain measuring rod as a sign. The Bitse Circle keeps its shared records in ordinary accounts.

<details><summary>Structured generated facts</summary>

```json
{
  "status": "research-group",
  "type": "burial-society",
  "purpose": "keep-contributions-fairly-recorded",
  "culture_id": 10,
  "name": "The Bitse Circle",
  "leader_role": "elected-record-keeper",
  "resource": "shared-tools-and-contributions",
  "symbol": "a-plain-measuring-rod",
  "related_entities": [
    {
      "id": "settlements:771/group:review/partner",
      "kind": "group",
      "type": "household-workroom",
      "name": null
    }
  ],
  "relationship": {
    "other": "settlements:771/group:review/partner",
    "type": "shared-record-keeping",
    "canonical": false
  }
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "internal_goal": "resolve-an-undisclosed-contribution-dispute"
}
```

</details>

### npc / settlements:771/npc:role:tavern-keeper

Source: original settlements ID 771, cell 1621; Maura.

Deru works as a tavern keeper in Maura. They are known to be cowardly and impatient. Deru values patience with learners and notes who lent an object. One visible detail is a carefully folded cloth. They hope to keep a promise to a departed friend.

<details><summary>Structured generated facts</summary>

```json
{
  "name": "Deru",
  "naming": {
    "model": "Lexicon native phonotactics with original profiles",
    "culture_id": 10,
    "confidence": "research-approximation"
  },
  "birthplace": {
    "id": 771,
    "name": "Maura",
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5"
  },
  "age_band": "older-adult",
  "occupation": "tavern-keeper",
  "training": "a-relative-with-failing-eyesight",
  "family": "household-of-family-friends",
  "childhood": "listening-to-older-neighbours",
  "value": "patience-with-learners",
  "habit": "notes-who-lent-an-object",
  "concern": "becoming-dependent-on-strangers",
  "contact": {
    "id": "settlements:771/npc:role:tavern-keeper/contact",
    "name": "Lelir",
    "role": "a-friend-from-shared-lessons",
    "relationship": "known-person"
  },
  "traits": [
    "cowardly",
    "impatient"
  ],
  "keepsake": "a-blank-account-leaf",
  "local_knowledge": {
    "kind": "public-origin",
    "burg_id": 771,
    "cell_id": 1621,
    "hidden_pois": []
  },
  "role": "tavern-keeper",
  "desire": "keep-a-promise-to-a-departed-friend",
  "speech_style": "measured",
  "physical_identifier": "a carefully folded cloth"
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "private_fact": "kept-an-unfinished-practice-piece"
}
```

</details>

### npc / settlements:771/npc:role:toolmaker

Source: original settlements ID 771, cell 1621; Maura.

Kigkirgo works as a toolmaker in Maura. Neighbours describe them as practical and sceptical. Kigkirgo values sharing useful knowledge and sets tools in a fixed order. One visible detail is a worn plain ring. They hope to earn enough to repair a family home.

<details><summary>Structured generated facts</summary>

```json
{
  "name": "Kigkirgo",
  "naming": {
    "model": "Lexicon native phonotactics with original profiles",
    "culture_id": 10,
    "confidence": "research-approximation"
  },
  "birthplace": {
    "id": 771,
    "name": "Maura",
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5"
  },
  "age_band": "young-adult",
  "occupation": "toolmaker",
  "training": "a-demanding-workshop-keeper",
  "family": "family-of-itinerant-workers",
  "childhood": "tending-stored-supplies",
  "value": "sharing-useful-knowledge",
  "habit": "sets-tools-in-a-fixed-order",
  "concern": "repeating-a-costly-mistake",
  "contact": {
    "id": "settlements:771/npc:role:toolmaker/contact",
    "name": "Rubbeg",
    "role": "a-keeper-of-local-records",
    "relationship": "known-person"
  },
  "traits": [
    "practical",
    "sceptical"
  ],
  "keepsake": "an-old-tally-stick",
  "local_knowledge": {
    "kind": "public-origin",
    "burg_id": 771,
    "cell_id": 1621,
    "hidden_pois": []
  },
  "role": "toolmaker",
  "desire": "earn-enough-to-repair-a-family-home",
  "speech_style": "brief",
  "physical_identifier": "a worn plain ring"
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "private_fact": "concealed-who-paid-for-their-training"
}
```

</details>

### npc / settlements:771/npc:role:local-clerk

Source: original settlements ID 771, cell 1621; Maura.

Tetbud works as a local clerk in Maura. They are known to be plain spoken and cowardly. Tetbud values practical fairness and turns a ring when thinking. They can be recognised by a carefully folded cloth. They hope to prove that a past failure need not define them.

<details><summary>Structured generated facts</summary>

```json
{
  "name": "Tetbud",
  "naming": {
    "model": "Lexicon native phonotactics with original profiles",
    "culture_id": 10,
    "confidence": "research-approximation"
  },
  "birthplace": {
    "id": 771,
    "name": "Maura",
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5"
  },
  "age_band": "older-adult",
  "occupation": "local-clerk",
  "training": "a-household-friend",
  "family": "family-of-itinerant-workers",
  "childhood": "caring-for-younger-children",
  "value": "practical-fairness",
  "habit": "turns-a-ring-when-thinking",
  "concern": "letting-a-friendship-lapse",
  "contact": {
    "id": "settlements:771/npc:role:local-clerk/contact",
    "name": "Mamno",
    "role": "a-former-apprentice",
    "relationship": "known-person"
  },
  "traits": [
    "plain-spoken",
    "cowardly"
  ],
  "keepsake": "a-tiny-box-of-spare-pegs",
  "local_knowledge": {
    "kind": "public-origin",
    "burg_id": 771,
    "cell_id": 1621,
    "hidden_pois": []
  },
  "role": "local-clerk",
  "desire": "prove-that-a-past-failure-need-not-define-them",
  "speech_style": "measured",
  "physical_identifier": "a carefully folded cloth"
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "private_fact": "hid-a-small-unpaid-debt"
}
```

</details>

### npc / settlements:771/npc:role:traveller

Source: original settlements ID 771, cell 1621; Maura.

Buros works as a traveller in Maura. Neighbours describe them as methodical and cowardly. Buros values remembering absent neighbours and turns a ring when thinking. They can be recognised by a scuffed carrying bag. They hope to bring a younger sibling new opportunities.

<details><summary>Structured generated facts</summary>

```json
{
  "name": "Buros",
  "naming": {
    "model": "Lexicon native phonotactics with original profiles",
    "culture_id": 10,
    "confidence": "research-approximation"
  },
  "birthplace": {
    "id": 771,
    "name": "Maura",
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5"
  },
  "age_band": "adult",
  "occupation": "traveller",
  "training": "an-older-sibling",
  "family": "two-connected-households",
  "childhood": "copying-household-accounts",
  "value": "remembering-absent-neighbours",
  "habit": "turns-a-ring-when-thinking",
  "concern": "forgetting-names-and-obligations",
  "contact": {
    "id": "settlements:771/npc:role:traveller/contact",
    "name": "Lata",
    "role": "a-friend-from-shared-lessons",
    "relationship": "known-person"
  },
  "traits": [
    "methodical",
    "cowardly"
  ],
  "keepsake": "an-old-tally-stick",
  "local_knowledge": {
    "kind": "public-origin",
    "burg_id": 771,
    "cell_id": 1621,
    "hidden_pois": []
  },
  "role": "traveller",
  "desire": "bring-a-younger-sibling-new-opportunities",
  "speech_style": "measured",
  "physical_identifier": "a scuffed carrying bag"
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "private_fact": "still-keeps-a-rival-s-discarded-work"
}
```

</details>

### npc / settlements:771/npc:role:religious-attendant

Source: original settlements ID 771, cell 1621; Maura.

Bokeb works as a religious attendant in Maura. Neighbours describe them as plain spoken and boastful. Bokeb values careful workmanship and turns a ring when thinking. They can be recognised by a scuffed carrying bag. They hope to keep a promise to a departed friend.

<details><summary>Structured generated facts</summary>

```json
{
  "name": "Bokeb",
  "naming": {
    "model": "Lexicon native phonotactics with original profiles",
    "culture_id": 10,
    "confidence": "research-approximation"
  },
  "birthplace": {
    "id": 771,
    "name": "Maura",
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5"
  },
  "age_band": "older-adult",
  "occupation": "religious-attendant",
  "training": "a-neighbour-who-taught-evening-lessons",
  "family": "two-connected-households",
  "childhood": "mending-ordinary-possessions",
  "value": "careful-workmanship",
  "habit": "turns-a-ring-when-thinking",
  "concern": "returning-without-useful-work",
  "contact": {
    "id": "settlements:771/npc:role:religious-attendant/contact",
    "name": "Gonib",
    "role": "a-person-who-once-lent-tools",
    "relationship": "known-person"
  },
  "traits": [
    "plain-spoken",
    "boastful"
  ],
  "keepsake": "a-spare-buckle",
  "local_knowledge": {
    "kind": "public-origin",
    "burg_id": 771,
    "cell_id": 1621,
    "hidden_pois": []
  },
  "role": "religious-attendant",
  "desire": "keep-a-promise-to-a-departed-friend",
  "speech_style": "careful",
  "physical_identifier": "a scuffed carrying bag"
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "private_fact": "failed-to-deliver-a-household-message"
}
```

</details>

### npc / settlements:771/npc:role:possible-recruit

Source: original settlements ID 771, cell 1621; Maura.

Reru works as a repair apprentice in Maura. Neighbours describe them as curious and reserved. Reru values repair before replacement and notes who lent an object. One visible detail is a repaired sleeve. They hope to bring a younger sibling new opportunities.

<details><summary>Structured generated facts</summary>

```json
{
  "name": "Reru",
  "naming": {
    "model": "Lexicon native phonotactics with original profiles",
    "culture_id": 10,
    "confidence": "research-approximation"
  },
  "birthplace": {
    "id": 771,
    "name": "Maura",
    "world_id": "azgaar:1.153.1:game-11-determinism:2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5"
  },
  "age_band": "young-adult",
  "occupation": "possible-recruit",
  "training": "a-guardian-who-valued-careful-work",
  "family": "single-parent-household",
  "childhood": "listening-to-older-neighbours",
  "value": "repair-before-replacement",
  "habit": "notes-who-lent-an-object",
  "concern": "letting-a-friendship-lapse",
  "contact": {
    "id": "settlements:771/npc:role:possible-recruit/contact",
    "name": "Kodo",
    "role": "a-household-guardian",
    "relationship": "known-person"
  },
  "traits": [
    "curious",
    "reserved"
  ],
  "keepsake": "a-folded-household-letter",
  "local_knowledge": {
    "kind": "public-origin",
    "burg_id": 771,
    "cell_id": 1621,
    "hidden_pois": []
  },
  "role": "possible-recruit",
  "desire": "bring-a-younger-sibling-new-opportunities",
  "speech_style": "measured",
  "physical_identifier": "a repaired sleeve"
}
```

</details>

<details><summary>Developer-only hidden truth — excluded from public prose</summary>

```json
{
  "private_fact": "left-a-task-unfinished-and-blamed-poor-materials"
}
```

</details>

## Fresh canonical worlds

| Seed | Actual contrasting towns | Actual ruin IDs | Enrichment examples |
|---|---|---|---:|
| game78-deep-00 | Louleibagos (32), Valforbogno (59), Seting (163), Torci (33), Ryadh (34) | 46, 47, 48 | 38 |
| game78-deep-01 | Newboline (22), Dodbrigh (66), Rothton (152), Wihulton (26), Harton (31) | 53, 54, 55 | 38 |
| game78-deep-02 | Dodri (23), Casthgrore (20), Zirnib (119), Gajar'jaz (110), Itnathuhel (26) | 46, 47, 48 | 38 |
| game78-deep-03 | Hofnnestad (11), Hesberg (23), Halton (130), Flaneskene (273), Lovernes (16), Batontongay (18) | 46, 47, 48 | 45 |
| game78-deep-04 | Brinay (30), Zhivansk (35), Vevesk (139), Palheidual (34), Teostos (32) | 53, 54, 55 | 38 |

Five fresh worlds each replay byte-identically through the accepted packaged helper. [Source IDs, hashes and complete examples](fresh-worlds.json).

## Recommendation and limits

Retain TRHGD typed facts/seeds and constraints. Use the pinned Lexicon engine where weighting and language generation help, and pinned Rant for public-fact rendering. Adopt only the specifically cleared vocabulary. No vendor fantasy/SRD prose pack enters the content library. See [executed comparison](../docs/PROVIDER-FINDINGS.md), [performance](performance.json) and [architecture](../docs/ARCHITECTURE.md).

This is substantially broader than GAME-77, but still a research library rather than a finished years-long campaign corpus. The present tone emphasises everyday work and local memory; future authored packs need broader non-craft social history, cultural voices, source-type coverage and editorial acceptance. Names are source-culture-bound approximations. Ruins/dungeons are the supported site anchors; unsupported natural markers fail rather than acquire invented buildings.
