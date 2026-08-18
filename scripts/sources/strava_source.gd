extends ActivitySource
class_name StravaSource
## Stub adapter for the Strava API.
##
## Integration surface (not yet implemented):
##   - OAuth2 token via Strava API (https://www.strava.com/api/v3/...)
##   - Fetch recent activities (runs, rides, strength training)
##   - For strength workouts, decode "exercises" from the raw upload;
##     for cardio, map sport type to an overall activity profile.
## Until then, fetch_activities() returns an empty list.

func display_name() -> String:
	return "Strava"

func source_id() -> String:
	return "strava"

func fetch_activities() -> Array:
	# TODO: implement OAuth + activity polling, then normalize each record.
	return []
