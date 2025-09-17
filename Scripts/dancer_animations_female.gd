extends Node3D


@onready var armature: Node3D = $"Female Armature"
@onready var animation_player: AnimationPlayer = $"Female Armature/AnimationPlayer"
@export var database: BalletMoveDatabase

# Signal to infrom UI that an animation has started
signal animation_started(anim_name: String)

func _ready():
	# Find AnimationPlayer
	if not animation_player:
		animation_player = armature.get_node_or_null("AnimationPlayer")
	if animation_player:
		print("AnimationPlayer assigned! Animatation:", animation_player.get_animation_list())
	else:
		push_warning("AnimationPlayer not found in character!")

# Play a move by its term name
func play_move(term: String) -> void:
	if not database:
		push_warning("No BalletMoveDatabase assigned to character!")
		return
	
	# Look the move up in the database
	var move: BalletMove = null
	for m in database.moves:
		if m.name == term:
			move = m
			break

	if move == null:
		push_warning("Move '%s' not found in database!" % term)
		return
	
	if not animation_player:
		animation_player = armature.get_node_or_null("AnimationPlayer")
	if not animation_player:
		push_warning("AnimationPlayer not assigned on character!")
		return
	# Debug: list all available animations
	print("Available animations:", animation_player.get_animation_list())
	
	# Find animation that contains the move name (handles Blender prefixes)
	var anim_to_play := ""
	for anim_name in animation_player.get_animation_list():
		if anim_name.to_lower().ends_with(move.animation_name.to_lower()):
			anim_to_play = anim_name
			break

	if anim_to_play != "":
		animation_player.play(anim_to_play)
		emit_signal("animation_started", anim_to_play)
		print("Playing animation:", anim_to_play)
	else:
		push_warning("Animation '%s' not found in AnimationPlayer!" % move.animation_name)
