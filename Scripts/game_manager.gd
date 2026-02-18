# ----------------------------
# game_manager.gd
# ----------------------------
extends Node

# ----------------------------
# Signals
# ----------------------------
signal nav_left
signal nav_right

# ----------------------------
# Persistent state
# All cross-scene state lives here and nowhere else
# ----------------------------
var chosen_character: String = ""       # Scene path e.g. "res://Scenes/male.tscn"
var selected_term: String = ""          # Display name e.g. "Arabesque"
var selected_animation: String = ""     # Animation clip name e.g. "arabesque"
var selected_definition: String = ""    # Definition text for the selected term
var playback_time: float = 0.0          # Where in the animation we were
var is_paused: bool = false             # Was it paused when we left?
var is_looping: bool = false            # Was it looping?
var is_fullscreen: bool = false

# ----------------------------
# Database
# ----------------------------
@export var ballet_move_database: BalletMoveDatabase = preload("res://Definition Resources/ballet_moves_database.tres")

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	set_process_unhandled_input(true)

# ----------------------------
# Database helpers
# ----------------------------
func get_terms() -> Array:
	var term_list: Array = []
	if ballet_move_database:
		for move in ballet_move_database.moves:
			term_list.append(move.name)
	return term_list

func get_move_by_name(term: String) -> BalletMove:
	if not ballet_move_database:
		return null
	for move in ballet_move_database.moves:
		if normalize(move.name) == normalize(term):
			return move
	return null

# ----------------------------
# Save playback state from a dancer node
# Call this before any scene transition
# ----------------------------
func save_playback_state(dancer: Node3D) -> void:
	if dancer == null or not dancer.has_method("get_playback_state"):
		return
	var state: Dictionary = dancer.get_playback_state()
	playback_time = state.get("time", 0.0)
	is_paused = state.get("is_paused", false)
	is_looping = state.get("is_looping", false)

# ----------------------------
# Clear term state
# Call this when navigating back to title
# ----------------------------
func clear_term_state() -> void:
	selected_term = ""
	selected_animation = ""
	selected_definition = ""
	playback_time = 0.0
	is_paused = false
	is_looping = false

# ----------------------------
# Global input
# ----------------------------
func _shortcut_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	print("[GameManager] KEY pressed:", event.keycode, " is_action nav_left:", event.is_action("nav_left"), " ui_cancel:", event.is_action("ui_cancel"))
	
	if event.is_action("nav_left") and not is_fullscreen:
		get_viewport().set_input_as_handled()
		emit_signal("nav_left")
	elif event.is_action("nav_right") and not is_fullscreen:
		get_viewport().set_input_as_handled()
		emit_signal("nav_right")
	elif event.is_action("ui_cancel"):
		get_tree().quit()

# ----------------------------
# Normalization utilities
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
