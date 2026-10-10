class_name CombatArt
extends RefCounted
## Presentation only: stable identity, real equipment, no tactical RNG/save writer.
const CATALOG := "res://data/art/styles.json"
static var preference_path := "user://presentation.cfg"
static var _catalog: Array=[]
static var _textures := {}
static var _thumbnails := {}
static var _preview_units := {}
static var _preview_key := ""
static func frame_view(layer: Dictionary,index: int,facing: int) -> Dictionary:
 var frame := Vector2(layer.frame[0],layer.frame[1])
 var row := 0 if int(layer.get("directions",4))==1 else facing
 var offset: Array=layer.get("offset",[0,0])
 return {"texture":texture(layer.path,layer.get("palette",{})),"region":Rect2(Vector2(index*frame.x,row*frame.y),frame),"offset":Vector2(offset[0],offset[1])}
static func thumbnail(art: Dictionary) -> Texture2D:
 # Same native idle layers, palettes, facing and offsets as the combat renderer.
 if not art.get("available",false):return null
 var key: String=art.recipe_hash
 if _thumbnails.has(key):return _thumbnails[key]
 var canvas := Image.create(int(art.native),int(art.native),false,Image.FORMAT_RGBA8)
 canvas.fill(Color.TRANSPARENT)
 for layer in art.animations.idle:
  var view := frame_view(layer,0,2)
  if view.texture==null:continue
  var image: Image=view.texture.get_image();image.convert(Image.FORMAT_RGBA8)
  canvas.blend_rect(image,Rect2i(view.region),Vector2i(view.offset))
 if _thumbnails.size()>=64:_thumbnails.clear()
 _thumbnails[key]=ImageTexture.create_from_image(canvas)
 return _thumbnails[key]
static func party_units(state: Dictionary) -> Dictionary:
 # Pure starting-build preview, never a second preparation/save writer.
 if state.get("party",{}).get("members",[]).is_empty():return {}
 var key := RulesJson.digest([state.party,state.get("mechanics",{})])
 if key==_preview_key:return _preview_units.duplicate(true)
 var candidate: Dictionary=state.duplicate(true);candidate.party.status="ready"
 var result := RulesRecords.preview_preparation(candidate)
 if not result.ok:return {}
 var engine := TacticalCombat.new();var units := {}
 for member in candidate.party.members:
  var record: Dictionary=result.candidate.mechanics.records[member.character_id]
  units[member.character_id]=engine.unit(member.character_id,member.name,"party",[0,0],record,TacticalCombat.weapon_for(record))
 _preview_key=key;_preview_units=units
 return units.duplicate(true)
static func styles() -> Array:
 if _catalog.is_empty(): _catalog=JSON.parse_string(FileAccess.get_file_as_string(CATALOG)).styles
 return _catalog
static func texture(path: String, palette: Dictionary={}) -> Texture2D:
 var key := path+JSON.stringify(palette)
 if _textures.has(key): return _textures[key]
 var source: Texture2D=load(path) if ResourceLoader.exists(path) else null
 if source==null or palette.is_empty(): _textures[key]=source;return source
 # Cache exact six-shade artwork adaptations; preserve original PNG/alpha/eye colours.
 var image := source.get_image();image.convert(Image.FORMAT_RGBA8)
 var bytes := image.get_data();var replacements := {}
 for i in palette.source.size(): replacements[str(palette.source[i]).hex_to_int()]=str(palette.target[i]).hex_to_int()
 for i in range(0,bytes.size(),4):
  if bytes[i+3]==0: continue
  var rgb: int=(int(bytes[i])<<16)|(int(bytes[i+1])<<8)|int(bytes[i+2])
  if replacements.has(rgb):
   var target: int=replacements[rgb];bytes[i]=(target>>16)&255;bytes[i+1]=(target>>8)&255;bytes[i+2]=target&255
 _textures[key]=ImageTexture.create_from_image(Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,bytes))
 return _textures[key]
