extends ActivitySource
class_name WatchSource
## Stub adapter for smartwatch / wearable data.
##
## Integration surface (not yet implemented):
##   - Read workouts and heart-rate / training-load summaries from the
##     vendor SDK (e.g. WatchKit HealthKit on watchOS, Wear OS on Android).
##   - For structured strength sessions, map movements to normalized
##     exercise names; otherwise derive a whole-body load estimate.
## Until then, fetch_activities() returns an empty list.

func display_name() -> String:
	return "Smartwatch"

func source_id() -> String:
	return "watch"

func fetch_activities() -> Array:
	# TODO: implement wearable SDK reads, then normalize.
	return []
