extends Node3D

const DATA_PATH := "res://data/muscles.json"
const EXERCISES_PATH := "res://data/exercises.json"
const ANATOMY_PATH := "res://assets/models/body_rigged.glb"
const CREDITS := "Anatomy model: Z-Anatomy, github.com/Z-Anatomy (CC BY-SA 4.0)"
const BG := Color("#090d18")
const PANEL := Color("#111a2b")
const TEXT := Color("#e8edf7")
const MUTED := Color("#91a0b8")
const MUSCLE := Color("#c87656")
const BONE := Color("#e9e2cc")
const HIGHLIGHT := Color("#ef3333")
const GREY := Color("#5a5a5a")
const ZOOM_MIN := 1.0
const ZOOM_MAX := 8.0
const HIDE_KEYWORDS := ["bursa", "sheath", "tendon", "ligament", "artery", "arterial", "vein", "venous",
	"nerve", "ganglion", "plexus", "gland", "lymph", "organ", "intestine", "stomach", "liver", "kidney",
	"heart", "lung", "bronch", "oesophagus", "esophagus", "aorta", "vessel", "apponeurosis", "fascia",
	"retinaculum", "plica", "mesentery", "peritoneum", "pleura", "pericard", "duodenum", "pancreas",
	"spleen", "ureter", "bladder", "rectum", "colon", "cecum", "appendix", "trachea", "larynx", "pharynx",
	"thyroid", "parotid", "submandibular", "sublingual", "tongue", "bulb", "duct", "sac", "capsule",
	"membrane", "adipose", "aponeurosis", "tendinous", "linea alba"]
const BONE_KEYWORDS := ["bone", "skeleton", "skull", "cranium", "vertebra", "coccyx", "sacrum", "sternum",
	"rib", "clavicle", "scapula", "humerus", "radius", "ulna", "femur", "tibia", "fibula", "patella",
	"pelvis", "metacarpal", "metatarsal", "phalanx", "calcaneus", "talus", "mandible", "maxilla",
	"zygomatic", "nasal", "lacrimal", "vomer", "ethmoid", "sphenoid", "temporal", "parietal", "frontal",
	"occipital", "hyoid", "atlas", "axis", "meniscus", "cartilage", "incus", "malleus", "stapes",
	"sesamoid", "incisor", "canine", "premolar", "molar", "tooth", "teeth", "xiphoid", "enamel",
	"dentin", "tarsus"]
const MUSCLE_KEYWORDS := ["muscle", "pector", "deltoid", "trapezius", "latissimus", "glute", "biceps",
	"triceps", "quadratus", "femoris", "vastus", "sartorius", "gastrocnemius", "soleus", "adductor",
	"abductor", "extensor", "flexor", "levator", "depressor", "sphincter", "orbicularis", "zygomatic",
	"buccinator", "bucinator", "platysma", "sternocleidomast", "temporalis", "masseter", "pterygoid",
	"scalene", "serratus", "rhomboid", "subscapular", "supraspinat", "infraspinat", "teres",
	"coracobrach", "brachialis", "brachioradial", "supinator", "pronator", "palmaris", "iliacus", "psoas",
	"obturator", "piriformis", "gracilis", "tensor", "erector", "iliocostal", "longissimus", "multifidus",
	"semispinalis", "splenius", "digastric", "mylohyoid", "geniohyoid", "stylohyoid", "omohyoid",
	"sternohyoid", "thyrohyoid", "transversus", "rectus abdominis", "oblique", "cremaster", "peroneus",
	"fibularis", "tibialis", "popliteus", "corrugator", "constrictor", "rotatores", "diaphragm",
	"semitendinosus", "semimembranosus", "plantaris", "hamstring"]

