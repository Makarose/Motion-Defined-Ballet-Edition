extends Node3D

# ----------------------------
# Nodes
# ----------------------------
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var scrub_slider: Slider = $ScrubSlider  # optional UI slider for local scrubbing

# ----------------------------
# State
# ----------------------------
var last_animation_name: String = ""
var is_paused: bool = false
var is_looping: bool = false

# ----------------------------
# Godot callbacks
# ----------------------------
func _ready() -> void:
	if animation_player:
		animation_player.playback_active = true
		animation_player.speed_scale = DancerState.animation_speed  # Let AnimationPlayer control timing

	if scrub_slider:
		scrub_slider.connect("value_changed", Callable(self, "_on_scrub_slider_changed"))

func _process(delta: float) -> void:
	if not animation_player:
		return

	# Update DancerState based on AnimationPlayer
	if animation_player.current_animation != "":
		DancerState.animation_time = animation_player.current_animation_position
		DancerState.animation_length = animation_player.current_animation_length
		DancerState.current_animation = animation_player.current_animation
		DancerState.is_playing = animation_player.is_playing()
		DancerState.is_paused = is_paused

		DancerState.emit_signal("playback_position_changed", DancerState.animation_time, DancerState.animation_length)

	# Update scrub slider if present and not being dragged
	if scrub_slider and not scrub_slider.is_dragging() and animation_player.current_animation_length > 0:
		scrub_slider.min_value = 0.0
		scrub_slider.max_value = animation_player.current_animation_length
		scrub_slider.value = animation_player.current_animation_position

# ----------------------------
# Animation Control
# ----------------------------
func play_move(anim_name: String) -> void:
	if not animation_player or not animation_player.has_animation(anim_name):
		push_warning("Animation not found: " + anim_name)
		return

	if last_animation_name != anim_name:
		last_animation_name = anim_name
		is_paused = false
		is_looping = false

		animation_player.speed_scale = DancerState.animation_speed
		animation_player.play(anim_name)
		
		DancerState.current_animation = anim_name
		DancerState.is_playing = true
		DancerState.is_paused = false
		DancerState.animation_time = 0.0
		DancerState.animation_length = animation_player.current_animation_length
		DancerState.emit_signal("animation_changed", anim_name)
		DancerState.emit_signal("playback_started")

func toggle_pause_or_resume() -> void:
	if not animation_player:
		return

	is_paused = not is_paused
	DancerState.is_paused = is_paused

	if is_paused:
		animation_player.playback_active = false  # freeze in place
		DancerState.is_playing = false
	else:
		animation_player.playback_active = true   # resume from current position
		animation_player.speed_scale = DancerState.animation_speed
		DancerState.is_playing = true


func replay_last_animation() -> void:
	if last_animation_name == "" or not animation_player.has_animation(last_animation_name):
		return

	play_move(last_animation_name)

func loop_current_animation() -> void:
	if last_animation_name == "" or not animation_player.has_animation(last_animation_name):
		print_debug("No animation to loop")
		return

	is_looping = true
	animation_player.get_animation(last_animation_name).loop = true
	print_debug("Looping enabled for", last_animation_name)

func stop_animation() -> void:
	if not animation_player:
		return

	animation_player.stop()
	is_paused = false
	is_looping = false

	DancerState.is_playing = false
	DancerState.is_paused = false
	DancerState.animation_time = 0.0
	DancerState.animation_length = animation_player.current_animation_length

# ----------------------------
# Seek & Scrubbing
# ----------------------------
func seek_to_time(time: float) -> void:
	if not animation_player or last_animation_name == "":
		return

	var anim_length = animation_player.current_animation_length
	if anim_length <= 0:
		return

	animation_player.seek(time, true)
	DancerState.animation_time = time

	# freeze playback while scrubbing
	animation_player.playback_active = false
	is_paused = true
	DancerState.is_paused = true
	DancerState.is_playing = false



func _on_scrub_slider_changed(value: float) -> void:
	seek_to_time

# ----------------------------
# Save/Restore Playback State
# ----------------------------
func get_playback_state() -> Dictionary:
	var anim_name = animation_player.current_animation
	if anim_name == "":
		return {
			"animation": "",
			"time": 0.0,
			"length": 0.0,
			"is_paused": is_paused
		}

	return {
		"animation": anim_name,
		"time": animation_player.current_animation_position,
		"length": animation_player.current_animation_length,
		"is_paused": is_paused
	}

func apply_playback_state(state: Dictionary) -> void:
	if not state.has("animation") or state.animation == "":
		return
	if not animation_player.has_animation(state.animation):
		return

	if not animation_player.has_animation(state.animation):
		return

	animation_player.play(state.animation)
	animation_player.speed_scale = DancerState.animation_speed
	animation_player.seek(state.get("time", 0.0), true)
	animation_player.playback_active = not state.get("is_paused", false)


	last_animation_name = state.animation
	is_paused = state.get("is_paused", false)

	DancerState.current_animation = state.animation
	DancerState.animation_time = state.get("time", 0.0)
	DancerState.is_paused = is_paused
	DancerState.animation_length = animation_player.current_animation_length
	DancerState.is_playing = not is_paused

	if scrub_slider:
		_update_slider_for_animation(state.animation)

# ----------------------------
# Helper: Slider max update
# ----------------------------
func _update_slider_for_animation(anim_name: String) -> void:
	if not scrub_slider or not animation_player.has_animation(anim_name):
		return
	var anim_length = animation_player.get_animation(anim_name).length
	scrub_slider.min_value = 0.0
	scrub_slider.max_value = anim_length
	scrub_slider.value = 0.0
