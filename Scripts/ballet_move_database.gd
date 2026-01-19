# ----------------------------
# ballet_move_database.gd
# ----------------------------

extends Resource
class_name BalletMoveDatabase

@export var moves: Array[BalletMove] = []

func get_move_by_term(term: String) -> BalletMove:
	for move in moves:
		if move.term == term:
			return move
	return null