var muscles: Array = []
var exercises_by_group: Dictionary = {}
var detail_exercise_list: VBoxContainer
var selected := 0
var selected_muscle := -1
var activity_mapper: ActivityMapper
var recovery_estimator: RecoveryEstimator
var activity_states: Dictionary = {}
var activity_sources: Array[ActivitySource] = []
var avatar: Node3D
var body_node: Node3D
var skeleton: Skeleton3D
var camera_pivot: Node3D
var focus_target := Vector3(0, 1.0, 0)
var focus_zoom := 4.5
var focus_yaw := 0.0
var focus_pitch := 0.05
var focus_smoothing := 6.0
var dragging := false
var last_mouse := Vector2.ZERO
var click_start := Vector2.ZERO
var click_moved := false
var yaw := 0.0
var pitch := 0.05
var zoom := 4.5
var pinch_start_dist := 0.0
var pinch_start_zoom := 4.5
var pinch_active := false
var touches: Dictionary = {}
var muscle_meshes: Array[MeshInstance3D] = []
var bone_meshes: Array[MeshInstance3D] = []
var group_meshes: Array[Array] = []
var detail_title: Label
var detail_summary: Label
var state_badge: Label
var selection_buttons: Array[Button] = []
var sub_header: Label
var sub_list: BoxContainer
var sub_buttons: Array[Button] = []
var ui_layer: CanvasLayer
var ui_root: Control
var ui_portrait := false
var portrait_panel_open := true
var portrait_shift := 0.0

func _ready() -> void:
	_load_data()
	_setup_activity_pipeline()
	_build_world()
	_build_interface()
	_refresh_activity_states()
	# Open on the full-avatar default view rather than auto-zooming into the
	# first muscle group, so the app starts framed on the whole body.
	_reset_view()

func _setup_activity_pipeline() -> void:
	activity_sources = [
		SampleActivitySource.new(),
		HevySource.new(),
		StravaSource.new(),
		HealthConnectSource.new(),
		WatchSource.new(),
	]
	activity_mapper = ActivityMapper.new()
	recovery_estimator = RecoveryEstimator.new()
	activity_mapper.set_source(activity_sources[0])

func _refresh_activity_states() -> void:
	if activity_mapper == null:
		return
	var group_load := activity_mapper.fetch_group_load()
	activity_states.clear()
	for g in muscles.size():
		var group_id: String = muscles[g].id
		var state := recovery_estimator.state_for_group(group_id, group_load)
		activity_states[group_id] = state
		muscles[g]["activity"] = state
		if muscles[g].has("muscles"):
			for sub in muscles[g].muscles:
				sub["activity"] = state
	_tint_buttons()
	_tint_muscles()
	_reset_view()

func _tint_buttons() -> void:
	for i in selection_buttons.size():
		var state: String = muscles[i].activity
		selection_buttons[i].add_theme_color_override("font_color", recovery_estimator.color_for_state(state))

func _load_data() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file:
		muscles = JSON.parse_string(file.get_as_text())
	_load_exercises_map()

func _load_exercises_map() -> void:
	var ex_file := FileAccess.open(EXERCISES_PATH, FileAccess.READ)
	if ex_file == null:
		push_warning("Exercises map not found: " + EXERCISES_PATH)
		return
	var data = JSON.parse_string(ex_file.get_as_text())
	if not data is Dictionary or not data.has("exercises"):
		return
	for entry: Dictionary in data["exercises"]:
		var g: String = entry.get("primary", "")
		if g == "":
			continue
		if not exercises_by_group.has(g):
			exercises_by_group[g] = []
		exercises_by_group[g].append({
			"name": entry["name"],
			"url": entry.get("url", ""),
			"sub_muscles": entry.get("sub_muscles", []),
		})

func _exercises_for_group(group_id: String) -> Array:
	if not exercises_by_group.has(group_id):
		return []
	return exercises_by_group[group_id]

func _populate_exercises(list: Array) -> void:
	if detail_exercise_list == null:
		return
	for c in detail_exercise_list.get_children():
		detail_exercise_list.remove_child(c)
		c.queue_free()
	if list.is_empty():
		var empty := _label("No exercises mapped.", 16, MUTED)
		detail_exercise_list.add_child(empty)
		return
	for entry: Dictionary in list:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_lbl := _label("• " + entry["name"], 17)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		top.add_child(name_lbl)
		var url: String = entry.get("url", "")
		if url != "":
			var watch := Button.new()
			watch.text = "▶"
			watch.custom_minimum_size = Vector2(36, 30)
			watch.add_theme_font_size_override("font_size", 17)
			watch.pressed.connect(_open_video.bind(url))
			top.add_child(watch)
		row.add_child(top)
		var subs: Array = entry.get("sub_muscles", [])
		if not subs.is_empty():
			var sub_lbl := _label("   " + ", ".join(subs), 14, MUTED)
			sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(sub_lbl)
		detail_exercise_list.add_child(row)

