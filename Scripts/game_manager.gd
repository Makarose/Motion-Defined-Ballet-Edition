# ----------------------------
# game_manager.gd
# ----------------------------
extends Node

# ----------------------------
# Signals
# ----------------------------
signal nav_left
signal nav_right


var quit_dialog: ConfirmationDialog = null

# ----------------------------
# Persistent state
# ----------------------------
var chosen_character: String = ""
var selected_term: String = ""
var selected_animation: String = ""
var selected_definition: String = ""
var playback_time: float = 0.0
var is_paused: bool = false
var is_looping: bool = false
var is_fullscreen: bool = false
var music_player: AudioStreamPlayer = null
var music_enabled: bool = true

# ----------------------------
# Database
# ----------------------------
@export var ballet_move_database: BalletMoveDatabase = preload("res://Definition Resources/ballet_moves_database.tres")

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	set_process_unhandled_input(true)
	
	# Create quit confirmation dialog
	quit_dialog = ConfirmationDialog.new()
	quit_dialog.dialog_text = "Are you sure you want to quit?"
	quit_dialog.title = "Quit Application"
	quit_dialog.min_size = Vector2(500, 200)
	quit_dialog.confirmed.connect(_on_quit_confirmed)
	quit_dialog.canceled.connect(_on_quit_canceled)
	add_child(quit_dialog)
	
# Add white border only (transparent background)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0)  # Transparent background
	style_box.set_border_width_all(3)
	style_box.border_color = Color(1, 1, 1, 1)  # White border
	style_box.content_margin_bottom = 20  # Reduce bottom margin to move buttons up
	quit_dialog.add_theme_stylebox_override("panel", style_box)
	
	# Center the text horizontally and vertically + increase font size
	await get_tree().process_frame
	var label = quit_dialog.get_label()
	if label:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.stream = preload("res://MusicSounds/Rosalita_The_Piano_Says (looped).mp3")  # Change to your music file path
	music_player.autoplay = true
	add_child(music_player)
	music_player.play()
		
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
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	
	if event.ctrl_pressed and event.physical_keycode == KEY_LEFT and not is_fullscreen:
		get_viewport().set_input_as_handled()
		emit_signal("nav_left")
	elif event.ctrl_pressed and event.physical_keycode == KEY_RIGHT and not is_fullscreen:
		get_viewport().set_input_as_handled()
		emit_signal("nav_right")
	elif event.is_action("quit_app"):
		get_viewport().set_input_as_handled()
		quit_dialog.popup_centered()

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
	

# ----------------------------
# Music Toggle
# ----------------------------		
func toggle_music() -> void:
	print("[GameManager] toggle_music() called!")
	music_enabled = !music_enabled
	if music_enabled:
		music_player.play()
	else:
		music_player.stop()
	
# ----------------------------
# Quit Warnings
# ----------------------------	
func _on_quit_confirmed() -> void:
	get_tree().quit()

func _on_quit_canceled() -> void:
	pass  # Just close the dialog
