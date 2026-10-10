class_name CombatPawn
extends Control
## One shared timeline/facing for all original LPC layers. No game commands.
var recipe := {}
var unit := {}
var active := false
var max_hp := 1
var badge := ""
var animation := "idle"
var age := 0.0
var idle_age := 0.0
var facing := 2 # Source order: north, west, south, east. Never mirror equipment.
var travel := Vector2.ZERO
var impulse := Vector2.ZERO
var down := false
var display_hp := 1.0
var feedback := ""
var feedback_age := 1.0
var flash := 0.0
var serial := 0
var hp_settle_age := 2.0
var motion_tween: Tween
var impulse_tween: Tween
var hp_tween: Tween
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func present(value: Dictionary, art: Dictionary, selected: bool, hp: int, label: String) -> void:
 var first := unit.is_empty()
 if not first and int(unit.record.runtime.hp)!=int(value.record.runtime.hp):hp_settle_age=0.0
 unit=value;recipe=art;active=selected;max_hp=hp;badge=label
 if first:
  display_hp=float(unit.record.runtime.hp);down=display_hp<=0
  idle_age=float(recipe.variant)/100.0
  animation="down" if down else "idle";age=2.0 if down else 0.0
 elif down and int(value.record.runtime.hp)>0:down=false;animation="idle";age=0.0
 queue_redraw()
func _process(delta: float) -> void:
 age+=delta;idle_age+=delta;feedback_age+=delta;hp_settle_age+=delta;flash=maxf(0,flash-delta)
 if hp_settle_age>CombatPacing.HP_SETTLE_SECONDS:
  display_hp=float(unit.record.runtime.hp)
  if int(unit.record.runtime.hp)<=0 and not down:down=true;animation="down";age=2.0
 if animation not in ["idle","down","move"] and age>=duration(animation):
  animation="down" if down else "idle";age=2.0 if down else 0.0
 if feedback_age>CombatPacing.FEEDBACK_SECONDS:feedback=""
 queue_redraw()
func duration(clip: String) -> float:
 return CombatPacing.clip_seconds(recipe.timelines,clip)
func face(direction: Vector2) -> void:
 if direction==Vector2.ZERO:return
 facing=3 if direction.x>0 else 1 if direction.x<0 else 2 if direction.y>0 else 0
func cancel_motion() -> void:
 if motion_tween!=null and motion_tween.is_valid():motion_tween.kill()
 if impulse_tween!=null and impulse_tween.is_valid():impulse_tween.kill()
 travel=Vector2.ZERO;impulse=Vector2.ZERO
func play_action(kind: String, direction: Vector2=Vector2.ZERO) -> int:
 serial+=1;cancel_motion();face(direction);age=0.0
 animation="shoot" if kind=="attack" and unit.weapon=="bow" else "thrust" if kind=="attack" and unit.weapon=="staff" else "slash" if kind=="attack" else "spell" if kind in ["spark","slow","healing-thread"] else "guard" if kind=="guard" else "idle"
 if animation in ["slash","thrust"]:
  var toward := direction.normalized() if direction!=Vector2.ZERO else Vector2.RIGHT
  impulse_tween=create_tween();impulse_tween.tween_property(self,"impulse",-toward*2,0.22)
  impulse_tween.tween_property(self,"impulse",toward*3,0.20);impulse_tween.tween_property(self,"impulse",Vector2.ZERO,0.28)
 return serial
func animate_route(points: Array) -> void:
 serial+=1;cancel_motion()
 if points.size()<2:animation="down" if down else "idle";return
 animation="move";age=0.0;travel=points[0]
 motion_tween=create_tween()
 for i in range(1,points.size()):
  var direction: Vector2=points[i]-points[i-1]
  motion_tween.tween_callback(func():face(direction))
  motion_tween.tween_property(self,"travel",points[i],CombatPacing.TILE_SECONDS).set_trans(Tween.TRANS_LINEAR)
 motion_tween.tween_callback(func():animation="down" if down else "idle";age=0.0)