func _open_video(url: String) -> void:
	OS.shell_open(url)

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8fa9d0")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	var key := OmniLight3D.new()
	key.position = Vector3(3, 4, 4)
	key.light_color = Color("#d9e8ff")
	key.light_energy = 5.0
	key.omni_range = 12.0
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-4, 2, 1)
	fill.light_color = Color("#8cb8ff")
	fill.light_energy = 3.0
	fill.omni_range = 10.0
	add_child(fill)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.0, 0)
	add_child(camera_pivot)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0.2, zoom)
	camera.current = true
	camera.fov = 38.0
	camera_pivot.add_child(camera)

	avatar = Node3D.new()
	avatar.position = Vector3(0, 0.14, 0)
	add_child(avatar)
	_load_anatomy()

func _material(color: Color, roughness := 0.65) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func _highlight_material(color: Color) -> StandardMaterial3D:
	var mat := _material(color)
	mat.emission_enabled = true
	mat.emission = color.lightened(0.25)
	mat.emission_energy_multiplier = 0.8
	return mat

func _transparent_material(color: Color, alpha: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.5
	return mat

func _load_anatomy() -> void:
	var scene := load(ANATOMY_PATH) as PackedScene
	if scene == null:
		printerr("Failed to load anatomy model: ", ANATOMY_PATH)
		return
	for g in muscles.size():
		group_meshes.append([])
	var body: Node3D = scene.instantiate()
	body_node = body
	avatar.add_child(body)
	var stack: Array[Node] = [body]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is Skeleton3D:
			skeleton = n as Skeleton3D
		if n is MeshInstance3D:
			_classify_mesh(n as MeshInstance3D)
		for c in n.get_children():
			stack.append(c)
	_tint_muscles()

func _classify_mesh(mesh: MeshInstance3D) -> void:
	var name_lower: String = mesh.name.to_lower()
	for kw in HIDE_KEYWORDS:
		if kw in name_lower:
			mesh.visible = false
			return
	for kw in MUSCLE_KEYWORDS:
		if kw in name_lower:
			mesh.material_override = _material(MUSCLE)
			muscle_meshes.append(mesh)
			for g in muscles.size():
				for kw2: String in muscles[g].keywords:
					if kw2 in name_lower:
						group_meshes[g].append(mesh)
						_add_pickable(mesh, g)
						break
			return
	for kw in BONE_KEYWORDS:
		if kw in name_lower:
			mesh.material_override = _material(BONE)
			bone_meshes.append(mesh)
			return
	mesh.visible = false

func _add_pickable(mesh: MeshInstance3D, group_index: int) -> void:
	var body := StaticBody3D.new()
	body.set_meta("muscle_index", group_index)
	body.set_meta("hit_mesh_name", mesh.name)
	avatar.add_child(body)
	var shape := CollisionShape3D.new()
	var tri := ConcavePolygonShape3D.new()
	tri.set_faces(mesh.mesh.get_faces())
	shape.shape = tri
	body.add_child(shape)

func _label(text_value: String, size: int, color := TEXT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _build_interface() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui_root)
	_build_layout()

func _process(delta: float) -> void:
	var t: float = clamp(focus_smoothing * delta, 0.0, 1.0)
	if not camera_pivot.position.is_equal_approx(focus_target):
		camera_pivot.position = camera_pivot.position.lerp(focus_target, t)
	if not is_equal_approx(zoom, focus_zoom):
		zoom = lerp(zoom, focus_zoom, t)
		var camera := camera_pivot.get_child(0) as Camera3D
		camera.position.z = zoom
	var d_yaw: float = _wrap_angle(focus_yaw - yaw)
	yaw += d_yaw * t
	pitch = lerp(pitch, focus_pitch, t)
	_update_camera()
	# Rebuild layout when the window crosses the portrait/landscape boundary.
	var vs := get_viewport().get_visible_rect().size
	var portrait := vs.y > vs.x
	if portrait != ui_portrait:
		ui_portrait = portrait
		_build_layout()

func _clear_ui() -> void:
	for c in ui_root.get_children():
		ui_root.remove_child(c)
		c.queue_free()
	selection_buttons.clear()
	sub_buttons.clear()
	detail_exercise_list = null
	detail_title = null
	detail_summary = null
	state_badge = null
	sub_header = null
	sub_list = null

func _build_layout() -> void:
	_clear_ui()
	var vs := get_viewport().get_visible_rect().size
	if ui_portrait:
		_build_portrait_ui(vs)
	else:
		portrait_shift = 0.0
		_build_landscape_ui(vs)
	# Refresh current selection so the detail panel is populated.
	if selected >= 0 and selected < muscles.size():
		_select_muscle(selected)
	elif detail_title:
		detail_title.text = "Health Avatar"

func _build_landscape_ui(vs: Vector2) -> void:
	var heading := _label("HEALTH AVATAR", 26)
	heading.position = Vector2(32, 24)
	ui_root.add_child(heading)
	var subtitle := _label("Interactive anatomy  •  tap a muscle", 14, MUTED)
	subtitle.position = Vector2(34, 59)
	ui_root.add_child(subtitle)

	var left := PanelContainer.new()
	left.position = Vector2(28, 96)
	left.size = Vector2(220, min(470, vs.y - 130))
	left.add_theme_stylebox_override("panel", _box(PANEL, 14))
	ui_root.add_child(left)
	var scroll := ScrollContainer.new()
	left.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.add_theme_constant_override("margin_left", 18)
	list.add_theme_constant_override("margin_top", 16)
	list.add_theme_constant_override("margin_right", 10)
	list.add_theme_constant_override("margin_bottom", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	list.add_child(_label("MUSCLE GROUPS", 12, MUTED))
	for i in muscles.size():
		var button := Button.new()
		button.text = muscles[i].name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(180, 40)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_select_muscle.bind(i))
		list.add_child(button)
		selection_buttons.append(button)
	sub_header = _label("", 12, MUTED)
	list.add_child(sub_header)
	sub_list = VBoxContainer.new()
	sub_list.add_theme_constant_override("separation", 6)
	list.add_child(sub_list)

	var right := PanelContainer.new()
	right.position = Vector2(vs.x - 380, 96)
	right.size = Vector2(352, min(470, vs.y - 130))
	right.add_theme_stylebox_override("panel", _box(PANEL, 14))
	ui_root.add_child(right)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.add_theme_constant_override("margin_left", 20)
	content.add_theme_constant_override("margin_top", 18)
	content.add_theme_constant_override("margin_right", 12)
	content.add_theme_constant_override("margin_bottom", 12)
	right.add_child(content)
	detail_title = _label("", 26)
	content.add_child(detail_title)
	state_badge = _label("", 13)
	content.add_child(state_badge)
	content.add_child(HSeparator.new())
	detail_summary = _label("", 15)
	detail_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_summary.custom_minimum_size.y = 60
	content.add_child(detail_summary)
	content.add_child(_label("JEFF NIPPARD EXERCISES", 12, MUTED))
	var ex_scroll := ScrollContainer.new()
	ex_scroll.custom_minimum_size.y = 150
	ex_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(ex_scroll)
	detail_exercise_list = VBoxContainer.new()
	detail_exercise_list.add_theme_constant_override("separation", 4)
	detail_exercise_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ex_scroll.add_child(detail_exercise_list)

	var hint := _label("Tap a muscle  •  Drag to orbit  •  Wheel/pinch to zoom  •  R to reset", 13, MUTED)
	hint.position = Vector2(380, vs.y - 52)
	ui_root.add_child(hint)
	var credits := _label(CREDITS, 11, MUTED)
	credits.position = Vector2(28, vs.y - 26)
	credits.add_theme_color_override("font_color", Color("#5f6b80"))
	ui_root.add_child(credits)

func _build_portrait_ui(vs: Vector2) -> void:
	# Compact header so the avatar gets most of the screen.
	var heading := _label("HEALTH AVATAR", 20)
	heading.position = Vector2(14, 8)
	ui_root.add_child(heading)
	var credits := _label(CREDITS, 12, MUTED)
	credits.position = Vector2(14, 32)
	credits.add_theme_color_override("font_color", Color("#5f6b80"))
	ui_root.add_child(credits)

	var panel_h: float
	if portrait_panel_open:
		panel_h = clamp(vs.y * 0.46, 320.0, 420.0)
	else:
		# Collapsed: just a slim handle + the muscle group chip row.
		panel_h = 64.0
	var panel_y: float = vs.y - panel_h
	var panel := PanelContainer.new()
	panel.position = Vector2(0, panel_y)
	panel.size = Vector2(vs.x, panel_h)
	panel.add_theme_stylebox_override("panel", _box(PANEL, 18))
	ui_root.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.add_theme_constant_override("margin_left", 12)
	col.add_theme_constant_override("margin_top", 6)
	col.add_theme_constant_override("margin_right", 12)
	col.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(col)

	# Handle row: grabber + collapse toggle.
	var handle := HBoxContainer.new()
	handle.add_theme_constant_override("separation", 8)
	col.add_child(handle)
	var handle_lbl := _label("", 16)
	handle_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	handle.add_child(handle_lbl)
	var toggle := Button.new()
	toggle.text = "⌄" if portrait_panel_open else "⌃"
	toggle.custom_minimum_size = Vector2(52, 30)
	toggle.add_theme_font_size_override("font_size", 20)
	toggle.pressed.connect(_toggle_portrait_panel)
	handle.add_child(toggle)

	# Muscle group chips (horizontal scroll).
	var sel_scroll := ScrollContainer.new()
	sel_scroll.custom_minimum_size.y = 46
	sel_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sel_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sel_scroll)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	sel_scroll.add_child(hbox)
	for i in muscles.size():
		var button := Button.new()
		button.text = muscles[i].name
		button.custom_minimum_size = Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(_select_muscle.bind(i))
		hbox.add_child(button)
		selection_buttons.append(button)

	if portrait_panel_open:
		# Sub-muscle chips (horizontal scroll).
		var sub_scroll := ScrollContainer.new()
		sub_scroll.custom_minimum_size.y = 40
		sub_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		sub_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		col.add_child(sub_scroll)
		sub_list = HBoxContainer.new()
		sub_list.add_theme_constant_override("separation", 6)
		sub_scroll.add_child(sub_list)

		# Title + activity state on one row.
		var title_row := HBoxContainer.new()
		title_row.add_theme_constant_override("separation", 8)
		col.add_child(title_row)
		detail_title = _label("", 24)
		detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_row.add_child(detail_title)
		state_badge = _label("", 14)
		title_row.add_child(state_badge)

		detail_summary = _label("", 16)
		detail_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_summary.custom_minimum_size.y = 32
		col.add_child(detail_summary)

		var ex_label := _label("EXERCISES", 14, MUTED)
		col.add_child(ex_label)

		# Exercise list in a scrollable area (rest of the sheet).
		var ex_scroll := ScrollContainer.new()
		ex_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ex_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		col.add_child(ex_scroll)
		detail_exercise_list = VBoxContainer.new()
		detail_exercise_list.add_theme_constant_override("separation", 3)
		detail_exercise_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ex_scroll.add_child(detail_exercise_list)

	var hint := _label("Tap a muscle  •  Drag to orbit  •  Pinch to zoom", 14, MUTED)
	hint.position = Vector2(14, panel_y - 26)
	ui_root.add_child(hint)

	# Frame the avatar in the visible area above the panel so it is never hidden.
	# The camera-pivot Y bias (applied in the focus/reset logic) lifts the avatar.
	portrait_shift = panel_h * 0.5

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box

