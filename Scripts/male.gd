extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var last_animation_name: String = ""
var is_paused: bool = false
var paused_position: float = 0.0
var is_looping: bool = false


func _ready() -> void:
	animation_player.playback_active = true

func _process(_delta: float) -> void:
	# Keep DancerState in sync
	if animation_player.is_playing():
		DancerState.animation_time = animation_player.current_animation_position

# ----------------------------
# Animation Control
# ----------------------------
func play_move(anim_name: String) -> void:
	if not animation_player or not animation_player.has_animation(anim_name):
		push_warning("Animation not found: " + anim_name)
		return

	print("DEBUG: play_move called with:", anim_name)

	animation_player.stop()
	animation_player.play(anim_name)
	last_animation_name = anim_name

	is_paused = false
	paused_position = 0.0

	# Update DancerState
	DancerState.current_animation = anim_name
	DancerState.is_playing = true
	DancerState.is_paused = false
	DancerState.animation_time = 0.0
	DancerState.animation_length = animation_player.current_animation_length

func toggle_pause_or_resume() -> void:
	if not animation_player:
		return

	if is_paused:
		animation_player.speed_scale = 1.0
		is_paused = false
		DancerState.is_paused = false
		DancerState.is_playing = true
	else:
		animation_player.speed_scale = 0.0
		is_paused = true
		DancerState.is_paused = true
		DancerState.is_playing = false

func replay_last_animation() -> void:
	if last_animation_name == "" or not animation_player.has_animation(last_animation_name):
		return

	print("Replaying last animation:", last_animation_name)

	is_paused = false
	paused_position = 0.0
	animation_player.speed_scale = 1.0

	animation_player.stop()
	animation_player.play(last_animation_name)
	animation_player.seek(0.0, true)

	DancerState.current_animation = last_animation_name
	DancerState.is_playing = true
	DancerState.is_paused = false
	DancerState.animation_time = 0.0
	DancerState.animation_length = animation_player.current_animation_length

func loop_current_animation() -> void:
	if last_animation_name == "" or not animation_player.has_animation(last_animation_name):
		print("DEBUG: No animation to loop")
		return

	is_looping = true
	animation_player.get_animation(last_animation_name).loop = true
	print("DEBUG: Looping enabled for", last_animation_name)

func stop_animation() -> void:
	if not animation_player:
		return

	# Stop playback immediately
	animation_player.stop()
	is_paused = false
	paused_position = 0.0

	# Keep last_animation_name so replay works
	# Update DancerState to reflect stopped but replayable animation
	DancerState.is_playing = false
	DancerState.is_paused = false
	DancerState.animation_time = 0.0



# ----------------------------
# Seamless switch support
# ----------------------------
func seek_to_time(time: float) -> void:
	if not animation_player or last_animation_name == "":
		return

	animation_player.seek(time, true)
	DancerState.animation_time = time

func get_playback_state() -> Dictionary:
	return {
		"animation": last_animation_name,
		"time": animation_player.current_animation_position,
		"is_paused": is_paused
	}

func apply_playback_state(state: Dictionary) -> void:
	if not state.has("animation") or state.animation == "":
		return
	if not animation_player.has_animation(state.animation):
		return

	animation_player.stop()
	animation_player.play(state.animation)
	animation_player.seek(state.get("time", 0.0), true)

	last_animation_name = state.animation
	is_paused = state.get("is_paused", false)

	animation_player.speed_scale = 0.0 if is_paused else 1.0

	# Update DancerState
	DancerState.current_animation = state.animation
	DancerState.animation_time = state.get("time", 0.0)
	DancerState.is_paused = is_paused
	DancerState.is_playing = not is_paused
