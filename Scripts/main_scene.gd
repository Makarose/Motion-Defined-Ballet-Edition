# ----------------------------
# main_scene.gd
# ----------------------------
extends Control

# ----------------------------
# Scene Nodes
# ----------------------------
@onready var main_scene_ui: Control = $MainSceneUI
@onready var dancer_viewport: SubViewport = $SubViewportContainer/DancerViewport
@onready var fullscreen_scene: Control = $FullscreenScene

# ----------------------------
# Runtime state
# ----------------------------
var current_dancer: Node3D = null

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("[MainScene] Ready")
	
	# If returning to fullscreen, hide UI immediately to prevent flash
	if GameManager.is_fullscreen:
		main_scene_ui.hide()
	
	fullscreen_scene.hide()

	# Wire up MainSceneUI signals
	main_scene_ui.term_selected.connect(_on_term_selected)
	main_scene_ui.fullscreen_requested.connect(_on_fullscreen_requested)
	main_scene_ui.back_pressed.connect(_on_nav_left)
	main_scene_ui.index_pressed.connect(_on_nav_right)
	main_scene_ui.replay_requested.connect(_on_replay_requested)

	# Wire up FullscreenScene signals
	fullscreen_scene.exit_requested.connect(_on_fullscreen_exit)
	fullscreen_scene.character_changed.connect(_on_character_changed)

	# Spawn character — there should always be one from title page
	if GameManager.chosen_character != "":
		_spawn_dancer(GameManager.chosen_character)
	else:
		push_warning("[MainScene] No character chosen — did you come from title page?")

	# If we arrived from index with a term already selected, auto-play it
	if GameManager.selected_term != "":
		_play_term(GameManager.selected_term, GameManager.selected_animation)
		main_scene_ui.restore_term(GameManager.selected_term, GameManager.selected_definition)
		await get_tree().process_frame
		main_scene_ui.show_fullscreen_button()
		main_scene_ui.hide_random_button()
		
		# If we were in fullscreen before (e.g., returning from instructions), re-enter fullscreen
		if GameManager.is_fullscreen:
			await get_tree().process_frame
			_on_fullscreen_requested()
			
			
# ----------------------------
# Spawn a dancer into the SubViewport
# Replaces any existing dancer
# ----------------------------
func _spawn_dancer(scene_path: String) -> void:
	if current_dancer and current_dancer.is_inside_tree():
		current_dancer.queue_free()
		current_dancer = null

	var packed: PackedScene = load(scene_path)
	if not packed:
		push_error("[MainScene] Could not load character scene: " + scene_path)
		return

	current_dancer = packed.instantiate()
	dancer_viewport.add_child(current_dancer)
	print("[MainScene] Spawned dancer:", scene_path)
	
	# Connect animation finished signal
	current_dancer.animation_finished.connect(_on_animation_finished)

	# Only play idle if no term is selected
	if GameManager.selected_animation == "":
		current_dancer.play_idle()


func _on_animation_finished(anim_name: String) -> void:
	print("[MainScene] Animation finished:", anim_name)
	
	# Only show replay if a real term animation finished, not idle
	if anim_name == "" or GameManager.normalize(anim_name) == GameManager.normalize("idle"):
		return
	
	# Guard against stale signals — only react if this matches what we selected
	if GameManager.selected_animation == "":
		return
	
	if GameManager.normalize(anim_name) != GameManager.normalize(GameManager.selected_animation):
		return
	
	main_scene_ui.show_replay_button()

# ----------------------------
# Find exact animation clip name on dancer
# Uses normalization so casing/accents don't matter
# ----------------------------
func _resolve_animation_name(anim_name: String) -> String:
	if current_dancer == null:
		return ""
	var ap: AnimationPlayer = current_dancer.get_node_or_null("AnimationPlayer")
	if ap == null:
		return ""
	for clip in ap.get_animation_list():
		if GameManager.normalize(clip) == GameManager.normalize(anim_name):
			return clip
	return ""


# ----------------------------
# Play a term on the current dancer
# ----------------------------
func _play_term(term: String, anim_name: String) -> void:
	if current_dancer == null:
		push_warning("[MainScene] Cannot play term — no dancer")
		return

	var resolved: String = _resolve_animation_name(anim_name)
	if resolved == "":
		push_warning("[MainScene] Could not resolve animation: " + anim_name)
		return

	# Save to GameManager
	GameManager.selected_term = term
	GameManager.selected_animation = resolved

	current_dancer.play_animation(resolved)
	print("[MainScene] Playing animation:", resolved)


# ----------------------------
# Term selected from MainSceneUI search
# ----------------------------
func _on_term_selected(term: String, anim_name: String, definition: String) -> void:
	print("[MainScene] Term selected:", term)
	GameManager.selected_definition = definition
	_play_term(term, anim_name)
	main_scene_ui.hide_replay_button()
	main_scene_ui.show_fullscreen_button()


# ----------------------------
# Fullscreen requested
# ----------------------------
func _on_fullscreen_requested() -> void:
	GameManager.is_fullscreen = true
	print("[MainScene] is_fullscreen set to:", GameManager.is_fullscreen)
	main_scene_ui.process_mode = Node.PROCESS_MODE_DISABLED
	main_scene_ui.hide()
	fullscreen_scene.get_node("CanvasLayer").show()
	await fullscreen_scene.set_dancer(current_dancer)


# ----------------------------
# Exit fullscreen
# ----------------------------
func _on_fullscreen_exit() -> void:
	GameManager.is_fullscreen = false
	fullscreen_scene.get_node("CanvasLayer").hide()
	main_scene_ui.process_mode = Node.PROCESS_MODE_INHERIT
	main_scene_ui.show()
	# Re-focus search bar
	await get_tree().process_frame
	main_scene_ui.search_bar.grab_focus()
	
# ----------------------------
# Replay requested
# ----------------------------
func _on_replay_requested() -> void:
	if current_dancer:
		current_dancer.replay_last_animation()
		main_scene_ui.hide_replay_button()
		main_scene_ui.show_fullscreen_button()


# ----------------------------
# Character changed from fullscreen character swap
# ----------------------------
func _on_character_changed(scene_path: String) -> void:
	print("[MainScene] Character changed to:", scene_path)
	GameManager.chosen_character = scene_path

	_spawn_dancer(scene_path)

	if GameManager.selected_animation != "":
		var resolved: String = _resolve_animation_name(GameManager.selected_animation)
		if resolved != "":
			current_dancer.apply_playback_state({
				"animation": resolved,
				"time": GameManager.playback_time,
				"is_paused": GameManager.is_paused,
				"is_looping": GameManager.is_looping
			})


# ----------------------------
# Navigation
# ----------------------------
func _on_nav_left() -> void:
	GameManager.clear_term_state()
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")

func _on_nav_right() -> void:
	get_tree().change_scene_to_file("res://Scenes/index.tscn")

func _on_back_button_pressed() -> void:
	_on_nav_left()

func _on_index_button_pressed() -> void:
	_on_nav_right()
	
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	print("[MainScene] _input keycode:", event.keycode, " ctrl:", event.ctrl_pressed)

	if GameManager.is_fullscreen:
		if event.is_action("exit_fullscreen") or event.is_action("ui_focus_next"):
			get_viewport().set_input_as_handled()
			fullscreen_scene.request_exit()
		return
		
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	print("[MainScene] _unhandled keycode:", event.keycode, " ctrl:", event.ctrl_pressed)
