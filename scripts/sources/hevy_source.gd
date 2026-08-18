extends ActivitySource
class_name HevySource
## Stub adapter for the Hevy workout-tracker API.
##
## Integration surface (not yet implemented):
##   - OAuth2 token via Hevy API (https://api.hevy.com/v1/...)
##   - Fetch recent workout sets with exercise names
##   - Map Hevy exercise names onto the app's normalized names via
##     the exercise lookup table in the activity mapper.
## Until then, fetch_activities() returns an empty list.

func display_name() -> String:
	return "Hevy"

func source_id() -> String:
	return "hevy"

func fetch_activities() -> Array:
	# TODO: implement OAuth + API polling, then normalize each record.
	return []
