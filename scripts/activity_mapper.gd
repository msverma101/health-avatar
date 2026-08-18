extends RefCounted
class_name ActivityMapper
## Turns normalized activity records into per-muscle-group load data.
##
## Pipeline (matches the data-flow diagram in the project brief):
##   External source -> source adapter -> normalized records
##     -> exercise mapping -> per-group load -> recovery estimator
##
## The mapper is source-agnostic: it consumes the normalized records
## produced by any ActivitySource subclass, so no app code depends on
## Hevy, Strava, Health Connect or any single provider.

const EXERCISE_TABLE_PATH := "res://data/exercise_muscles.json"

var exercise_table: Dictionary = {}
var source: ActivitySource

## Aggregated load per muscle group id:
##   { "<group_id>": { "load": float, "last_date_unix": int, "count": int } }
var group_load: Dictionary = {}

func _init(source_ref: ActivitySource = null) -> void:
	source = source_ref
	_load_exercise_table()

func set_source(source_ref: ActivitySource) -> void:
	source = source_ref

func _load_exercise_table() -> void:
	var file := FileAccess.open(EXERCISE_TABLE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Exercise table not found: " + EXERCISE_TABLE_PATH)
		return
	var raw: Variant = JSON.parse_string(file.get_as_text())
	if raw is Dictionary:
		exercise_table = raw

func _date_to_unix(iso_date: String) -> int:
	var parts := iso_date.split("-")
	if parts.size() != 3:
		return 0
	return Time.get_unix_time_from_datetime_dict({
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
	})

func fetch_group_load() -> Dictionary:
	group_load.clear()
	if source == null:
		push_warning("No activity source configured in ActivityMapper")
		return group_load
	for record in source.fetch_activities():
		if record is Dictionary:
			_apply_record(record)
	return group_load

## Add one normalized record to the aggregated per-group load.
## A record's exercise is matched to a row in the exercise table; the
## row's weighted group targets are folded into group_load, weighted by
## intensity and duration.
func _apply_record(record: Dictionary) -> void:
	var exercise: String = String(record.get("exercise", ""))
	var mapping := _match_exercise(exercise)
	if mapping.is_empty():
		return
	var intensity: float = float(record.get("intensity", 0.5))
	var duration: float = float(record.get("duration_minutes", 0))
	var date_unix := int(record.get("start_time_unix", _date_to_unix(String(record.get("date", "")))))
	var groups: Array = mapping.get("groups", [])
	var weights: Array = mapping.get("weights", [])
	for i in groups.size():
		var group_id: String = groups[i]
		var weight: float = float(weights[i]) if i < weights.size() else 0.5
		if not group_load.has(group_id):
			group_load[group_id] = {"load": 0.0, "last_date_unix": 0, "count": 0}
		var entry: Dictionary = group_load[group_id]
		entry["load"] += intensity * weight * (0.5 + duration / 60.0)
		entry["count"] += 1
		if date_unix > int(entry["last_date_unix"]):
			entry["last_date_unix"] = date_unix

## Match an exercise name to a table row using case-insensitive
## substring matching, falling back to any contained keyword.
func _match_exercise(exercise: String) -> Dictionary:
	var needle := exercise.to_lower()
	for name in exercise_table:
		if needle == String(name).to_lower():
			return exercise_table[name]
	for name in exercise_table:
		if String(name).to_lower() in needle or needle in String(name).to_lower():
			return exercise_table[name]
	return {}
