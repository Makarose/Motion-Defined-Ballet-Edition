# ----------------------------
# dancer_state.gd
# ----------------------------



extends Node

# ----------------------------
# Signals
# ----------------------------
signal dancer_changed(dancer_id: String)
signal animation_changed(animation_name: String)
signal playback_position_changed(time: float, length: float)
signal playback_started()
signal playback_stopped()

# ----------------------------
# State variables
# ----------------------------
var current_dancer_id: String = ""
var current_animation: String = ""
var animation_time: float = 0.0
var animation_length: float = 0.0
var is_playing: bool = false
var is_paused: bool = false
var is_looping: bool = false
var scrub_active: bool = false
var animation_speed: float = 0.95  # Optional: adjust if variable speed is needed

# ----------------------------
# Update playback info
# ----------------------------
func update_playback(current_time: float, total_length: float, playing: bool, paused: bool) -> void:
	animation_time = current_time
	animation_length = total_length
	is_playing = playing
	is_paused = paused
	emit_signal("playback_position_changed", animation_time, animation_length)

# ----------------------------
# Set current animation
# ----------------------------
func set_animation(animation_name: String) -> void:
	if current_animation == animation_name:
		return
	current_animation = animation_name
	emit_signal("animation_changed", animation_name)

# ----------------------------
# Set current dancer
# ----------------------------
func set_dancer(dancer_id: String) -> void:
	if current_dancer_id == dancer_id:
		return
	current_dancer_id = dancer_id
	emit_signal("dancer_changed", dancer_id)

# ----------------------------
# Playback notifications
# ----------------------------
func notify_playback_started() -> void:
	emit_signal("playback_started")

func notify_playback_stopped() -> void:
	emit_signal("playback_stopped")

# ----------------------------
# Reset state (utility)
# ----------------------------
func reset_state() -> void:
	current_dancer_id = ""
	current_animation = ""
	animation_time = 0.0
	animation_length = 0.0
	is_playing = false
	is_paused = false
	is_looping = false
	scrub_active = false
