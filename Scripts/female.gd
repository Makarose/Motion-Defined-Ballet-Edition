extends Node3D

# Class-level variable, visible in all functions
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var last_animation_name: String = ""
var is_paused := false
var paused_position := 0.0

func _ready() -> void:
	animation_player.playback_active = true # ensures playback is active

func _process(_delta: float) -> void:
	# Update DancerState playback time live
	if animation_player.is_playing():
		DancerState.animation_time = animation_player.current_animation_position
		

func play_move(anim_name: String) -> void:
	print("DEBUG: play_move called with:", anim_name)
	if animation_player and animation_player.has_animation(anim_name):
		print("About to play animation:", anim_name)

		animation_player.stop()
		animation_player.play(anim_name)
		last_animation_name = anim_name

		# Reset pause state
		is_paused = false
		paused_position = 0.0

		# Update DancerState
		DancerState.current_animation = anim_name
		DancerState.is_playing = true
		DancerState.animation_time = 0.0
		DancerState.animation_length = animation_player.current_animation_length

		print("AnimationPlayer found animations:", animation_player.get_animation_list())
	else:
		push_warning("Animation not found: " + anim_name)


func toggle_pause_or_resume() -> void:
	if animation_player == null:
		return

	if is_paused:
		animation_player.speed_scale = 1.0
		is_paused = false
		print("Animation resumed at:", animation_player.current_animation_position)
	else:
		animation_player.speed_scale = 0.0
		is_paused = true
		print("Animation paused at:", animation_player.current_animation_position)




func replay_last_animation() -> void:
	if last_animation_name == "":
		return
	if not animation_player.has_animation(last_animation_name):
		return

	# Reset pause state and speed
	is_paused = false
	paused_position = 0.0
	animation_player.speed_scale = 1.0  # <--- ensure it will play

	# Restart animation cleanly
	animation_player.stop()
	animation_player.play(last_animation_name)
	animation_player.seek(0.0, true) # start from beginning

	# Update DancerState fully
	DancerState.current_animation = last_animation_name
	DancerState.is_playing = true
	DancerState.animation_time = 0.0
	DancerState.animation_length = animation_player.current_animation_length

	print("Replayed animation from start:", last_animation_name)