func _toggle_portrait_panel() -> void:
	portrait_panel_open = not portrait_panel_open
	_build_layout()

# In portrait the bottom sheet covers part of the screen. To keep the selected
# muscle visible above it, aim the camera at a point below the muscle so the
# muscle renders higher on screen. bias_y is in world units and depends on how
# many world units cover the panel height on screen.
func _frame_target(base: Vector3, zoom_dist: float) -> Vector3:
	if not ui_portrait or portrait_shift <= 0.0:
		return base
	var vs := get_viewport().get_visible_rect().size
	var fov: float = 38.0
	var world_span_y: float = 2.0 * zoom_dist * tan(deg_to_rad(fov) * 0.5)
	var world_per_pixel: float = world_span_y / max(vs.y, 1.0)
	var bias_y: float = portrait_shift * world_per_pixel
	return Vector3(base.x, base.y - bias_y, base.z)

func _select_muscle(index: int) -> void:
	selected = index
	selected_muscle = -1
	_rebuild_sub_list()
	if muscles.is_empty() or index < 0 or index >= muscles.size():
		return
	var muscle: Dictionary = muscles[index]
	if detail_title:
		detail_title.text = muscle.name
	if detail_summary:
		detail_summary.text = muscle.summary
	_populate_exercises(_exercises_for_group(muscle.id))
	var state: String = muscle.activity
	var state_color := Color("#66c98b") if state == "none" else Color("#f3a65b") if state == "recent" else Color("#ef6a6a")
	if state_badge:
		state_badge.text = "●  " + ("No recent activity" if state == "none" else "Recently involved" if state == "recent" else "High estimated load")
		state_badge.add_theme_color_override("font_color", state_color)
	_tint_muscles()
	_focus_on_group(index)

