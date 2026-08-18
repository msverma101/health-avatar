extends RefCounted
class_name ActivitySource
## Adapter interface for activity data sources.
##
## Every data source (Hevy, Strava, Apple Health / Health Connect,
## smartwatch, or a local sample file) is represented by a subclass that
## returns a normalized list of activity records.
##
## Normalized record shape (a Dictionary):
##   {
##     "date":            "2026-08-05",   # ISO date string
##     "start_time_unix": 1786380000,     # optional, for sub-day precision
##     "exercise":        "Bench press",  # normalized exercise name
##     "duration_minutes": 35,            # seconds converted to minutes
##     "intensity":        0.9,           # 0.0 - 1.0 relative effort
##     "source":          "hevy"          # id of the producing adapter
##   }

const NORMALIZED_FIELDS := ["date", "exercise", "duration_minutes", "intensity"]

## Human readable name of the source, e.g. "Hevy".
func display_name() -> String:
	return "Unknown"

## Stable identifier of the source, e.g. "hevy".
func source_id() -> String:
	return "unknown"

## Fetch and return normalized activity records.
## Implementations should call _normalize() on each raw record so the
## app never depends on source-specific shapes.
func fetch_activities() -> Array:
	return []

## Translate a raw record into the normalized shape. Keeps only known
## fields and coerces types, so a single app-side mapper can consume
## data from any source.
func _normalize(record: Dictionary) -> Dictionary:
	var out := {}
	for key in NORMALIZED_FIELDS:
		if record.has(key):
			out[key] = record[key]
	if not out.has("intensity"):
		out["intensity"] = 0.5
	if not out.has("duration_minutes"):
		out["duration_minutes"] = 0
	out["source"] = source_id()
	return out
