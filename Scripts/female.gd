extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.playback_active = true # ensures playback is active

func play_move(anim_name: String) -> void:
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		print("▶ About to play animation:", anim_name)
		anim_player.stop()
		anim_player.play(anim_name)
		print("AnimationPlayer found animations:", anim_player.get_animation_list())
	else:
		push_warning("Animation not found: " + anim_name)