func _select_sub_muscle(group_index: int, sub_index: int) -> void:
	if group_index != selected:
		selected = group_index
		_rebuild_sub_list()
	selected_muscle = sub_index
	var muscle: Dictionary = muscles[selected].muscles[sub_index]
	if detail_title:
		detail_title.text = muscle.name
	if detail_summary:
		detail_summary.text = muscle.summary
	_populate_exercises(_exercises_for_group(muscles[selected].id))
	var state: String = muscle.activity
	var state_color := Color("#66c98b") if state == "none" else Color("#f3a65b") if state == "recent" else Color("#ef6a6a")
	if state_badge:
		state_badge.text = "●  " + ("No recent activity" if state == "none" else "Recently involved" if state == "recent" else "High estimated load")
		state_badge.add_theme_color_override("font_color", state_color)
	_tint_muscles()
	_focus_on_group(selected, sub_index)

func _rebuild_sub_list() -> void:
	if sub_list == null:
		return
	for b in sub_buttons:
		sub_list.remove_child(b)
		b.queue_free()
	sub_buttons.clear()
	if selected < 0 or selected >= muscles.size() or not muscles[selected].has("muscles"):
		if sub_header:
			sub_header.text = ""
		return
	if sub_header:
		sub_header.text = "MUSCLES IN " + muscles[selected].name.to_upper()
	for j in muscles[selected].muscles.size():
		var button := Button.new()
		button.text = muscles[selected].muscles[j].name
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if ui_portrait:
			button.custom_minimum_size = Vector2(0, 38)
			button.add_theme_font_size_override("font_size", 16)
		else:
			button.custom_minimum_size = Vector2(170, 30)
			button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(_select_sub_muscle.bind(selected, j))
		sub_list.add_child(button)
		sub_buttons.append(button)

