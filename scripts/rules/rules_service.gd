class_name RulesService
extends PartyService
## Deliberate mechanics commits reuse the existing lock, journal and world guard.
func commit_preview(entry: Dictionary,slot: String,preview: Dictionary) -> Dictionary:
 if not preview.get("ok",false) or not preview.get("operation") in ["prepare","advance","runtime"] or not preview.get("before_hash") is String or not preview.get("candidate_hash") is String: return fail("A valid reviewable rules preview is required")
 if preview.operation=="advance" and not preview.get("choice") is Dictionary: return fail("rules.choice: Advancement requires a structured choice")
 if preview.operation=="runtime" and not preview.get("runtime") is Dictionary: return fail("rules.runtime: Current mechanics must be a dictionary")
 return operate(entry,slot,{"prepare":"prepare_rules","advance":"advance_rules","runtime":"runtime_rules"}[preview.operation],1,preview)

func _operate_locked(entry: Dictionary,slot: String,operation: String,member: int,changes: Dictionary) -> Dictionary:
 if not operation in ["prepare_rules","advance_rules","runtime_rules"]: return super._operate_locked(entry,slot,operation,member,changes)
 if operation=="advance_rules" and not changes.get("choice") is Dictionary: return fail("rules.choice: Invalid advancement payload")
 if operation=="runtime_rules" and not changes.get("runtime") is Dictionary: return fail("rules.runtime: Invalid current-mechanics payload")
 var loaded := recover(slot,entry.world)
 if not loaded.ok: return loaded
 if RulesJson.digest(loaded.state)!=changes.get("before_hash"): return fail("rules.stale: Campaign changed after the preview; existing bytes were preserved")
 var preview := {}
 if operation=="prepare_rules": preview=RulesRecords.preview_preparation(loaded.state)
 elif operation=="advance_rules": preview=RulesRecords.preview_advancement(loaded.state,str(changes.get("character_id")),changes.get("choice",{}))
 if operation=="runtime_rules": preview=RulesRecords.preview_runtime(loaded.state,str(changes.get("character_id")),changes.get("runtime",{}))
 if not preview.ok: return preview
 if preview.candidate_hash!=changes.get("candidate_hash"): return fail("rules.preview_changed: Preview does not match the reconstructed rules transaction")
 if preview.get("already_prepared",false): return {"ok":true,"state":loaded.state,"unchanged":true}
 return commit(slot,preview.candidate,entry.world)
