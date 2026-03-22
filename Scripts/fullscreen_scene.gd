# ----------------------------
# fullscreen_scene.gd
# ----------------------------
extends Control

# ----------------------------
# Signals emitted up to MainScene
# ----------------------------
signal exit_requested
signal character_changed(scene_path: String)

# ----------------------------
# Nodes
# ----------------------------
@onready var video_controls: Control = $CanvasLayer/VideoControls
@onready var dancer_viewport: SubViewport = $CanvasLayer/SubViewportContainer/DancerViewport
@onready var character_slot: Node3D = $CanvasLayer/SubViewportContainer/DancerViewport/CharacterSlot
# ----------------------------
# Runtime state
# ----------------------------
var current_dancer: Node3D = null
var instructions_overlay: Control = null

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	$CanvasLayer.hide()
	video_controls.exit_requested.connect(_on_exit_requested)
	video_controls.character_requested.connect(_on_character_requested)
	video_controls.instructions_requested.connect(_on_instructions_requested)

# ----------------------------
# Called by MainScene when fullscreen is shown
# Spawns a fresh dancer into the fullscreen viewport
# ----------------------------
func set_dancer(_dancer: Node3D) -> void:
	if current_dancer and current_dancer.is_inside_tree():
		current_dancer.queue_free()
		current_dancer = null

	var char_path: String = GameManager.chosen_character
	if char_path == "":
		push_warning("[FullscreenScene] No chosen character in GameManager")
		return

	var char_packed: PackedScene = load(char_path)
	if not char_packed:
		push_error("[FullscreenScene] Could not load character scene: " + char_path)
		return

	current_dancer = char_packed.instantiate()
	character_slot.add_child(current_dancer)

	await get_tree().process_frame

	if GameManager.selected_animation != "":
		current_dancer.apply_playback_state({
			"animation": GameManager.selected_animation,
			"time": GameManager.playback_time,
			"is_paused": GameManager.is_paused,
			"is_looping": GameManager.is_looping
		})

	video_controls.set_dancer(current_dancer)
	print("[FullscreenScene] Dancer set")

# ----------------------------
# Exit requested from VideoControls
# ----------------------------
func _on_exit_requested() -> void:
	emit_signal("exit_requested")

func request_exit() -> void:
	emit_signal("exit_requested")
	
	
# ----------------------------
# Character swap requested from VideoControls
# ----------------------------
func _on_character_requested(scene_path: String) -> void:
	GameManager.chosen_character = scene_path

	# Save state from current dancer BEFORE freeing it
	if current_dancer != null:
		GameManager.save_playback_state(current_dancer)

	print("[FullscreenScene] Saved state — animation:", GameManager.selected_animation, " time:", GameManager.playback_time, " is_paused:", GameManager.is_paused, " is_looping:", GameManager.is_looping)

	# Free old dancer
	if current_dancer and current_dancer.is_inside_tree():
		current_dancer.queue_free()
		current_dancer = null

	# Load new dancer — hide it until state is applied
	var char_packed: PackedScene = load(scene_path)
	if not char_packed:
		push_error("[FullscreenScene] Could not load character scene: " + scene_path)
		return

	current_dancer = char_packed.instantiate()
	current_dancer.visible = false
	character_slot.add_child(current_dancer)
	await get_tree().process_frame
	await get_tree().process_frame

	if GameManager.selected_animation != "":
		current_dancer.apply_playback_state({
			"animation": GameManager.selected_animation,
			"time": GameManager.playback_time,
			"is_paused": GameManager.is_paused,
			"is_looping": GameManager.is_looping
		})

	current_dancer.visible = true
	video_controls.set_dancer(current_dancer, false)
	emit_signal("character_changed", scene_path)



# ----------------------------
# Instructions Overlay
# ----------------------------
func _on_instructions_requested() -> void:
	var instructions_scene = load("res://Scenes/instructions.tscn")
	instructions_overlay = instructions_scene.instantiate()
	$CanvasLayer.add_child(instructions_overlay)
	video_controls.hide()

	await get_tree().process_frame
	if OS.get_name() == "macOS":
		await get_tree().create_timer(0.2).timeout

	var back_button = instructions_overlay.get_node_or_null("MarginContainer2/HBoxContainer/BackButtonContainer/VBoxContainer/BackButton")
	if back_button:
		# Disconnect all existing connections safely
		if back_button.pressed.is_connected(instructions_overlay._on_back_button_pressed):
			back_button.pressed.disconnect(instructions_overlay._on_back_button_pressed)
		# Connect to our overlay close
		if not back_button.pressed.is_connected(_on_instructions_back_pressed):
			back_button.pressed.connect(_on_instructions_back_pressed)

func _on_instructions_back_pressed() -> void:
	if instructions_overlay:
		instructions_overlay.queue_free()
		instructions_overlay = null
	video_controls.show()