func _tint_muscles() -> void:
	if selected < 0:
		# No muscle selected: show the full anatomy in neutral muscle color.
		for i in muscle_meshes.size():
			muscle_meshes[i].material_override = _material(MUSCLE)
		return
	# When a specific sub-muscle is selected, find which meshes (from ANY group)
	# actually overlap/cover it in 3D space so they can be made transparent.
	var sel_aabbs: Array[AABB] = []
	if selected_muscle >= 0:
		var sel_meshes := group_meshes[selected] if selected < group_meshes.size() else []
		for mesh: MeshInstance3D in sel_meshes:
			if _sub_muscle_of(mesh, selected) == selected_muscle:
				sel_aabbs.append(_mesh_global_aabb(mesh))
	for i in muscle_meshes.size():
		var mesh := muscle_meshes[i]
		var group_index := _group_of(mesh)
		var is_selected := false
		if group_index == selected:
			is_selected = selected_muscle == -1 or _sub_muscle_of(mesh, group_index) == selected_muscle
		if is_selected:
			mesh.material_override = _highlight_material(HIGHLIGHT)
		elif selected_muscle >= 0:
			# Any muscle (from any group) whose bounds fully contain the selected
			# one covers it, so it goes transparent to reveal the deep muscle.
			# Containment (rather than mere intersection) avoids hiding side-by-side
			# neighbours such as biceps vs triceps.
			if _covers_any(mesh, sel_aabbs):
				mesh.material_override = _transparent_material(GREY, 0.18)
			else:
				mesh.material_override = _material(GREY)
		else:
			# Whole group selected: highlight the group's meshes, grey the rest.
			if group_index == selected:
				mesh.material_override = _highlight_material(HIGHLIGHT)
			else:
				mesh.material_override = _material(GREY)

