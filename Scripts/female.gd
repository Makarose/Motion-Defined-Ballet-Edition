extends Node3D

# ----------------------------
# Nodes
# ----------------------------
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# ----------------------------
# State
# ----------------------------
var last_animation_name: String = ""
var is_paused: bool = false
var is_looping: bool = false
var is_scrubbing: bool = false

# ----------------------------
# Godot callbacks
# ----------------------------
func _ready() -> void:
	if animation_player:
		animation_player.playback_active = true
		animation_player.speed_scale = DancerState.animation_speed
		print("Dancer ready, AnimationPlayer active")

func _process(delta: float) -> void:
	if not animation_player:
		return

	# Do not push time while the UI is scrubbing
	if DancerState.scrub_active:
		return

	if animation_player.current_animation != "":
		DancerState.animation_time = animation_player.current_animation_position
		DancerState.animation_length = animation_player.current_animation_length
		DancerState.current_animation = animation_player.current_animation
		DancerState.is_playing = animation_player.is_playing()
		DancerState.is_paused = is_paused

		DancerState.emit_signal(
			"playback_position_changed",
			DancerState.animation_time,
			DancerState.animation_length
		)

# ----------------------------
# Animation Control
# ----------------------------
func play_move(anim_name: String) -> void:
	DancerState.scrub_active = false
	is_scrubbing = false
	is_paused = false
	
	if not animation_player or not animation_player.has_animation(anim_name):
		push_warning("Animation not found: " + anim_name)
		return

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

	print("play_move called for animation:", anim_name)

func pause_animation() -> void:
	if not animation_player:
		return

	if animation_player.is_playing():
		is_paused = true
		animation_player.playback_active = false
		DancerState.is_paused = true
		DancerState.is_playing = false
		print("Animation paused")

func toggle_pause_or_resume() -> void:
	if not animation_player:
		return

	is_paused = not is_paused
	DancerState.is_paused = is_paused

	if is_paused:
		animation_player.playback_active = false
		DancerState.is_playing = false
		print("Toggled: paused")
	else:
		animation_player.playback_active = true
		animation_player.speed_scale = DancerState.animation_speed
		DancerState.is_playing = true
		print("Toggled: resumed")

func replay_last_animation() -> void:
	if last_animation_name == "" or not animation_player.has_animation(last_animation_name):
		print("No animation to replay")
		return
	print("Replaying last animation:", last_animation_name)
	play_move(last_animation_name)


func loop_current_animation() -> void:
	if last_animation_name == "" or not animation_player.has_animation(last_animation_name):
		print_debug("No animation to loop")
		return

	is_looping = true
	animation_player.get_animation(last_animation_name).loop = true
	print_debug("Looping enabled for ", last_animation_name)


func stop_animation() -> void:
	if not animation_player:
		return

	animation_player.stop()
	is_paused = false
	is_looping = false
	is_scrubbing = false
	
	DancerState.scrub_active = false
	DancerState.is_playing = false
	DancerState.is_paused = false
	DancerState.animation_time = 0.0
	DancerState.animation_length = animation_player.current_animation_length
	print("Animation stopped")

# ----------------------------
# Seek & Scrubbing
# ----------------------------
func seek_to_time(time: float) -> void:
	if not animation_player or last_animation_name == "":
		return

	var anim_length = animation_player.current_animation_length
	if anim_length <= 0:
		return

	is_scrubbing = true
	animation_player.seek(time, true)
	DancerState.animation_time = time
	DancerState.animation_length = anim_length
	print("Slider moved to", time)

func resume_from_scrub() -> void:
	if not animation_player:
		return

	is_scrubbing = false
	is_paused = false
	animation_player.playback_active = true
	animation_player.speed_scale = DancerState.animation_speed
	DancerState.is_paused = false
	DancerState.is_playing = true
	print("Resumed from scrub at", DancerState.animation_time)

# ----------------------------
# Save / Restore Playback State
# ----------------------------
func get_playback_state() -> Dictionary:
	if not animation_player:
		return {
		"animation": "",
		"time": 0.0,
		"length": 0.0,
		"is_paused": is_paused
	}

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
	if not animation_player:
		return
	if not state.has("animation") or state.animation == "":
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

	print("Applied playback state for animation:", state.animation)
