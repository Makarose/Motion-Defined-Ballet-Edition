extends Node

@export var ballet_move_database: BalletMoveDatabase = preload("res://Definition Resources/ballet_moves_database.tres")

var chosen_character : String = "" # Last selected character
var selected_term: String = "" # Last selecetd term
var pending_animation: String = "" # Animation to play when back in main scene

func get_terms() -> Array:
	var term_list: Array = []
	if ballet_move_database:
		for move in ballet_move_database.moves:
			term_list.append(move.name)
	return term_list
