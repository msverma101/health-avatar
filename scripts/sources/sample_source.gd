extends ActivitySource
class_name SampleActivitySource
## Reads the bundled sample_activities.json so the app can run with
## realistic data before any real integration is wired up.

const SAMPLE_PATH := "res://data/sample_activities.json"

func display_name() -> String:
	return "Sample data"

func source_id() -> String:
	return "sample"

func fetch_activities() -> Array:
	var file := FileAccess.open(SAMPLE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Sample activity file not found: " + SAMPLE_PATH)
		return []
	var raw: Variant = JSON.parse_string(file.get_as_text())
	if raw is not Array:
		push_warning("sample_activities.json does not contain an array")
		return []
	var out: Array = []
	for record in raw:
		if record is Dictionary:
			out.append(_normalize(record))
	return out