func _mesh_global_aabb(mesh: MeshInstance3D) -> AABB:
	var local: AABB = mesh.get_aabb()
	var t := mesh.get_global_transform()
	var out := AABB()
	var has := false
	for idx in 8:
		var corner: Vector3 = local.get_endpoint(idx)
		var gc: Vector3 = t * corner
		if not has:
			out = AABB(gc, Vector3.ZERO)
			has = true
		else:
			out = out.expand(gc)
	return out

func _covers_any(mesh: MeshInstance3D, sel_aabbs: Array[AABB]) -> bool:
	if sel_aabbs.is_empty():
		return false
	var box: AABB = _mesh_global_aabb(mesh)
	for sel in sel_aabbs:
		# A muscle covers the selected one if a significant share of the selected
		# muscle's bounds lie inside it. This reveals deep/buried muscles while not
		# hiding side-by-side neighbours (e.g. biceps vs triceps) whose overlap is
		# only a small fraction.
		var inter: AABB = box.intersection(sel)
		if inter != null:
			var sel_vol: float = sel.size.x * sel.size.y * sel.size.z
			var inter_vol: float = inter.size.x * inter.size.y * inter.size.z
			if sel_vol > 0.0 and inter_vol / sel_vol >= 0.45:
				return true
	return false

func _focus_on_group(group_index: int, sub_index: int = -1) -> void:
	var meshes: Array = group_meshes[group_index] if group_index < group_meshes.size() else []
	if meshes.is_empty():
		focus_target = _frame_target(Vector3(0, 1.0, 0), 4.5)
		focus_zoom = 4.5
		return
	var center := Vector3.ZERO
	var count := 0
	for mesh: MeshInstance3D in meshes:
		if sub_index >= 0 and _sub_muscle_of(mesh, group_index) != sub_index:
			continue
		var aabb: AABB = mesh.get_aabb()
		var c: Vector3 = mesh.get_global_transform() * aabb.get_center()
		center += c
		count += 1
	if count == 0:
		focus_target = _frame_target(Vector3(0, 1.0, 0), 4.5)
		focus_zoom = 4.5
		return
	center /= float(count)
	focus_target = _frame_target(center, 1.8 if sub_index >= 0 else 2.4)
	focus_zoom = 1.8 if sub_index >= 0 else 2.4
	# Rotate the camera to face the muscle. A per-muscle "view" hint (front/back/
	# side) decides the primary axis; the lateral component is kept so the muscle
	# is framed from its own side. Falls back to the outward direction otherwise.
	var view := ""
	if sub_index >= 0 and muscles[group_index].has("muscles"):
		view = str(muscles[group_index].muscles[sub_index].get("view", "auto"))
	var dir := Vector2(center.x, center.z)
	var target := Vector2.ZERO
	match view:
		"front":
			target = Vector2(dir.x, 1.0)
		"back":
			target = Vector2(dir.x, -1.0)
		"left":
			target = Vector2(-1.0, dir.y)
		"right":
			target = Vector2(1.0, dir.y)
		_:
			target = dir
	if target.length() > 0.02:
		target = target.normalized()
		focus_yaw = atan2(target.x, target.y)
	else:
		focus_yaw = yaw
	focus_pitch = 0.05

func _reset_view() -> void:
	selected = -1
	selected_muscle = -1
	_rebuild_sub_list()
	if detail_title:
		detail_title.text = "Health Avatar"
	if detail_summary:
		detail_summary.text = "Select a muscle group to explore its anatomy, sub-muscles and Jeff Nippard exercise recommendations."
	if detail_exercise_list:
		_populate_exercises([])
	if state_badge:
		state_badge.text = ""
	if selection_buttons.size() > 0:
		for b in selection_buttons:
			b.add_theme_color_override("font_color", TEXT)
	_tint_muscles()
	yaw = 0.0
	pitch = 0.05
	zoom = 4.5
	focus_yaw = 0.0
	focus_pitch = 0.05
	focus_zoom = 4.5
	focus_target = _frame_target(Vector3(0, 1.0, 0), 4.5)
	_update_camera()

