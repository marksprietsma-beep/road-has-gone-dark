class_name OpportunityGenerator
extends RefCounted
## V2 owns activity selection; frozen V1 still owns legal board composition.
const VERSION := "sandbox-opportunities-v2"
const SOURCE := "res://data/sandbox/opportunities-v2.json"
static var _rules := {}
static func rules() -> Dictionary:
 if _rules.is_empty():_rules=RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string(SOURCE)))
 return _rules
static func template(id: String) -> Dictionary:
 for activity in rules().activities:
  if activity.id==id:return activity
 return {}
static func seed_for(world: GameWorldTemplate,home: int,content_sha: String) -> String:
 return RulesJson.digest([VERSION,FileAccess.get_sha256(SOURCE),world.source_sha256,home,int(world.get_record("burg",home).cell),content_sha])
static func select(seed: String,environment: String,near_route: bool,family: String,used: Array) -> Dictionary:
 var pool: Array=[];var total := 0
 for activity in rules().activities:
  if activity.id in used or (not family.is_empty() and activity.family!=family) or (activity.requires_route and not near_route):continue
  var weight := int(activity.weights.get(environment,0))
  if weight<=0:continue
  pool.append({"activity":activity,"weight":weight});total+=weight
 if total==0:return {}
 var chosen := SandboxGenerator.pick(seed,"activity",total)
 for item in pool:
  chosen-=int(item.weight)
  if chosen<0:return item.activity.duplicate(true)
 return {}
static func generate(world: GameWorldTemplate,home_id: int,content: Dictionary) -> Dictionary:
 var base := SandboxGenerator.generate(world,home_id,content)
 if base.is_empty():return {}
 var seed := seed_for(world,home_id,content.sha)
 base.version=VERSION;base.seed=seed;base["rules_sha"]=FileAccess.get_sha256(SOURCE)
 var families: Array=["recovery","investigation","contested",""]
 # Coverage constraints are independent of site index/placement, then weighted.
 families.sort_custom(func(a: String,b: String):return RulesJson.digest([seed,a])<RulesJson.digest([seed,b]))
 var used: Array=[]
 for i in base.sites.size():
  var site: Dictionary=base.sites[i]
  var route := SandboxGenerator.nearest_route(world,site.world_position,int(base.cell_id))
  var activity := select(seed+":"+str(i),site.context.environment,float(route.distance)<=2.0,families[i],used)
  if activity.is_empty():return {}
  used.append(activity.id)
  site.id="sandbox-site:"+RulesJson.digest([VERSION,world.world_id,home_id,int(base.cell_id),int(site.context.placement_slot)])
  site.opportunity_id="opportunity:"+RulesJson.digest([VERSION,site.id])
  site.kind=activity.kind;site.name=activity.name;site.description=activity.description;site["activity_id"]=activity.id
  site.reward="Combat victory: 10 journey XP each. Noncombat: provisions or information only; no battle XP."
  site.context.route_ref=int(route.id) if activity.requires_route else -1
  var local_seed := RulesJson.digest([seed,site.id])
  site.provenance={"version":VERSION,"seed":local_seed,"world_sha":world.source_sha256,"content_sha":content.sha,"rules_sha":base.rules_sha,"authorship":"TRHGD generated local fiction"}
  var recipe := {"version":SandboxGenerator.VERSION,"rules_sha":FileAccess.get_sha256(SandboxGenerator.SOURCE),"seed":local_seed,"site_id":site.id,"kind":site.kind,"environment":site.context.environment,"composition":SandboxGenerator.pick(local_seed,"opponents",SandboxGenerator.rules().compositions.size())}
  site.board=SandboxGenerator.battlefield(recipe)
  if site.board.is_empty():return {}
 return base
static func choices(state: Dictionary,site: Dictionary) -> Array:
 var activity := template(site.activity_id)
 var options: Array=activity.choices.duplicate(true)
 for option in options:option.participant="";option.profession=""
 # Real saved profession, not ancestry, intended role or an invented skill roll.
 for member in state.party.members:
  var profession := str(member.generated_facts.occupation_id)
  if profession not in activity.professions:continue
  var supported: String="inspect" if activity.family=="contested" else "careful"
  var original: Dictionary=options.filter(func(o: Dictionary):return o.id==supported)[0]
  var contribution := original.duplicate(true)
  contribution.id="companion:"+str(member.character_id)
  contribution.label=str(member.name)+": help as a "+profession.replace("-"," ")
  contribution.provisions=maxi(0,int(original.provisions)-1)
  if activity.family=="recovery":contribution.event="quick"
  contribution.participant=member.character_id;contribution.profession=profession
  options.append(contribution)
 return options