static func paths_in(value: Variant) -> Array[String]:
 var found: Array[String]=[]
 if value is Dictionary:
  if value.has("path"): found.append(value.path)
  for key in value:
   if value[key] is Dictionary or value[key] is Array: found.append_array(paths_in(value[key]))
 elif value is Array:
  for child in value: found.append_array(paths_in(child))
 return found
static func available(style: Dictionary) -> bool:
 return not style.is_empty() and paths_in(style).all(func(path: String):return ResourceLoader.exists(path))
static func preferred() -> String:
 # Retired experiment preferences never select an absent provider or touch campaign saves.
 return "lpc"
static func remember(_id: String) -> Error:
 var file := ConfigFile.new();file.load(preference_path);file.set_value("combat","art_style","lpc")
 return file.save(preference_path)
static func profile(identity: String, member: Dictionary, descriptors: Dictionary={}) -> Dictionary:
 var refs: Dictionary=member.get("origin_refs",{})
 var value := {"version":1,"identity":identity,"visual_seed":"trhgd-visual-v1:"+identity,
  "identity_layers":{"ancestry_ref":member.get("people_id",""),"heritage":{},"culture":{"world_id":refs.get("world_id",""),"culture_id":refs.get("culture_id",-1)},"origin":refs.duplicate(true),"background":member.get("background_id","")},
  "body":{"plan":"humanoid","size":1.0,"proportions":[1.0,1.0],"surface":"unspecified","parts":["head","torso","left_arm","right_arm","left_leg","right_leg"],"features":[]},
  "heritage_layers":[],"acquired_layers":[],"transformation":{},"equipment_layers":[]}
 for key in descriptors:value[key]=descriptors[key].duplicate(true) if descriptors[key] is Dictionary or descriptors[key] is Array else descriptors[key]
 value.identity=identity;value.visual_seed="trhgd-visual-v1:"+identity
 return value
static func pick(seed: String, domain: String, count: int) -> int:
 return (domain+":"+seed).sha256_text().left(7).hex_to_int()%count