func _sub_muscle_of(mesh: MeshInstance3D, group_index: int) -> int:
	var name_lower: String = mesh.name.to_lower()
	if not muscles[group_index].has("muscles"):
		return -1
	for j in muscles[group_index].muscles.size():
		for kw: String in muscles[group_index].muscles[j].keywords:
			if kw in name_lower:
				return j
	return -1

func _group_of(mesh: MeshInstance3D) -> int:
	var name_lower: String = mesh.name.to_lower()
	for g in muscles.size():
		for kw: String in muscles[g].keywords:
			if kw in name_lower:
				return g
	return -1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
		return
	if event is InputEventScreenDrag:
		_handle_drag(event)
		return
	if event is InputEventMagnifyGesture:
		zoom = clamp(zoom * (1.0 / event.factor), ZOOM_MIN, ZOOM_MAX)
		focus_zoom = zoom
		_update_camera()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				last_mouse = event.position
				click_start = event.position
				click_moved = false
			else:
				dragging = false
				if not click_moved and not pinch_active:
					_pick_muscle(event.position)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = max(ZOOM_MIN, zoom - 0.35)
			focus_zoom = zoom
			_update_camera()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = min(ZOOM_MAX, zoom + 0.35)
			focus_zoom = zoom
			_update_camera()
	elif event is InputEventMouseMotion and dragging and not pinch_active:
		var delta: Vector2 = event.position - last_mouse
		if event.position.distance_to(click_start) > 6.0:
			click_moved = true
		yaw -= delta.x * 0.01
		pitch = clamp(pitch - delta.y * 0.01, -0.8, 0.8)
		last_mouse = event.position
		focus_target = camera_pivot.position
		focus_yaw = yaw
		focus_pitch = pitch
		_update_camera()
	elif event.is_action_pressed("orbit_reset"):
		yaw = 0.0
		pitch = 0.05
		zoom = 4.5
		focus_zoom = 4.5
		focus_yaw = 0.0
		focus_pitch = 0.05
		focus_target = _frame_target(Vector3(0, 1.0, 0), 4.5)
		_update_camera()

func _pick_muscle(screen_pos: Vector2) -> void:
	var camera := camera_pivot.get_child(0) as Camera3D
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 40.0
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space.intersect_ray(query)
	if result.is_empty():
		return
	var body := result.get("collider") as Node
	if body and body.has_meta("muscle_index"):
		var group_index: int = body.get_meta("muscle_index")
		if group_index != selected:
			selected = group_index
			_rebuild_sub_list()
		# find which specific sub-muscle mesh was hit
		var hit_name: String = String(result.get("collider").get_meta("hit_mesh_name", ""))
		var sub_index := -1
		for j in muscles[group_index].muscles.size():
			for kw: String in muscles[group_index].muscles[j].keywords:
				if kw in hit_name:
					sub_index = j
					break
			if sub_index >= 0:
				break
		_select_sub_muscle(group_index, sub_index)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var index := event.index
	if event.pressed:
		touches[index] = event.position
	else:
		touches.erase(index)
	if touches.size() >= 2:
		var positions := touches.values()
		if not pinch_active:
			pinch_active = true
			pinch_start_dist = positions[0].distance_to(positions[1])
			pinch_start_zoom = zoom
	elif touches.size() < 2:
		pinch_active = false

func _handle_drag(event: InputEventScreenDrag) -> void:
	if not touches.has(event.index):
		touches[event.index] = event.position
	else:
		touches[event.index] = event.position
	if pinch_active and touches.size() >= 2:
		var positions := touches.values()
		var dist: float = positions[0].distance_to(positions[1])
		if pinch_start_dist > 1.0:
			zoom = clamp(pinch_start_zoom * (pinch_start_dist / dist), ZOOM_MIN, ZOOM_MAX)
			# Keep focus_zoom in sync so the per-frame smoothing in _process does not revert it.
			focus_zoom = zoom
			_update_camera()

func _wrap_angle(a: float) -> float:
	while a > PI:
		a -= TAU
	while a < -PI:
		a += TAU
	return a

func _update_camera() -> void:
	camera_pivot.rotation = Vector3(pitch, yaw, 0)
	var camera := camera_pivot.get_child(0) as Camera3D
	camera.position.z = zoom
