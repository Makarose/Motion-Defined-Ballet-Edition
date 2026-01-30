# ----------------------------
# game_manager.gd
# ----------------------------

extends Node

signal nav_left
signal nav_right

@export var ballet_move_database: BalletMoveDatabase = preload("res://Definition Resources/ballet_moves_database.tres")

var chosen_character: String = ""       # Last selected character
var selected_term: String = ""          # Last selected term
var last_played_animation: String = ""  # Last animation played globally
var arrived_from_title_page := false

func _ready() -> void:
	set_process_unhandled_input(true)  # Enable _unhandled_input processing


# ----------------------------
# Ballet moves
# ----------------------------
func get_terms() -> Array:
	var term_list: Array = []
	if ballet_move_database:
		for move in ballet_move_database.moves:
			term_list.append(move.name)
	return term_list

func play_move_on_dancer(dancer: Node3D, term: String) -> void:
	if dancer and dancer.has_method("play_move"):
		dancer.play_move(term)
		last_played_animation = term
		selected_term = term


# ----------------------------
# Global input handling
# ----------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("quit_app"):
			get_tree().quit()
			return

		var current = get_tree().current_scene
		if current and current.name == "TitlePage":
			return

		if get_tree().get_nodes_in_group("blocks_nav").size() > 0:
			return

		var focus = get_viewport().gui_get_focus_owner()
		if focus is LineEdit:
			return

		if event.is_action_pressed("ui_left"):
			emit_signal("nav_left")
			return
		if event.is_action_pressed("ui_right"):
			emit_signal("nav_right")
			return


# ----------------------------
# Back button helper
# ----------------------------
func _on_back_button_pressed() -> void:
	# Indicate that the next character selected should start fresh
	arrived_from_title_page = true

	# Go back to the title page
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")


# ----------------------------
# Normalization Helpers
# ----------------------------
func strip_accents(text: String) -> String:
	var mapping = {
		"á":"a","à":"a","ä":"a","â":"a","ã":"a","å":"a",
		"Á":"A","À":"A","Â":"A","Ä":"A","Ã":"A","Å":"A",
		"é":"e","è":"e","ë":"e","ê":"e",
		"É":"E","È":"E","Ê":"E","Ë":"E",
		"í":"i","ì":"i","ï":"i","î":"i",
		"Í":"I","Ì":"I","Ï":"I","Î":"I",
		"ó":"o","ò":"o","ö":"o","ô":"o","õ":"o",
		"Ó":"O","Ò":"O","Ö":"O","Ô":"O","Õ":"O",
		"ú":"u","ù":"u","ü":"u","û":"u",
		"Ú":"U","Ù":"U","Û":"U","Ü":"U",
		"ñ":"n","Ñ":"N","ç":"c","Ç":"C"
	}
	var result := ""
	for c in text:
		result += mapping.get(c, c)
	return result

func normalize(text: String) -> String:
	return strip_accents(text).to_lower()
