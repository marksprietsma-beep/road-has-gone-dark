class_name RouteTimeScenario
extends RefCounted

const PRESETS := [0, 15, 30, 60]

static func format_moving_time(minutes: int) -> String:
	var hours: int = minutes / 60
	var remainder: int = minutes % 60
	if hours > 0:
		return "%dh %dm" % [hours, remainder] if remainder else "%dh" % hours
	return "%dm" % remainder

static func estimate(route: Dictionary, minutes_per_effort: int = 0) -> Dictionary:
	assert(PRESETS.has(minutes_per_effort))
	var result := {"meaning": "PROVISIONAL_MOVING_TIME_SCENARIO", "minutes_per_effort": minutes_per_effort, "physical_km": "UNCALIBRATED", "total_journey_minutes": null, "moving_minutes": null}
	if minutes_per_effort == 0:
		result.status = "UNSET"
	elif str(route.get("status", "")) != "PREVIEW_ROUTE":
		result.status = "NO_ROUTE"
	elif int(route.get("route_steps", 0)) == 0:
		result.status = "WITHIN_HEX_TIME_UNKNOWN"
	else:
		var effort: float = float(route.get("effort", -1))
		assert(is_finite(effort) and effort > 0)
		var raw: float = effort * minutes_per_effort
		var minutes: int = int(ceil(raw / 5.0)) * 5
		result.merge({"status": "SCENARIO_ONLY", "raw_moving_minutes": raw, "moving_minutes": minutes, "display": "~" + format_moving_time(minutes), "crossing_delay": "UNKNOWN" if not route.get("river_crossings", []).is_empty() else "NOT_ASSESSED", "rests": "NOT_INCLUDED"}, true)
	return result
