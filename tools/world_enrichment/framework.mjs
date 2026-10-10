import {
  readFileSync,
  writeFileSync,
  mkdirSync,
  linkSync,
  unlinkSync,
} from "node:fs";
import { dirname } from "node:path";
import { ContentSeed, sha, canonical } from "./core.mjs";
import { createContext, weightedList } from "../../vendor/content/lexicon/core/index.js";
import { generateWord } from "../../vendor/content/lexicon/language/index.js";
import { contextTags, choose, validateSelection } from "./compatibility.mjs";
export const VERSION = "trhgd-game78-1",
  SCHEMA = 2;
const packPath = new URL("../../data/world_enrichment/trhgd-expanded-v1.json", import.meta.url),
  vocabPath = new URL(
    "../../data/world_enrichment/curated-corpora-vocabulary.json",
    import.meta.url,
  );
export const pack = JSON.parse(readFileSync(packPath)),
  vocabulary = JSON.parse(readFileSync(vocabPath));
export const packSha = sha(
  canonical({
    pack,
    vocabulary,
    engines: { lexicon: "da0a823e275d9642731bdaed1f3006d2c9bfae74" },
  }),
);
export const domains = [
  "site",
  "origin",
  "character",
  "npc",
  "mundane",
  "rare",
  "contract",
  "group",
];
const itemCategories = new Set(pack.items.map((r) => r.category));
export function seedFor(ctx, domain, instance, scope, provider) {
  return new ContentSeed(
    ctx.world.id,
    scope,
    VERSION + ":" + provider,
    packSha,
    [ctx.source_kind + ":" + ctx.source_id, domain + ":" + instance],
  );
}
function cultureName(ctx, seed) {
  // Original phonotactic profiles, bound to immutable source culture ID. They are
  // research approximations, not authoritative Azgaar personal naming rules.
  const profiles = [
    {
      C: ["b", "d", "g", "k", "l", "m", "n", "r", "s", "t"],
      V: ["a", "e", "i", "o", "u"],
    },
    {
      C: ["br", "d", "f", "h", "k", "l", "n", "r", "th", "v"],
      V: ["a", "e", "ei", "o"],
    },
    {
      C: ["d", "g", "l", "m", "n", "r", "s", "sh", "t", "z"],
      V: ["a", "ai", "i", "o", "u"],
    },
  ];
  const profile =
    profiles[
      parseInt(sha(canonical([ctx.world.id, ctx.culture_id])).slice(0, 8), 16) %
        profiles.length
    ];
  const glyphs = {
    classes: profile,
    syllables: [
      ["C V", 3],
      ["C V C", 2],
    ],
    wordShapes: [
      ["2", 3],
      ["3", 1],
    ],
    joiner: "",
  };
  return generateWord(
    glyphs,
    createContext({ seed: seed.digest("personal-name") }),
  );
}
export function generate(
  ctx,
  domain,
  instance = "0",
  {
    provider = "sha-staged",
    playthrough_id = null,
    role = null,
    site_record = null,
  } = {},
) {
  if (
    !domains.includes(domain) ||
    !["sha-staged", "lexicon-staged"].includes(provider)
  )
    throw Error("Unsupported provider/domain");
  if (
    !ctx?.world?.id ||
    !ctx.world.sha256 ||
    !Number.isInteger(ctx.source_id) ||
    !Number.isInteger(ctx.cell_id)
  )
    throw Error("Invalid source context");
  if (domain === "site" && ctx.source_kind !== "markers")
    throw Error("Sites require actual markers");
  if (domain === "site" && !["ruins", "dungeons"].includes(ctx.marker_type))
    throw Error("Unsupported source marker type: " + ctx.marker_type);
  if (domain !== "site" && ctx.source_kind !== "settlements")
    throw Error("Domain requires actual hometown");
  if (domain === "character" && !playthrough_id)
    throw Error("Character requires explicit playthrough");
  const scope =
      domain === "character" ? "playthrough:" + playthrough_id : "world",
    seed = seedFor(ctx, domain, String(instance), scope, provider),
    tags = contextTags(ctx);
  const picker =
    provider === "lexicon-staged"
      ? (field, rows) => {
          const g = weightedList(
            Object.fromEntries(rows.map((r) => [r.id, r.weight ?? 1])),
          );
          const id = g.generate(createContext({ seed: seed.digest(field) }));
          return rows.find((r) => r.id === id);
        }
      : null;
  const pick = (field, key, selected = []) =>
    choose(
      seed,
      field,
      typeof key === "string" ? pack[key] : key,
      tags,
      selected,
      picker,
    );
  const small = (field, key) => pick(field, key).id;
  const source = {
    world_id: ctx.world.id,
    world_sha: ctx.world.sha256,
    kind: ctx.source_kind,
    id: ctx.source_id,
    cell_id: ctx.cell_id,
    state_id: ctx.state_id,
    province_id: ctx.province_id,
    culture_id: ctx.culture_id,
    religion_id: ctx.religion_id,
  };
  const r = {
    schema_version: SCHEMA,
    id: ctx.source_kind + ":" + ctx.source_id + "/" + domain + ":" + instance,
    domain,
    scope,
    source,
    versions: {
      generator: VERSION,
      provider,
      pack: pack.version,
      pack_sha: packSha,
    },
    seed: seed.digest("entity"),
    context: {
      culture: ctx.culture,
      religion: ctx.religion,
      biome: ctx.biome,
      port: ctx.port,
      walls: ctx.walls,
      river: ctx.river_id,
      roads: ctx.road_ids,
      route_connection: ctx.route_connection,
      settlement_class: ctx.settlement_class ?? null,
      relative_population: ctx.population ?? null,
      adjacent_settlements: ctx.adjacent_settlements ?? null,
    },
    source_visibility: ctx.source_visibility,
    public: {},
    rumours: [],
    secret: {},
    provenance: {
      authorship: "TRHGD immutable generated fiction",
      source_context: "GAME-77 canonical context",
      context_tags: [...tags].sort(),
      canonical_gameplay: false,
      source_flavour: ctx.source_flavour,
    },
  };
  const pub = r.public;
  if (domain === "site") {
    // Actual source marker type is retained. Purposes are invented historical
    // interpretation, not replacement source classification.
    pub.marker_type = ctx.marker_type;
    pub.source_name =
      ctx.source_visibility === "public" ? ctx.display_name : null;
    const constrained =
      ctx.marker_type === "sacred"
        ? pack.purposes.filter((x) =>
            ["religious", "ritual", "burial"].includes(x.category),
          )
        : pack.purposes;
    const purpose = pick("purpose", constrained);
    pub.purpose = purpose.id;
    pub.age_band = seed.pick("age", [
      "several-generations",
      "within-living-memory",
      "many-generations",
    ]);
    const stages = [
      pack.events.filter((x) => x.category === "expanded"),
      pack.events.filter((x) => ["damage", "social"].includes(x.category)),
      pack.events.filter((x) =>
        ["repair", "reuse", "abandonment", "salvage"].includes(x.category),
      ),
      pack.events.filter((x) => x.category === "care"),
      pack.events.filter((x) => x.category === "memory"),
    ];
    pub.history = [
      {
        index: 0,
        event: "foundation-laid",
        state: "standing",
        actor: "original-workers",
        years_before: {
          "within-living-memory": 60,
          "several-generations": 150,
          "many-generations": 300,
        }[pub.age_band],
      },
    ];
    let previous = "standing";
    for (let k = 0; k < stages.length; k++) {
      const event = pick("history:" + k, stages[k]);
      pub.history.push({
        index: k + 1,
        event: event.id,
        state: event.transition === "preserve" ? previous : event.transition,
        previous_state: previous,
        actor: seed.pick("history-actor:" + k, [
          "later-keepers",
          "local-workers",
          "later-occupants",
        ]),
        years_before: Math.floor(
          pub.history[0].years_before * [0.8, 0.55, 0.25, 0.13, 0.06][k],
        ),
      });
      previous = event.transition === "preserve" ? previous : event.transition;
    }
    const conditions = [];
    for (const facet of ["roof", "walls", "access", "floor", "surrounds"])
      conditions.push(
        pick(
          "condition:" + facet,
          pack.conditions.filter((x) => x.facet === facet),
        ),
      );
    pub.conditions = conditions.map((x) => x.id);
    // Damage/abandonment need not remove all masonry. Choose coherent final roof.
    if (previous === "damaged") pub.conditions[0] = "roof-missing";
    pub.structural_damage = [];
    for (const e of pub.history) {
      const row = pack.events.find((x) => x.id === e.event);
      if (
        row.damage_component &&
        !pub.structural_damage.includes(row.damage_component)
      )
        pub.structural_damage.push(row.damage_component);
      if (row.repair_component)
        pub.structural_damage = pub.structural_damage.filter(
          (c) => c !== row.repair_component,
        );
    }
    const damagedConditions = {
      roof: "roof-missing",
      walls: "walls-cracked",
      floor: "floor-subsided",
      access: "entrance-blocked",
    };
    for (const component of pub.structural_damage) {
      const at = ["roof", "walls", "access", "floor", "surrounds"].indexOf(
        component,
      );
      pub.conditions[at] = damagedConditions[component];
    }
    pub.current_state = previous;
    pub.tags = [purpose.category, ctx.marker_type ?? "site"];
    r.rumours = [
      {
        id: "former-store",
        claim: "The site once held the belongings of several households.",
        truth: "partially-true",
      },
      {
        id: "untouched-room",
        claim:
          "One sealed room has remained untouched since the first keepers left.",
        truth: "false",
      },
    ];
    r.secret = {
      historical_detail: small("historical-secret", "site_secrets"),
      enclosed_space: seed.pick("private-space", [
        null,
        "wall-cupboard",
        "small-alcove",
        "blocked-store",
        "disused-cellar",
        "covered-cistern",
      ]),
      inventory: { household_goods: true, wealth: false },
      continuous_keepers: false,
      repair_account: seed.pick("private-account", [
        "missing-page",
        "altered-date",
        "unrecorded-borrower",
      ]),
    };
  } else if (domain === "origin") {
    const memory = pick("memory", "memories"),
      tradition = pick("tradition", "traditions"),
      craft = pick("craft", "occupations");
    pub.hometown = ctx.display_name;
    pub.memory = {
      event: memory.id,
      actors: memory.actors,
      legacy: memory.legacy,
      period: seed.pick("memory-period", [
        "a-generation-ago",
        "within-living-memory",
        "several-generations-ago",
      ]),
    };
    pub.tradition = {
      practice: tradition.id,
      occasion: tradition.occasion,
      participants: "local-households",
    };
    pub.public_craft = {
      occupation: craft.id,
      visibility: "widely-known-local-practice",
    };
    pub.local_figure = {
      role: seed.pick("public-figure", [
        "retired-record-keeper",
        "patient-repair-teacher",
        "keeper-of-shared-tools",
      ]),
      name: cultureName(ctx, seed.child("local-figure")),
      claim: "generated-local-figure",
    };
    r.secret = {
      memory_detail:
        "The surviving account omits a disagreement over the shared contribution.",
    };
  } else if (domain === "character" || domain === "npc") {
    const occupation = role
      ? pack.occupations.find((x) => x.id === role)
      : pick("occupation", "occupations");
    if (!occupation) throw Error("Unknown role");
    validateSelection([occupation], tags);
    for (const tag of occupation.provides ?? []) tags.add(tag);
    const traits = [pick("trait:0", "traits")];
    traits.push(pick("trait:1", "traits", traits));
    validateSelection(traits, tags);
    pub.name = cultureName(ctx, seed);
    pub.naming = {
      model: "Lexicon native phonotactics with original profiles",
      culture_id: ctx.culture_id,
      confidence: "research-approximation",
    };
    pub.birthplace = {
      id: ctx.source_id,
      name: ctx.display_name,
      world_id: ctx.world.id,
    };
    pub.age_band = seed.pick("age", ["young-adult", "adult", "older-adult"]);
    pub.occupation = occupation.id;
    pub.training = small("training", "training");
    pub.family = small("family", "family");
    pub.childhood = small("childhood", "childhood");
    pub.value = small("value", "value");
    pub.habit = small("habit", "habit");
    pub.concern = small("concern", "concern");
    pub.contact = {
      id: r.id + "/contact",
      name: cultureName(ctx, seed.child("contact")),
      role: small("contact", "contact"),
      relationship: "known-person",
    };
    pub.traits = traits.map((x) => x.id);
    pub.keepsake = small("keepsake", "keepsake");
    pub.local_knowledge = {
      kind: "public-origin",
      burg_id: ctx.source_id,
      cell_id: ctx.cell_id,
      hidden_pois: [],
    };
    if (domain === "character") {
      pub.first_failure = small("failure", "failure");
      pub.first_success = small("success", "success");
      pub.motivation = small("motivation", "motivation");
      pub.hometown_relationship = "leaving-with-unfinished-obligations";
    } else {
      pub.role = occupation.id;
      pub.desire = small("desire", "motivation");
      pub.speech_style = seed.pick("speech", [
        "brief",
        "measured",
        "plain",
        "careful",
      ]);
      pub.physical_identifier = seed.pick("identifier", [
        "a repaired sleeve",
        "an ink-stained cuff",
        "a worn plain ring",
        "a carefully folded cloth",
        "a scuffed carrying bag",
      ]);
    }
    r.secret = { private_fact: small("secret", "secret") };
  } else if (domain === "mundane" || domain === "rare") {
    const item = pick("base", "items");
    tags.add("item:" + item.category);
    pub.base = {
      type: item.id,
      category: item.category,
      material: seed.pick("material", item.materials),
      secondary_material: item.secondary.length
        ? seed.pick("secondary", item.secondary)
        : null,
    };
    if (["linen", "wool", "leather", "paper", "wicker"].includes(pub.base.material))
      tags.add("flexible");
    pub.quality = small("quality", "qualities");
    pub.condition = small("wear", "wear");
    pub.maker = {
      role: small("maker", "makers"),
      culture_id: ctx.culture_id,
      place: { world_id: ctx.world.id, burg_id: ctx.source_id },
      identity: r.id + "/maker",
    };
    pub.age_band = seed.pick("age", [
      "recent",
      "one-generation",
      "several-generations",
    ]);
    pub.use = item.use;
    pub.visible_mark = small("mark", "marks");
    const n = domain === "rare" ? 4 : 2,
      transfers = [];
    pub.ownership = [
      {
        owner: r.id + "/owner:0",
        role:
          domain === "rare"
            ? small("owner:0", "rare_roles")
            : "first-household",
        event: "created",
        index: 0,
      },
    ];
    for (let k = 1; k < n; k++) {
      const transfer = pick("transfer:" + k, "item_events", transfers);
      transfers.push(transfer);
      pub.ownership.push({
        owner: r.id + "/owner:" + k,
        from: pub.ownership[k - 1].owner,
        role:
          domain === "rare"
            ? small("owner:" + k, "rare_roles")
            : "later-household",
        event: transfer.id,
        index: k,
      });
    }
    pub.repair = {
      event: seed.pick(
        "repair",
        item.category === "clothing" ||
          ["linen", "wool", "leather", "paper", "wicker"].includes(pub.base.material)
          ? [
              "a-protective-wrapping-was-renewed",
              "a-storage-cover-was-replaced",
            ]
          : pack.repairs.map((x) => x.id),
      ),
      after_owner: pub.ownership.at(-1).owner,
    };
    if (domain === "rare") {
      pub.reputation = small("reputation", "reputations");
      r.rumours = [
        {
          id: "single-owner",
          claim: "The object has never left its first household.",
          truth: "false",
        },
      ];
      r.secret = {
        private_history: small("private", "item_secrets"),
        exceptional_property: null,
      };
    } else {
      pub.small_detail = seed.pick("detail", [
        "kept-with-spare-parts",
        "recorded-in-an-ordinary-account",
        "returned-with-a-thank-you",
        "stored-under-a-reused-cover",
      ]);
    }
  } else if (domain === "contract") {
    // Contract is an unactivated proposal. Related IDs are explicit references,
    // never hidden source sites or actual quest state.
    pub.status = "research-proposal";
    pub.issuer = { id: r.id + "/issuer", role: small("issuer", "occupations") };
    const goal = pick("goal", "contracts");
    pub.goal = goal.id;
    pub.reason = "preserve-or-return-ordinary-property";
    pub.known_complication = small("complication", "complications");
    pub.target = {
      world_id: ctx.world.id,
      burg_id: ctx.source_id,
      kind: goal.target_kind,
      identity: r.id + "/target",
    };
    pub.evidence = seed.pick("evidence", [
      "a-marked-object",
      "a-copied-account",
      "a-witness-description",
      "a-repair-tally",
    ]);
    pub.alternate_resolution = "compare-accounts-with-a-second-witness";
    pub.reward_theme = seed.pick("reward", [
      "repair-work",
      "supplies",
      "a-small-payment",
      "practical-instruction",
    ]);
    pub.time_sensitivity = "unspecified";
    if (site_record) {
      if (
        site_record.domain !== "site" ||
        site_record.source.world_id !== ctx.world.id ||
        site_record.source_visibility !== "public"
      )
        throw Error("Invalid or hidden contract source site");
      pub.related_site = {
        source_kind: "markers",
        source_id: site_record.source.id,
        cell_id: site_record.source.cell_id,
        world_id: site_record.source.world_id,
        enrichment_id: site_record.id,
      };
    }
    r.secret = {
      complication:
        "The issuer has not disclosed an incomplete ownership account.",
    };
  } else {
    pub.status = "research-group";
    const groupType = pick("type", "group_types");
    pub.type = groupType.id;
    pub.purpose = pick(
      "purpose",
      pack.group_purposes.filter((x) =>
        groupType.allowed_purposes.includes(x.id),
      ),
    ).id;
    pub.culture_id = ctx.culture_id;
    pub.name = "The " + cultureName(ctx, seed) + " Circle";
    pub.leader_role = "elected-record-keeper";
    pub.resource = "shared-tools-and-contributions";
    pub.symbol = small("symbol", "symbols");
    pub.related_entities = [
      {
        id: r.id + "/partner",
        kind: "group",
        type: "household-workroom",
        name: null,
      },
    ];
    pub.relationship = {
      other: r.id + "/partner",
      type: "shared-record-keeping",
      canonical: false,
    };
    r.secret = { internal_goal: "resolve-an-undisclosed-contribution-dispute" };
  }
  validateRecord(r, ctx);
  return r;
}
export function validateRecord(r, ctx) {
  if (
    r.schema_version !== SCHEMA ||
    r.source.world_id !== ctx.world.id ||
    r.source.world_sha !== ctx.world.sha256 ||
    r.source.cell_id !== ctx.cell_id ||
    r.source.id !== ctx.source_id ||
    r.source.kind !== ctx.source_kind ||
    r.source.state_id !== ctx.state_id ||
    r.source.province_id !== ctx.province_id ||
    r.source.culture_id !== ctx.culture_id ||
    r.source.religion_id !== ctx.religion_id ||
    r.versions.pack_sha !== packSha ||
    r.versions.generator !== VERSION ||
    r.versions.pack !== pack.version
  )
    throw Error("Identity/version mismatch");
  if (r.domain === "character" && !r.scope.startsWith("playthrough:"))
    throw Error("Private character world leakage");
  const tags = contextTags(ctx),
    check = (key, id) => {
      const row = pack[key].find((x) => x.id === id);
      if (!row) throw Error("Unknown pack reference " + key + ":" + id);
      validateSelection([row], tags);
      return row;
    };
  if (r.public.occupation) {
    const occupation = check("occupations", r.public.occupation);
    for (const tag of occupation.provides ?? []) tags.add(tag);
    if (r.public.training) check("training", r.public.training);
  }
  if (r.public.traits)
    validateSelection(
      r.public.traits.map((id) => check("traits", id)),
      tags,
    );
  if (r.domain === "origin") {
    check("memories", r.public.memory.event);
    check("traditions", r.public.tradition.practice);
    check("occupations", r.public.public_craft.occupation);
  }
  if (r.domain === "site") {
    check("purposes", r.public.purpose);
    for (const id of r.public.conditions) check("conditions", id);
    const facets = r.public.conditions.map(
      (id) => check("conditions", id).facet,
    );
    if (new Set(facets).size !== facets.length)
      throw Error("Conflicting condition facets");
    let state = "standing",
      last = Infinity;
    for (const [i, e] of r.public.history.entries()) {
      const row = check("events", e.event);
      if (
        e.index !== i ||
        e.years_before >= last ||
        (row.transition === "preserve" ? state : row.transition) !== e.state ||
        (i > 0 && e.previous_state !== state)
      )
        throw Error("Invalid history chain");
      state = e.state;
      last = e.years_before;
    }
    if (state !== r.public.current_state)
      throw Error("Final history state mismatch");
    const damage = new Set();
    for (const e of r.public.history) {
      const row = check("events", e.event);
      if (row.damage_component) damage.add(row.damage_component);
      if (row.repair_component) damage.delete(row.repair_component);
    }
    if (
      canonical([...damage].sort()) !==
      canonical([...r.public.structural_damage].sort())
    )
      throw Error("Damage chain mismatch");
    const required = {
      roof: "roof-missing",
      walls: "walls-cracked",
      floor: "floor-subsided",
      access: "entrance-blocked",
    };
    for (const c of damage)
      if (!r.public.conditions.includes(required[c]))
        throw Error("History/condition contradiction");
  }
  if (["mundane", "rare"].includes(r.domain)) {
    const item = check("items", r.public.base.type);
    if (
      item.category !== r.public.base.category ||
      !item.materials.includes(r.public.base.material) ||
      !itemCategories.has(item.category)
    )
      throw Error("Incompatible item material");
    const chain = r.public.ownership;
    if (
      !chain.length ||
      chain[0].event !== "created" ||
      new Set(chain.map((x) => x.owner)).size !== chain.length
    )
      throw Error("Invalid ownership chain");
    for (let k = 1; k < chain.length; k++)
      if (chain[k].from !== chain[k - 1].owner || chain[k].index !== k)
        throw Error("Disconnected ownership");
    if (r.public.repair.after_owner !== chain.at(-1).owner)
      throw Error("Repair references missing owner");
  }
  if (r.domain === "group") {
    const t = check("group_types", r.public.type);
    if (!t.allowed_purposes.includes(r.public.purpose))
      throw Error("Group purpose contradiction");
    if (
      !r.public.related_entities.some(
        (e) => e.id === r.public.relationship.other,
      )
    )
      throw Error("Unresolved group relationship");
  }
  if (
    r.domain === "contract" &&
    r.public.related_site?.world_id &&
    r.public.related_site.world_id !== ctx.world.id
  )
    throw Error("Cross-world contract reference");
  return true;
}
export function project(r, knowledge) {
  if (knowledge?.world_id !== r.source.world_id) return null;
  if (
    r.domain === "character" &&
    knowledge.playthrough_id !== r.scope.slice(12)
  )
    return null;
  if (r.domain === "site" && !knowledge.known_entities?.includes(r.id))
    return null;
  const result = {
    schema_version: SCHEMA,
    id: r.id,
    domain: r.domain,
    source: structuredClone(r.source),
    public: structuredClone(r.public),
    versions: structuredClone(r.versions),
  };
  const revealKeys = {
    site: ["historical_detail"],
    origin: ["memory_detail"],
    character: ["private_fact"],
    npc: ["private_fact"],
    rare: ["private_history"],
    contract: ["complication"],
    group: ["internal_goal"],
  };
  result.discoveries = (revealKeys[r.domain] ?? [])
    .filter((key) => knowledge.discovered_fields?.includes(r.id + ":" + key))
    .map((key) => ({ key, label: "Discovered", value: r.secret[key] }));
  result.rumours = r.rumours
    .filter((x) => knowledge.heard_rumours?.includes(r.id + ":" + x.id))
    .map((x) => ({ id: x.id, label: "Rumour", claim: x.claim }));
  // No generic recursive secret filter: only explicit fields are projected.
  return result;
}
export function envelope(base, records) {
  if (!records.length) throw Error("Empty sidecar");
  const scope = records[0].scope,
    provider = records[0].versions.provider;
  if (
    records.some(
      (r) =>
        r.source.world_id !== base.id ||
        r.source.world_sha !== base.sha256 ||
        r.scope !== scope ||
        r.versions.provider !== provider ||
        r.versions.generator !== VERSION ||
        r.versions.pack_sha !== packSha,
    ) ||
    new Set(records.map((x) => x.id)).size !== records.length
  )
    throw Error("Mixed or duplicate sidecar");
  const payload = {
    schema_version: SCHEMA,
    base_world: structuredClone(base),
    scope,
    provider,
    generator_version: VERSION,
    content_pack_version: pack.version,
    content_pack_sha: packSha,
    records: structuredClone(records).sort((a, b) => a.id.localeCompare(b.id, "en")),
  };
  return { ...payload, enrichment_sha: sha(canonical(payload)) };
}
export function verifySidecar(e, base, pinnedSha) {
  const { enrichment_sha, ...p } = e;
  if (
    !/^[a-f0-9]{64}$/.test(pinnedSha ?? "") ||
    enrichment_sha !== pinnedSha ||
    e.schema_version !== SCHEMA ||
    e.base_world.id !== base.id ||
    e.base_world.sha256 !== base.sha256 ||
    canonical(e.base_world) !== canonical(base) ||
    !["sha-staged", "lexicon-staged"].includes(e.provider) ||
    !e.records.length ||
    sha(canonical(p)) !== enrichment_sha ||
    e.generator_version !== VERSION ||
    e.content_pack_version !== pack.version ||
    e.content_pack_sha !== packSha ||
    new Set(e.records.map((r) => r.id)).size !== e.records.length ||
    e.records.some(
      (r) =>
        r.schema_version !== SCHEMA ||
        !domains.includes(r.domain) ||
        (r.domain === "character" ? !r.scope.startsWith("playthrough:") : r.scope !== "world") ||
        r.source.world_id !== base.id ||
        r.source.world_sha !== base.sha256 ||
        r.scope !== e.scope ||
        r.versions.provider !== e.provider ||
        r.versions.generator !== VERSION ||
        r.versions.pack !== pack.version ||
        r.versions.pack_sha !== packSha,
    )
  )
    throw Error("Invalid pinned sidecar");
  return e;
}
export function writeSidecar(path, e) {
  verifySidecar(e, e.base_world, e.enrichment_sha);
  mkdirSync(dirname(path), { recursive: true });
  const data = canonical(e) + "\n",
    temp = path + "." + process.pid + ".tmp";
  writeFileSync(temp, data, { flag: "wx" });
  try {
    linkSync(temp, path);
  } catch (error) {
    if (error.code !== "EEXIST" || readFileSync(path, "utf8") !== data)
      throw error;
  } finally {
    unlinkSync(temp);
  }
  return path;
}
export const find = (key, id) => {
  const row = pack[key].find((x) => x.id === id);
  if (!row) throw Error("Unknown renderer reference " + id);
  return row;
};
