extends Node

signal dancer_changed(dancer_id)
signal animation_changed(animation_name)
signal playback_position_changed(time, length)
signal playback_started
signal playback_stopped

var current_dancer_id: String = ""
var current_animation: String = ""
var animation_time: float = 0.0
var animation_length: float = 0.0
var is_playing: bool = false
var paused_position: float = 0.0
var is_paused: bool = false
var loop_enabled := false

# Automatically find the AnimationPlayer anywhere under this node
var anim_player: AnimationPlayer = null
var animation_speed: float = 0.95  # Default speed (adjustable)

func _ready():
	# Search for AnimationPlayer in the node hierarchy
	anim_player = get_node_or_null("AnimationPlayer")
	if not anim_player:
		anim_player = find_animation_player(self)
	
	if not anim_player:
		push_warning("No AnimationPlayer found in dancer scene!")

func find_animation_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var result = find_animation_player(child)
		if result:
			return result
	return null

func _process(delta: float) -> void:
	if is_playing and anim_player and not is_paused:
		# Just read current position; do not manually increment
		animation_time = anim_player.current_animation_position
		animation_length = anim_player.current_animation_length

		# Stop at end if not looping
		if animation_time >= animation_length and not loop_enabled:
			is_playing = false
			emit_signal("playback_stopped")
			print("DEBUG: playback stopped")

		emit_signal("playback_position_changed", animation_time, animation_length)

# Seek to a specific time in the animation
func seek(time: float):
	if not anim_player or not current_animation:
		return
	animation_time = clamp(time, 0.0, animation_length)
	anim_player.seek(animation_time, true)
	emit_signal("playback_position_changed", animation_time, animation_length)

# Play a move by name
func play_move(move_name: String):
	if not anim_player:
		push_warning("Cannot play move; AnimationPlayer not found!")
		return

	anim_player.speed_scale = animation_speed  # AnimationPlayer controls timing now

	if current_animation != move_name:
		current_animation = move_name
		animation_length = anim_player.get_animation(move_name).length if anim_player.has_animation(move_name) else 0.0
		animation_time = 0.0
		anim_player.play(move_name)
		is_playing = true
		is_paused = false
		emit_signal("animation_changed", move_name)
		emit_signal("playback_started")
	else:
		# Restart the same animation if already playing
		anim_player.play(move_name)
		animation_time = 0.0
		is_playing = true
		is_paused = false
		emit_signal("animation_changed", move_name)
		emit_signal("playback_started")

# Pause the animation
func pause():
	if is_playing and not is_paused and anim_player:
		is_paused = true
		paused_position = animation_time
		anim_player.stop()

# Resume the animation
func resume():
	if is_playing and is_paused and anim_player:
		is_paused = false
		anim_player.play(current_animation)
		anim_player.seek(paused_position, true)