static func recipe(_style_id: String, unit: Dictionary, member: Dictionary={}, descriptors: Dictionary={}) -> Dictionary:
 var style: Dictionary=styles()[0];var p := profile(str(unit.id),member,descriptors)
 var body: Dictionary=p.transformation.get("body",p.body)
 var warnings: Array[String]=[]
 var equipment: Array=unit.record.get("equipment",[])
 var weapon: String=unit.weapon
 var role := "scout" if weapon=="bow" else "adept" if weapon=="staff" else "vanguard" if equipment.has("mail") else "expert"
 if unit.team=="enemy":role="raider-archer" if weapon=="bow" else "raider-blade"
 var seed: String=p.visual_seed
 var family: String=str(body.get("family","female" if pick(seed,"body",2)==1 else "male"))
 if not family in ["male","female"]:family="male";warnings.append("Unsupported body family: neutral humanoid preview")
 var head: String="female" if family=="female" else "gaunt" if pick(seed,"head",3)==0 else "male"
 var hair: String=["plain","curly","ponytail-front"][pick(seed,"hair-shape",3)]
 var skin: int=pick(seed,"skin",style.palettes.skin.sets.size())
 var hair_color: int=pick(seed,"hair-colour",style.palettes.hair.sets.size())
 var cloth: String=["brown","forest","navy"][pick(seed,"clothes",3)]
 var mage_colour: String="blue" if pick(seed,"mage-clothes",2)==0 else "purple"
 var components: Array[String]=["body-"+family,"pants-"+family,"boots-"+family,"head-"+head]
 if hair=="ponytail-front":components.append("ponytail-back")
 components.append(hair)
 if family=="male" and (pick(seed,"beard",3)==0 or role=="raider-blade"):components.append("beard")
 if weapon=="staff":components.append_array(["skirt-"+family,"mage-"+family+"-"+mage_colour,"hat-"+mage_colour])
 else:components.append("shirt-"+family+"-"+cloth)
 if equipment.has("mail"):components.append("mail-"+family)
 elif equipment.has("leathers"):components.append("leather-"+family)
 if equipment.has("shield"):components.append("shield")
 if equipment.has("mail") and pick(seed,"headwear",3)==0:components.append("helmet")
 if role.begins_with("raider"):
  components.append_array(["cape-back","cape-front"])
  if weapon=="bow":components.append("hood")
 if weapon=="bow":components.append_array(["bow-back","bow-front"])
 elif weapon=="staff":components.append("cane-"+family)
 else:components.append_array(["blade-back","blade-front"])
 components.sort_custom(func(a: String,b: String):return float(style.parts[a].z)<float(style.parts[b].z))
 var animations := {};var fallbacks: Array[String]=[]
 var source_acts := {"idle":"idle","move":"walk","slash":"slash","shoot":"shoot","thrust":"thrust","spell":"spellcast","down":"hurt","hit":"hurt","guard":"walk"}
 for clip in source_acts:
  var layers: Array=[]
  for part_id in components:
   var item: Dictionary=style.parts[part_id];var requested: String=source_acts[clip]
   var is_weapon: bool=part_id.begins_with("blade-") or part_id.begins_with("bow-") or part_id.begins_with("cane-")
   # Casters free their hands; absent defeat equipment is lowered/stowed, not floating.
   if clip=="spell" and is_weapon:continue
   if clip=="down" and not item.actions.has("hurt"):continue
   var native: bool=item.actions.has(requested)
   var layer: Dictionary=item.actions[requested if native else "walk"].duplicate(true)
   layer.part_id=part_id
   layer.hold=not native or clip=="guard"
   if not native:fallbacks.append(part_id+" / "+clip+": held walk pose")
   if part_id.begins_with("body-") or part_id.begins_with("head-"):layer.palette={"source":style.palettes.skin.source,"target":style.palettes.skin.sets[skin]}
   elif part_id in ["plain","curly","ponytail-front","ponytail-back","beard"]:layer.palette={"source":style.palettes.hair.source,"target":style.palettes.hair.sets[hair_color]}
   layers.append(layer)
  animations[clip]=layers
 var replacement: Dictionary=body.get("visual_recipes",{}).get("lpc",{})
 var valid: bool=replacement.has_all(["native","animations"]) and replacement.animations is Dictionary and replacement.animations.has_all(source_acts.keys()) and not paths_in(replacement).is_empty() and paths_in(replacement).all(func(path: String):return path.begins_with("res://assets/combat/lpc/") and ResourceLoader.exists(path))
 if body.get("plan","humanoid")!="humanoid" and not valid:warnings.append("Unsupported body plan: neutral humanoid preview")
 if not valid and (body.get("surface","unspecified")!="unspecified" or not body.get("features",[]).is_empty()):warnings.append("Anatomical features not supplied by this preview")
 if valid:animations=replacement.animations.duplicate(true)
 var proportions: Array=body.get("proportions",[1.0,1.0])
 var result := {"available":available(style),"profile":p,"role":role,"style_id":"lpc","provider_version":style.version,"native":replacement.get("native",64) if valid else 64,"animations":animations,"timelines":CombatPacing.timelines(style.timelines),"variant":pick(seed,"phase",100),"warnings":warnings,"fallbacks":fallbacks,"scale":clampf(float(body.get("size",1.0)),0.7,1.2),"proportions":[clampf(float(proportions[0]),0.8,1.15),clampf(float(proportions[1]),0.8,1.15)],"appearance":{"family":family,"head":head,"hair":hair,"skin":skin,"hair_colour":hair_color},"equipment":equipment.duplicate(),"weapon":weapon}
 for group in [p.heritage_layers,p.acquired_layers,p.equipment_layers,p.transformation.get("layers",[])]:
  for overlay in group:
   if overlay.get("provider","lpc")!="lpc" or not overlay.get("path","").begins_with("res://assets/combat/lpc/") or not ResourceLoader.exists(overlay.get("path","")):
    result.warnings.append("Unsupported visual overlay: "+str(overlay.get("id","unnamed")));continue
   for clip in result.animations:result.animations[clip].append(overlay.duplicate(true))
 result.recipe_hash=RulesJson.digest(result)
 return result
