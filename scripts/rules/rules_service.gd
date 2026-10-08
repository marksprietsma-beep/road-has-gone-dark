class_name RulesService
extends PartyService
## Deliberate mechanics commits reuse the existing lock, journal and world guard.
func commit_preview(entry: Dictionary,slot: String,preview: Dictionary) -> Dictionary:
 if not preview.get("ok",false) or not preview.get("operation") in ["prepare","advance"] or not preview.get("before_hash") is String or not preview.get("candidate_hash") is String: return fail("A valid reviewable rules preview is required")
 return operate(entry,slot,"prepare_rules" if preview.operation=="prepare" else "advance_rules",1,preview)

func _operate_locked(entry: Dictionary,slot: String,operation: String,member: int,changes: Dictionary) -> Dictionary:
 if not operation in ["prepare_rules","advance_rules"]: return super._operate_locked(entry,slot,operation,member,changes)
 var loaded := recover(slot,entry.world)
 if not loaded.ok: return loaded
 if RulesJson.digest(loaded.state)!=changes.get("before_hash"): return fail("rules.stale: Campaign changed after the preview; existing bytes were preserved")
 var preview := RulesRecords.preview_preparation(loaded.state) if operation=="prepare_rules" else RulesRecords.preview_advancement(loaded.state,str(changes.get("character_id")),changes.get("choice",{}))
 if not preview.ok: return preview
 if preview.candidate_hash!=changes.get("candidate_hash"): return fail("rules.preview_changed: Preview does not match the reconstructed rules transaction")
 if preview.get("already_prepared",false): return {"ok":true,"state":loaded.state,"unchanged":true}
 return commit(slot,preview.candidate,entry.world)
