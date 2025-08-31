extends Node2D

@export var character_instance: Node = null

func _ready():
	var database = load("res://Definition Resources/ballet_moves_database.tres")
	for move in database.moves:
		print("Move:", move.name, "Definition:", move.definition)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
