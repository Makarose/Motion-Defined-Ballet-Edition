# ----------------------------
# dancer.gd
# Attach to the root node of male.tscn and female.tscn
# ----------------------------
extends Node3D

signal animation_finished(anim_name: String)

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# ----------------------------
# Playback state
# ----------------------------
var last_animation_name: String = ""
var is_paused: bool = false
var is_looping: bool = false
var paused_time: float = 0.0


func _ready() -> void:
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)


# ----------------------------
# Play a named animation from the beginning
# Expects the exact animation clip name (normalization done by caller)
# ----------------------------
func play_animation(anim_name: String) -> void:
	if not animation_player.has_animation(anim_name):
		push_warning("[Dancer] Animation not found: " + anim_name)
		return

	last_animation_name = anim_name
	is_paused = false
	is_looping = false
	paused_time = 0.0

	var anim: Animation = animation_player.get_animation(anim_name)
	if anim:
		anim.loop_mode = Animation.LOOP_NONE

	animation_player.play(anim_name)
	animation_player.seek(0.0, true)


# ----------------------------
# Play idle / waiting pose
# Freezes on frame 0 of plie — no animation plays
# Call this when dancer first loads before any term is selected
# ----------------------------
func play_idle() -> void:
	if animation_player.has_animation("plie"):
		animation_player.play("plie")
		animation_player.seek(0.0, true)
		animation_player.pause()
		last_animation_name = ""  # empty so scrub bar doesn't activate
		is_paused = false         # not "paused" in the playback sense
	else:
		animation_player.stop()


# ----------------------------
# Pause at current frame
# ----------------------------
func pause_animation() -> void:
	if animation_player.is_playing():
		is_paused = true
		paused_time = animation_player.current_animation_position
		animation_player.pause()


# ----------------------------
# Resume from paused frame
# ----------------------------
func resume_animation() -> void:
	if last_animation_name == "" or not is_paused:
		return
	is_paused = false
	animation_player.play(last_animation_name)
	animation_player.seek(paused_time, true)


# ----------------------------
# Replay from the beginning
# ----------------------------
func replay_last_animation() -> void:
	if last_animation_name == "":
		return

	is_paused = false
	is_looping = false
	paused_time = 0.0

	var anim: Animation = animation_player.get_animation(last_animation_name)
	if anim:
		anim.loop_mode = Animation.LOOP_NONE

	animation_player.play(last_animation_name)
	animation_player.seek(0.0, true)


# ----------------------------
# Loop current animation
# ----------------------------
func loop_current_animation() -> void:
	if last_animation_name == "":
		return

	is_looping = true
	is_paused = false
	paused_time = 0.0

	var anim: Animation = animation_player.get_animation(last_animation_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR

	if not animation_player.is_playing():
		animation_player.play(last_animation_name)


# ----------------------------
# Stop and return to frame 0
# ----------------------------
func stop_animation() -> void:
	if last_animation_name == "":
		return

	is_looping = false
	is_paused = false
	paused_time = 0.0

	var anim: Animation = animation_player.get_animation(last_animation_name)
	if anim:
		anim.loop_mode = Animation.LOOP_NONE

	animation_player.stop()
	animation_player.seek(0.0, true)


# ----------------------------
# Scrub to a specific time
# Does not change play/pause state
# ----------------------------
func seek_to_time(time_sec: float) -> void:
	if last_animation_name == "":
		return

	if animation_player.current_animation != last_animation_name:
		animation_player.play(last_animation_name)
		animation_player.pause()
		is_paused = true

	animation_player.seek(time_sec, true)
	paused_time = time_sec


# ----------------------------
# Get current playback state as a Dictionary
# Used by scrub bar and GameManager.save_playback_state()
# ----------------------------
func get_playback_state() -> Dictionary:
	var state: Dictionary = {}
	state["animation"] = last_animation_name
	state["time"] = 0.0
	state["length"] = 0.0
	state["is_paused"] = is_paused
	state["is_looping"] = is_looping

	if last_animation_name != "" and animation_player.has_animation(last_animation_name):
		var anim: Animation = animation_player.get_animation(last_animation_name)
		if anim:
			state["length"] = anim.length
			state["time"] = animation_player.current_animation_position

	return state


# ----------------------------
# Restore playback state (e.g. after character swap)
# ----------------------------
func apply_playback_state(state: Dictionary) -> void:
	if not state.has("animation") or state["animation"] == "":
		return
	if not animation_player.has_animation(state["animation"]):
		push_warning("[Dancer] Cannot restore state — animation not found: " + state["animation"])
		return

	last_animation_name = state["animation"]
	is_paused = state.get("is_paused", false)
	is_looping = state.get("is_looping", false)
	paused_time = state.get("time", 0.0)

	var anim: Animation = animation_player.get_animation(last_animation_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR if is_looping else Animation.LOOP_NONE

	# Must call play() first so AnimationPlayer has an active animation to seek into
	animation_player.play(last_animation_name)
	animation_player.seek(paused_time, true)

	# Now pause if needed — play() then immediate pause() holds the frame
	if is_paused:
		animation_player.pause()


# ----------------------------
# Animation finished callback
# ----------------------------
func _on_animation_finished(anim_name: String) -> void:
	animation_finished.emit(anim_name)
