// Rant owns phrasing, never objective facts. Every semantic dictionary table
// is a singleton derived from an explicitly public projection. Alternatives
// express the same proposition. Renderer version is independent of geography.
import { compile, explain } from "../vendor/rant/engine.js";
import { grammar } from "../vendor/lexicon/grammar/index.js";
import { createContext } from "../vendor/lexicon/core/index.js";
import { sha, canonical } from "../../game77/src/core.mjs";
import { find, pack, packSha, VERSION, SCHEMA } from "./framework.mjs";
export const RENDERER = "trhgd-game78-rant-1";
const table = (name, value) => ({
  name,
  subs: ["default"],
  entries: [{ forms: [String(value)], classes: [] }],
});
const get = (key, id) => find(key, id).label;
const publicOnly = (p) => {
  if (!p || p.secret || p.provenance || p.source_flavour || p.seed || p.scope)
    throw Error("Renderer requires a public projection");
};
function facts(p) {
  const f = p.public,
    out = {};
  if (p.domain === "site") {
    out.purpose = find("purposes", f.purpose).label;
    out.condition = f.conditions
      .map((id) => find("conditions", id).label)
      .join(", ");
    out.events = f.history
      .slice(1)
      .map((e) => find("events", e.event).clause)
      .join("; later, it ");
    out.culture = p.source.culture_id > 0 ? "local" : "unspecified";
  }
  if (p.domain === "origin") {
    const m = find("memories", f.memory.event),
      t = find("traditions", f.tradition.practice);
    out.hometown = f.hometown;
    out.actors = m.actors;
    out.memory = m.action;
    out.legacy = m.legacy;
    out.practice = t.practice;
    out.craft = find("occupations", f.public_craft.occupation).key;
    out.figure = f.local_figure.name;
    out.role = f.local_figure.role.replaceAll("-", " ");
  }
  if (["character", "npc"].includes(p.domain)) {
    out.firstname = f.name;
    out.home = f.birthplace.name;
    out.occupation = find("occupations", f.occupation).key;
    out.family = get("family", f.family);
    out.childhood = get("childhood", f.childhood);
    out.training = get("training", f.training);
    out.value = get("value", f.value);
    out.habit = get("habit", f.habit);
    out.habitplural = out.habit.replace(/^(\w+)s /, "$1 ");
    out.keepsake = get("keepsake", f.keepsake);
    out.traits = f.traits.map((id) => find("traits", id).key).join(" and ");
    out.concern = get("concern", f.concern);
    if (p.domain === "character") {
      out.failure = get("failure", f.first_failure);
      out.success = get("success", f.first_success);
      out.motivation = get("motivation", f.motivation);
    } else {
      out.identifier = f.physical_identifier;
      out.desire = get("motivation", f.desire);
    }
  }
  if (["mundane", "rare"].includes(p.domain)) {
    out.item = find("items", f.base.type).key;
    out.material = f.base.material;
    out.maker = get("makers", f.maker.role);
    out.quality = get("qualities", f.quality);
    out.wear = get("wear", f.condition);
    out.mark = get("marks", f.visible_mark);
    out.repair = get("repairs", f.repair.event);
    out.transfer = get("item_events", f.ownership[1].event);
    out.lasttransfer = f.ownership
      .slice(2)
      .map((e) => get("item_events", e.event))
      .join(", then ");
    out.use = f.use;
    if (p.domain === "rare") {
      out.reputation = get("reputations", f.reputation);
      out.owner = get("rare_roles", f.ownership[0].role);
    } else out.detail = f.small_detail.replaceAll("-", " ");
  }
  if (p.domain === "contract") {
    out.issuer = find("occupations", f.issuer.role).key;
    out.goal = get("contracts", f.goal);
    out.complication = get("complications", f.known_complication);
    out.evidence = f.evidence.replaceAll("-", " ");
    out.reward = f.reward_theme.replaceAll("-", " ");
  }
  if (p.domain === "group") {
    out.groupname = f.name;
    out.type = get("group_types", f.type);
    out.purpose = get("group_purposes", f.purpose);
    out.symbol = get("symbols", f.symbol);
  }
  return out;
}
export const patterns = {
  site: "{The <purpose :: site> survives with|What remains of the <purpose :: site> has} <condition>. {Its history records that it|Later accounts say it} <events>.",
  origin:
    "{In <hometown :: town>,|People in <hometown :: town> remember how} <actors> <memory>. {That work is still recalled by <legacy>.|A trace remains: <legacy>.} Local households <practice>.",
  character:
    "<firstname :: person> grew up in <home :: home>, in [a] <family>. {Early work involved|Childhood included} <childhood>. <::person> learned the work of [a] <occupation> from <training>. {They once|Early in that work, they} <failure>, but later <success>. {Now they hope to|They are leaving <::home> to} <motivation>.",
  npc: "<firstname :: person> works as [a] <occupation> in <home>. {They are known to be|Neighbours describe them as} <traits>. <::person> values <value> and <habit>. {One visible detail is|They can be recognised by} <identifier>. They hope to <desire>.",
  mundane:
    "{This <item :: object>, made from <material>, was made by|Made from <material>, this <item :: object> came from} <maker>. It is <quality> and <wear>. It was <transfer>; afterward, <repair>. {It remains an ordinary possession for|Its purpose is} <use>.",
  rare: "This <item :: object>, made from <material>, first belonged to <owner>. It was <transfer>, then <lasttransfer>. {During later care,|At a later repair,} <repair>. It is <reputation>; its surface bears <mark>.",
  contract:
    "[case:first][a] <issuer> asks someone to <goal>. {The difficulty is that|They explain that} <complication>. [case:sentence]<evidence> may help establish what happened. The proposed reward is <reward>.",
  group:
    "<groupname :: circle> is [a] <type>. Its public purpose is to <purpose>. Its members use <symbol> as a sign. [if:circle]{<::circle> keeps its shared records in ordinary accounts.}{The members keep ordinary accounts.}",
};
const lexiconPatterns = {
  site: [
    "The #purpose# remains with #condition#. Its history records that it #events#.",
    "What remains of the #purpose# has #condition#. Later accounts say it #events#.",
  ],
  origin: [
    "In #hometown#, #actors# #memory#. A trace remains: #legacy#. Local households #practice#.",
    "People in #hometown# remember how #actors# #memory#. That work is still recalled by #legacy#. Local households #practice#.",
  ],
  character: [
    "#firstname# grew up in #home#, in #family.a#. Childhood included #childhood#. #firstname# learned the work of #occupation.a# from #training#. They once #failure#, but later #success#. They hope to #motivation#.",
    "Raised in #home#, #firstname# belonged to #family.a#. Early work involved #childhood#. #training.capitalize# taught them the work of #occupation.a#. After they #failure#, they later #success#. They are leaving to #motivation#.",
  ],
  npc: [
    "#firstname# works as #occupation.a# in #home#. They are #traits#. #firstname# values #value# and #habit#. They can be recognised by #identifier#. They hope to #desire#.",
  ],
  mundane: [
    "This #item#, made from #material#, came from #maker#. It is #quality# and #wear#. It was #transfer#; afterward, #repair#. Its purpose is #use#.",
  ],
  rare: [
    "This #item#, made from #material#, first belonged to #owner#. It was #transfer#, then #lasttransfer#. During later care, #repair#. It is #reputation#; its surface bears #mark#.",
  ],
  contract: [
    "#issuer.a.capitalize# asks someone to #goal#. The difficulty is that #complication#. #evidence.capitalize# may help establish what happened. The proposed reward is #reward#.",
  ],
  group: [
    "#groupname# is #type.a#. Its public purpose is to #purpose#. Its members use #symbol# as a sign.",
  ],
};
export function render(
  publicProjection,
  { style = "rant", extended = false, trace = false, compact = false } = {},
) {
  publicOnly(publicProjection);
  if (publicProjection.schema_version !== SCHEMA || publicProjection.versions?.generator !== VERSION || publicProjection.versions?.pack !== pack.version || publicProjection.versions?.pack_sha !== packSha || !["sha-staged", "lexicon-staged"].includes(publicProjection.versions?.provider)) throw Error("Renderer requires its exact pinned fact pack and generator");
  if (!["rant", "fixed", "lexicon"].includes(style)) throw Error("Unsupported renderer style");
  const values = facts(publicProjection);
  const dictionary = {
    tables: Object.fromEntries(
      Object.entries(values).map(([k, v]) => [k, table(k, v)]),
    ),
  };
  const seed = sha(
    canonical([
      RENDERER,
      publicProjection.versions,
      publicProjection.id,
      publicProjection.source.world_id,
      publicProjection.public,
    ]),
  );
  if (style === "lexicon") {
    const rules = {
      start: lexiconPatterns[publicProjection.domain],
      ...Object.fromEntries(
        Object.entries(values).map(([k, v]) => [k, () => v]),
      ),
    };
    const text = grammar(rules, {
      id: "game78-public:" + publicProjection.domain,
    }).generate(createContext({ seed }));
    if (/\(\(|undefined|[<>]/.test(text))
      throw Error("Unresolved Lexicon grammar: " + text);
    return {
      renderer: RENDERER + "-lexicon-control",
      style,
      text,
      sha256: sha(text),
    };
  }
  let pattern = compact && publicProjection.domain === "origin" ? "[case:first]<actors> <memory>. Local households <practice>." : patterns[publicProjection.domain];
  if (!pattern) throw Error("Unsupported render domain");
  if (extended && publicProjection.domain === "character")
    pattern +=
      " They are <traits> and value <value>. They <habitplural>. Their concern is <concern>. They still carry <keepsake>.";
  if (style === "fixed") {
    // Comparable exact-fact control uses first weighted-free prose branches. This
    // is an explicit deterministic baseline, not a second fact generator.
    pattern = pattern.replace(/\{([^{}|]+)\|[^{}]+\}/g, "$1");
  }
  const run = trace
    ? explain(pattern, { dictionary, seed })
    : { text: compile(pattern, { dictionary, seed }).run() };
  if (/[<>]|undefined|\{[^}]*\}/.test(run.text))
    throw Error("Unresolved grammar: " + run.text);
  return {
    renderer: RENDERER,
    style,
    text: run.text,
    sha256: sha(run.text),
    ...(trace ? { picks: run.picks } : {}),
  };
}
export function originPayload(r, enrichmentSha, {compact = false} = {}) {
  if (r.domain !== "origin" || r.scope !== "world")
    throw Error("Not public world origin");
  const p = {
    id: r.id,
    domain: r.domain,
    public: r.public,
    source: r.source,
    versions: r.versions,
    schema_version: 2,
  };
  const rendered = render(p, {compact});
  return {
    schema_version: 1,
    world_id: r.source.world_id,
    burg_id: r.source.id,
    enrichment_sha: enrichmentSha,
    content_pack_version: r.versions.pack,
    record_id: r.id,
    label: "Local memory",
    text: rendered.text,
  };
}
