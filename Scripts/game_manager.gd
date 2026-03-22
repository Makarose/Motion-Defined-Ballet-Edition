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
var previous_scene: String = ""
var show_instructions_on_startup: bool = true
var instructions_auto_opened: bool = false
var instructions_shown_this_session: bool = false

const SETTINGS_PATH = "user://settings.cfg"
# ----------------------------
# Database
# ----------------------------
@export var ballet_move_database: BalletMoveDatabase = preload("res://Definition Resources/ballet_moves_database.tres")

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:

	set_process_unhandled_input(true)
	load_settings()
	
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
	if OS.get_name() == "macOS":
		await get_tree().create_timer(0.2).timeout
	else:
		await get_tree().process.frame
	var label = quit_dialog.get_label()
	if label:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.stream = preload("res://MusicSounds/Rosalita_The_Piano_Says (looped).mp3")
	music_player.autoplay = true
	music_player.volume_db = -10.0
	add_child(music_player)
	
	# Connect finished signal to loop the music
	music_player.finished.connect(func(): music_player.play())
	
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
	print("[GameManager] Saved state - time:", playback_time, " is_paused:", is_paused, " is_looping:", is_looping)

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
	
	var nav_left = event.is_action("nav_left") if not is_macos() else (event.shift_pressed and event.physical_keycode == KEY_LEFT)
	var nav_right = event.is_action("nav_right") if not is_macos() else (event.shift_pressed and event.physical_keycode == KEY_RIGHT)
	
	if nav_left and not is_fullscreen:
		get_viewport().set_input_as_handled()
		emit_signal("nav_left")
	elif nav_right and not is_fullscreen:
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

# ----------------------------
# Settings
# ----------------------------
func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		show_instructions_on_startup = config.get_value("settings", "show_instructions_on_startup", true)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("settings", "show_instructions_on_startup", show_instructions_on_startup)
	config.save(SETTINGS_PATH)

# ----------------------------
# Platform Detection
# ----------------------------
func is_macos() -> bool:
	return OS.get_name() == "macOS"
	
func get_shortcut_text(action_name: String) -> String:
	match action_name:
		"music_toggle":
			return "CMD + C" if is_macos() else "F3"
		"open_instructions":
			return "CMD + V" if is_macos() else "F4"
		"quit_app":
			return "ESC" if is_macos() else "ESC"
		"nav_left":
			return "SHIFT + ←" if is_macos() else "Ctrl+←"
		"nav_right":
			return "SHIFT + →" if is_macos() else "Ctrl+→"
		"random":
			return "CMD + A" if is_macos() else "F5"
		"launch_fullscreen":
			return "CMD + Z" if is_macos() else "F1"
		"replay_from_main":
			return "CMD + X" if is_macos() else "F2"
		"exit_fullscreen":
			return "Tab" if is_macos() else "Tab"
		_:
			return ""
