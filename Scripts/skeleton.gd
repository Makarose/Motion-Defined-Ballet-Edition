extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var skeleton: Skeleton3D = $Skeleton3D

func play_move(anim_name: String) -> void:
	if not anim_player:
		push_warning("AnimationPlayer missing!")
		return

	if not anim_player.has_animation(anim_name):
		push_warning("Animation not found: " + anim_name)
		return

	anim_player.play(anim_name)
	print("Playing animation:", anim_name)
