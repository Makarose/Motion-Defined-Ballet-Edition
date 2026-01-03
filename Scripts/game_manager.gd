extends Node

@export var ballet_move_database: BalletMoveDatabase = preload("res://Definition Resources/ballet_moves_database.tres")

var chosen_character: String = ""       # Last selected character
var selected_term: String = ""          # Last selected term
var last_played_animation: String = ""  # Last animation played globally

# ----------------------------
# Ballet moves
# ----------------------------
func get_terms() -> Array:
	var term_list: Array = []
	if ballet_move_database:
		for move in ballet_move_database.moves:
			term_list.append(move.name)
	return term_list

# Play a move on a dancer and track it
func play_move_on_dancer(dancer: Node3D, term: String) -> void:
	if dancer and dancer.has_method("play_move"):
		dancer.play_move(term)
		last_played_animation = term
		selected_term = term

# ----------------------------
# Global input
# ----------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit_app"): # ← Esc
		get_tree().quit()
