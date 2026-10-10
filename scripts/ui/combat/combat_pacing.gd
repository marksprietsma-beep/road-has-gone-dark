class_name CombatPacing
extends RefCounted
## Wall-clock presentation only. These values never enter battle saves or dice.
const TILE_SECONDS := 0.30
const PROJECTILE_SECONDS := 0.55
const RECOVERY_SECONDS := 0.15
const REACTION_SECONDS := 0.42
const POST_BEAT_SECONDS := 0.22
const AI_PAUSE_SECONDS := 0.32
const HP_SETTLE_SECONDS := 2.8
const FEEDBACK_SECONDS := 1.35
const FLASH_SECONDS := 0.27
const HP_TWEEN_SECONDS := 0.25
const MAX_BEAT_SECONDS := 3.2
const FPS := {"move":8.0,"slash":7.5,"shoot":12.0,"thrust":8.5,"spell":7.0,"hit":7.0,"down":6.5}
const IMPACT := {"slash":0.44,"shoot":0.76,"thrust":0.48,"spell":0.60}
static func timelines(source: Dictionary) -> Dictionary:
 var result: Dictionary=source.duplicate(true)
 for clip in FPS:
  if result.has(clip):result[clip].fps=FPS[clip]
 for clip in IMPACT:
  if result.has(clip):result[clip].impact=IMPACT[clip]
 return result
static func clip_seconds(timelines: Dictionary,clip: String) -> float:
 var value: Dictionary=timelines.get(clip,{"frames":[0],"fps":4})
 return float(value.frames.size())/float(value.fps)+RECOVERY_SECONDS
