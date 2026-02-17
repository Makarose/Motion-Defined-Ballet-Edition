# ----------------------------
# ballet_move_database.gd
# ----------------------------
extends Resource
class_name BalletMoveDatabase

@export var moves: Array[BalletMove] = []

func get_move_by_name(term: String) -> BalletMove:
	for move in moves:
		if GameManager.normalize(move.name) == GameManager.normalize(term):
			return move
	return null
