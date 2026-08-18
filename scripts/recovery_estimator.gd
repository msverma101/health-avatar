extends RefCounted
class_name RecoveryEstimator
## Estimates a per-muscle-group activity state from mapped load data.
##
## The estimator is a deliberately simple model so it can be improved
## later without changing the app: each group's state depends only on
## (a) how recently the group was used and (b) the accumulated load.
##
## States:
##   "high"   -> group used very recently with heavy load
##   "recent" -> group used within the recent window
##   "none"   -> no recent activity for this group

const DAY := 86400
const RECENT_WINDOW_DAYS := 7.0
const HIGH_LOAD_THRESHOLD := 1.4
const HIGH_WINDOW_DAYS := 3.0

## Compute state for one group id from the mapper's aggregated load.
func state_for_group(group_id: String, group_load: Dictionary, now_unix := 0) -> String:
	if now_unix == 0:
		now_unix = int(Time.get_unix_time_from_system())
	if not group_load.has(group_id):
		return "none"
	var entry: Dictionary = group_load[group_id]
	var last: int = int(entry.get("last_date_unix", 0))
	var load: float = float(entry.get("load", 0.0))
	if last <= 0:
		return "none"
	var days_ago: float = (now_unix - last) / DAY
	if days_ago > RECENT_WINDOW_DAYS:
		return "none"
	if load >= HIGH_LOAD_THRESHOLD and days_ago <= HIGH_WINDOW_DAYS:
		return "high"
	return "recent"

## Human readable label for a state value.
func label_for_state(state: String) -> String:
	match state:
		"high":
			return "High estimated load"
		"recent":
			return "Recently involved"
		_:
			return "No recent activity"

## Color hint per state (mirrors the legend in the UI).
func color_for_state(state: String) -> Color:
	match state:
		"high":
			return Color("#ef6a6a")
		"recent":
			return Color("#f3a65b")
		_:
			return Color("#66c98b")
