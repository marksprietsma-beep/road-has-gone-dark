class_name CombatArt
extends RefCounted
## Presentation only. No combat RNG, save service or ancestry roster dependency.
const CATALOG := "res://data/art/styles.json"
static var preference_path := "user://presentation.cfg"
static var _catalog: Array = []
static var _textures := {}

static func styles() -> Array:
 if _catalog.is_empty(): _catalog=JSON.parse_string(FileAccess.get_file_as_string(CATALOG)).styles
 return _catalog

static func texture(path: String) -> Texture2D:
 if not _textures.has(path):
  _textures[path]=load(path) if ResourceLoader.exists(path) else null
 return _textures[path]

static func paths_in(value: Variant) -> Array[String]:
 var found: Array[String]=[]
 if value is Dictionary:
  if value.has("path"): found.append(value.path)
  if value.has("sequence"):
   for path in value.sequence: found.append("res://assets/combat/"+path)
  for key in value:
   if value[key] is Dictionary or value[key] is Array: found.append_array(paths_in(value[key]))
 elif value is Array:
  for child in value: found.append_array(paths_in(child))
 return found

static func available(style: Dictionary) -> bool:
 return paths_in(style).all(func(path: String):return ResourceLoader.exists(path))

static func preferred() -> String:
 var file := ConfigFile.new()
 if file.load(preference_path)==OK:
  var id: String=str(file.get_value("combat","art_style","lpc"))
  if styles().any(func(s: Dictionary):return s.id==id and available(s)): return id
 for style in styles():
  if available(style): return style.id
 return ""

static func remember(id: String) -> Error:
 var file := ConfigFile.new()
 file.load(preference_path)
 file.set_value("combat","art_style",id)
 return file.save(preference_path)

static func profile(identity: String, member: Dictionary, descriptors: Dictionary={}) -> Dictionary:
 # The prototype people ID is provenance, never a body/skin/race lookup.
 var value := {"version":1,"identity":identity,"visual_seed":"trhgd-visual-v1:"+identity,
  "identity_layers":{"ancestry_ref":member.get("people_id",""),"heritage":{},"culture":member.get("origin_refs",{}),"background":member.get("background_id","")},
  "body":{"plan":"humanoid","size":1.0,"proportions":[1.0,1.0],"surface":"unspecified","parts":["head","torso","left_arm","right_arm","left_leg","right_leg"],"features":[]},
  "heritage_layers":[],"acquired_layers":[],"transformation":{},"equipment_layers":[]}
 for key in descriptors: value[key]=descriptors[key].duplicate(true) if descriptors[key] is Dictionary or descriptors[key] is Array else descriptors[key]
 # External equipment/transform descriptors can change without reseeding identity.
 value.identity=identity
 return value

static func recipe(style_id: String, unit: Dictionary, member: Dictionary={}, descriptors: Dictionary={}) -> Dictionary:
 var p := profile(str(unit.id),member,descriptors)
 var role := "scout" if unit.weapon=="bow" else "adept" if unit.weapon=="staff" else "vanguard"
 if unit.weapon=="shortblade" and member.get("role_id","")=="expert": role="expert"
 var style: Dictionary={}
 for candidate in styles():
  if candidate.id==style_id: style=candidate;break
 var seed: int=("appearance:"+str(p.visual_seed)).sha256_text().left(7).hex_to_int()
 var body: Dictionary=p.transformation.get("body",p.body)
 var warnings: Array[String]=[]
 var replacement: Dictionary=body.get("visual_recipes",{}).get(style_id,{})
 var replacement_valid := not replacement.is_empty() and replacement.has("native") and replacement.has("animations") and not paths_in(replacement).is_empty() and paths_in(replacement).all(func(path: String):return path.begins_with("res://assets/combat/"+style_id+"/") and ResourceLoader.exists(path))
 if body.get("plan","humanoid")!="humanoid" and not replacement_valid: warnings.append("Unsupported body plan: neutral humanoid preview")
 if not replacement_valid and (body.get("surface","unspecified")!="unspecified" or not body.get("features",[]).is_empty()): warnings.append("Anatomical features not supplied by this preview")
 if not style.has("roles") or not available(style): return {"available":false,"profile":p,"role":role,"warnings":["Art provider unavailable"],"style_id":style_id}
 var selected: Variant=style.roles[role]
 if selected is Array: selected=selected[seed%selected.size()]
 var result: Dictionary=selected.duplicate(true)
 # A provider-specific full silhouette can replace the inherited body visually.
 # This accepts future authored art; it implements no transformation gameplay.
 if replacement_valid: result=replacement.duplicate(true)
 result.merge({"available":true,"profile":p,"role":role,"style_id":style_id,"provider_version":style.version,"variant":seed,"warnings":warnings,"scale":clampf(float(body.get("size",1.0)),0.6,1.35)})
 if style_id=="lpc" and not replacement_valid:
  var hair: Dictionary=style.hair[seed%style.hair.size()]
  for animation in result.animations: result.animations[animation].append_array(hair[animation] if role!="adept" else [])
 if style_id=="kenney" and not replacement_valid:
  # Original atlas hairstyles, no skin recolouring and no ancestry assumptions.
  for animation in result.animations: result.animations[animation][3].rect=[(19+seed%5)*17,8*17,16,16]
 if style_id=="navinius" and not replacement_valid:
  for animation in result.animations: result.animations[animation][1].path="res://assets/combat/navinius/Modular RPG Pixel Art/Customization/blonde"+("" if seed%4==0 else str(seed%4+1))+".png"
 for group in [p.heritage_layers,p.acquired_layers,p.equipment_layers,p.transformation.get("layers",[])]:
  for overlay in group:
   if overlay.get("provider",style_id)!=style_id or not overlay.get("path","").begins_with("res://assets/combat/"+style_id+"/") or not ResourceLoader.exists(overlay.get("path","")):
    result.warnings.append("Unsupported visual overlay: "+str(overlay.get("id","unnamed")));continue
   for animation in result.animations: result.animations[animation].append(overlay.duplicate(true))
 var proportions: Array=body.get("proportions",[1.0,1.0])
 result.proportions=[clampf(float(proportions[0]),0.6,1.35),clampf(float(proportions[1]),0.6,1.35)]
 result.recipe_hash=RulesJson.digest(result)
 return result
