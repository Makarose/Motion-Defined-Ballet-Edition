extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func play_move(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		push_warning("animation not found: " + anim_name)
