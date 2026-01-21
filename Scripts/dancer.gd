# ----------------------------
# dancer.gd
# ----------------------------



extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# ----------------------------
# Playback state
# ----------------------------
var last_animation_name: String = ""
var is_paused: bool = false
var is_looping: bool = false
var paused_time: float = 0.0
var is_scrubbing: bool = false

# ----------------------------
# Play animation (resumes if paused)
# ----------------------------
func play_animation(anim_name: String) -> void:
	# Find matching animation ignoring case and accents
	var target_name: String = ""
	for anim in animation_player.get_animation_list():
		if GameManager.normalize(anim) == GameManager.normalize(anim_name):
			target_name = anim
			break

	if target_name == "":
		print("Animation not found:", anim_name)
		return
		
	# Set playback state
	last_animation_name = target_name
	is_looping = false

	# If paused, resume from paused_time
	if is_paused and paused_time > 0.0:
		is_paused = false
		animation_player.play(last_animation_name)
		animation_player.seek(paused_time, true)
		return

	# Otherwise, start from beginning
	is_paused = false
	paused_time = 0.0

	var anim: Animation = animation_player.get_animation(target_name)
	if anim != null:
		anim.loop_mode = Animation.LOOP_NONE

	animation_player.play(target_name)
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
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR

	animation_player.play(last_animation_name)
	animation_player.seek(0.0, true)

# ----------------------------
# Replay last animation from start
# ----------------------------
func replay_last_animation() -> void:
	if last_animation_name == "":
		return

	is_looping = false
	is_paused = false
	paused_time = 0.0

	var anim: Animation = animation_player.get_animation(last_animation_name)
	if anim != null:
		anim.loop_mode = Animation.LOOP_NONE

	animation_player.play(last_animation_name)
	animation_player.seek(0.0, true)

# ----------------------------
# Pause at current frame
# ----------------------------
func pause_animation() -> void:
	if animation_player.is_playing():
		is_paused = true
		# Capture the exact current frame
		paused_time = animation_player.current_animation_position
		# Stop the animation to freeze it visually
		animation_player.stop()
		animation_player.seek(paused_time, true)

# ----------------------------
# Resume from paused frame
# ----------------------------
func resume_animation() -> void:
	if last_animation_name == "":
		return
	if not is_paused:
		return

	is_paused = false
	animation_player.play(last_animation_name)
	animation_player.seek(paused_time, true)

# ----------------------------
# Stop animation
# ----------------------------
func stop_animation() -> void:
	if last_animation_name == "":
		return

	is_looping = false
	is_paused = false
	paused_time = 0.0

	var anim: Animation = animation_player.get_animation(last_animation_name)
	if anim != null:
		anim.loop_mode = Animation.LOOP_NONE

	animation_player.stop()
	animation_player.seek(0.0, true)

# ----------------------------
# Scrubbing
# ----------------------------
func seek_to_time(time_sec: float) -> void:
	if last_animation_name == "":
		return
	if animation_player.has_animation(last_animation_name):
		is_scrubbing = true
		animation_player.seek(time_sec, true)

func resume_from_scrub() -> void:
	if last_animation_name == "":
		return

	is_scrubbing = false
	if not is_paused:
		animation_player.play(last_animation_name)
		animation_player.seek(animation_player.current_animation_position, true)

# ----------------------------
# Save / restore playback state
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
		if anim != null:
			state["length"] = anim.length
			state["time"] = animation_player.current_animation_position

	return state

func apply_playback_state(state: Dictionary) -> void:
	if not state.has("animation") or state["animation"] == "":
		return
	if not animation_player.has_animation(state["animation"]):
		return

	last_animation_name = state["animation"]
	is_paused = state.get("is_paused", false)
	is_looping = state.get("is_looping", false)
	paused_time = state.get("time", 0.0)

	var anim: Animation = animation_player.get_animation(last_animation_name)
	if anim != null:
		if is_looping:
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE

	if is_paused:
		animation_player.stop()
		animation_player.seek(paused_time, true)
	else:
		animation_player.play(last_animation_name)
		animation_player.seek(paused_time, true)
