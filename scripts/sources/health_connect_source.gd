extends ActivitySource
class_name HealthConnectSource
## Stub adapter for Android Health Connect.
##
## Integration surface (not yet implemented):
##   - Use Godot's native Android plugin / JNI to read Health Connect
##     ExerciseSessions and WorkoutRecords (AndroidX Health Connect).
##   - Convert distance/duration/calories and exercise types into
##     normalized records.
## Until then, fetch_activities() returns an empty list.

func display_name() -> String:
	return "Health Connect"

func source_id() -> String:
	return "health_connect"

func fetch_activities() -> Array:
	# TODO: implement Android Health Connect reads, then normalize.
	return []
