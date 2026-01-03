extends Node3D

# Class-level variable, visible in all functions
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var last_animation_name: String = ""

func _ready() -> void:
	animation_player.playback_active = true # ensures playback is active

func _process(_delta: float) -> void:
	# Update DancerState playback time live
	if animation_player.is_playing():
		DancerState.animation_time = animation_player.current_animation_position
		

func play_move(anim_name: String) -> void:
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		print("About to play animation:", anim_name)

		anim_player.stop()
		anim_player.play(anim_name)
		last_animation_name = anim_name

		# Minimal wiring to DancerState
		DancerState.current_animation = anim_name
		DancerState.is_playing = true
		DancerState.animation_time = 0.0
		DancerState.animation_length = anim_player.current_animation_length

		print("AnimationPlayer found animations:", anim_player.get_animation_list())
	else:
		push_warning("Animation not found: " + anim_name)

func replay_last_animation():
	if last_animation_name != "" and $AnimationPlayer.has_animation(last_animation_name):
		$AnimationPlayer.play(last_animation_name)
		DancerState.current_animation = last_animation_name
		DancerState.is_playing = true

func toggle_pause():
	$AnimationPlayer.playback_paused = !$AnimationPlayer.playback_paused
	DancerState.is_playing = !$AnimationPlayer.playback_paused