func react(change: int, outcome: String="hit") -> void:
 flash=CombatPacing.FLASH_SECONDS if outcome=="hit" else 0.0;feedback_age=0.0
 feedback="MISS" if outcome=="miss" else "BLOCKED" if outcome=="blocked" else "RESISTED" if outcome=="resisted" else ("+" if change>0 else "−")+str(absi(change))
 if hp_tween!=null and hp_tween.is_valid():hp_tween.kill()
 hp_tween=create_tween();hp_tween.tween_property(self,"display_hp",float(unit.record.runtime.hp),CombatPacing.HP_TWEEN_SECONDS)
 down=int(unit.record.runtime.hp)<=0
 if down:
  if motion_tween!=null and motion_tween.is_running():return
  animation="down";age=0.0
 elif outcome=="hit" and change<0 and animation=="idle":animation="hit";age=0.0
func frame_index(layer: Dictionary) -> int:
 if layer.get("hold",false):return 0
 var timeline: Dictionary=recipe.timelines.get(animation,{"frames":[0],"fps":4})
 var t := idle_age if animation=="idle" else age
 var index := int(t*float(timeline.fps))
 index=index%timeline.frames.size() if timeline.get("loop",false) else mini(index,timeline.frames.size()-1)
 return mini(int(timeline.frames[index]),int(layer.get("columns",1))-1)
func _draw() -> void:
 if unit.is_empty():return
 var ink := GameUI.GOLD if active else GameUI.INK
 var faction := Color("a5d3ea") if unit.team=="party" else Color("f0b1a0")
 var compact := size.x<32
 var center := Vector2(size.x/2,size.y*(0.38 if compact else 0.50))+travel+impulse
 var width: float=(size.x-2 if compact else minf(size.x-5,size.y-11))*float(recipe.get("scale",1.0))
 width=minf(width,size.x-2)
 var origin := center-Vector2(width,width)/2
 draw_circle(center+Vector2(0,width*0.35),width*0.23,Color(0,0,0,0.45))
 if active:draw_arc(center+Vector2(0,width*0.30),width*0.25,0,PI,12,GameUI.GOLD,1)
 if not recipe.get("available",false):draw_string(ThemeDB.fallback_font,center,"?",HORIZONTAL_ALIGNMENT_LEFT,-1,18,GameUI.ERROR)
 else:
  var layers: Array=recipe.animations.get(animation,recipe.animations.idle)
  for layer in layers:
   var view := CombatArt.frame_view(layer,frame_index(layer),facing)
   var tex: Texture2D=view.texture
   if tex==null:continue
   var region: Rect2=view.region
   var offset: Vector2=view.offset
   var destination := Rect2(origin+offset*width/float(recipe.native),region.size*width/float(recipe.native))
   var proportions := Vector2(recipe.proportions[0],recipe.proportions[1])
   destination.position=center+(destination.position-center)*proportions;destination.size*=proportions
   var tint := Color(0.68,0.66,0.66,0.92) if down else Color.WHITE
   if flash>0:tint=Color(1.5,0.65,0.60)
   draw_texture_rect_region(tex,destination,region,tint)
 if animation in ["spell","guard"]:
  var color := Color("a3c9ec") if animation=="spell" else GameUI.GOLD
  draw_arc(center+Vector2(0,width*0.2),width*0.25,0,TAU,16,Color(color,0.6),1)
 var font := ThemeDB.fallback_font;var font_size := 8 if compact else 10 if size.x<50 else 12
 draw_string(font,Vector2(1 if compact else 3,font_size),badge,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)
 draw_string(font,Vector2(size.x-(8 if compact else 12),font_size),"◆" if unit.team=="party" else "×",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,faction)
 var bar_y := size.y-(3 if compact else 7);var bar_h := 2 if compact else 4
 draw_rect(Rect2(2,bar_y,size.x-4,bar_h),Color("100f0d"))
 draw_rect(Rect2(2,bar_y,(size.x-4)*clampf(display_hp/max_hp,0,1),bar_h),faction)
 if down and age>0.9:draw_string(font,Vector2(2,size.y-5 if compact else size.y-9),"↓" if compact else "DOWN",HORIZONTAL_ALIGNMENT_LEFT,-1,8 if compact else 9,GameUI.ERROR)
 if not feedback.is_empty():
  var color := GameUI.GOLD if feedback in ["MISS","BLOCKED","RESISTED"] else Color("c4e5a6") if feedback.begins_with("+") else Color("ffe3d5")
  draw_string(font,center+Vector2(-14,-15-feedback_age*15),feedback,HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
