# ----------------------------
# main_scene.gd
# ----------------------------

extends Control

# ----------------------------
# Scene Nodes
# ----------------------------
@onready var main_scene_ui: Control = $MainSceneUI
@onready var dancer_viewport: SubViewport = $SubViewportContainer/DancerViewport
@onready var fullscreen_scene_instance: Control = $FullscreenScene

# ----------------------------
# Runtime state
# ----------------------------
var current_dancer: Node3D = null
var is_fullscreen: bool = false
var pending_term: String = ""

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("[DEBUG] MainScene ready")
	fullscreen_scene_instance.hide()  # ensure hidden at start

	# Connect GameManager navigation
	GameManager.nav_left.connect(Callable(self, "_on_nav_left"))
	GameManager.nav_right.connect(Callable(self, "_on_nav_right"))

	# Connect UI signals safely
	if main_scene_ui:
		if not main_scene_ui.is_connected("term_selected", Callable(self, "_on_term_selected")):
			main_scene_ui.connect("term_selected", Callable(self, "_on_term_selected"))
		if not main_scene_ui.is_connected("character_requested", Callable(self, "_on_character_selected")):
			main_scene_ui.connect("character_requested", Callable(self, "_on_character_selected"))
		if main_scene_ui.fullscreen_button:
			main_scene_ui.fullscreen_button.visible = false
			if not main_scene_ui.fullscreen_button.is_connected("pressed", Callable(self, "_on_fullscreen_button_pressed")):
				main_scene_ui.fullscreen_button.pressed.connect(Callable(self, "_on_fullscreen_button_pressed"))

	# Spawn last selected character from GameManager
	if GameManager.chosen_character != "":
		print("[DEBUG] Spawning last selected character:", GameManager.chosen_character)
		_on_character_selected(GameManager.chosen_character, true)

# ----------------------------
# Character spawning
# ----------------------------
func _on_character_selected(character_scene_path: String, is_restore: bool = false) -> void:
	# Remove previous dancer
	if current_dancer and current_dancer.is_inside_tree():
		current_dancer.queue_free()
		current_dancer = null

	# Load and instantiate new dancer
	var char_scene: PackedScene = load(character_scene_path)
	if not char_scene:
		push_error("Character scene not found!: " + character_scene_path)
		return

	current_dancer = char_scene.instantiate()
	dancer_viewport.add_child(current_dancer)

	# Play pending term if it exists
	if pending_term != "":
		_play_term(pending_term)
		pending_term = ""

# ----------------------------
# Term selection handler
# ----------------------------
func _on_term_selected(animation_name: String) -> void:
	print("[DEBUG] MainScene received term_selected:", animation_name)
	_play_term(animation_name)

	# Tell the UI a term is selected so the fullscreen button shows
	if main_scene_ui:
		main_scene_ui.has_selected_term = true
		main_scene_ui.show_fullscreen_button()

# ----------------------------
# Helper to play a term on the current dancer
# ----------------------------
func _play_term(animation_name: String) -> void:
	if current_dancer:
		current_dancer.play_animation(animation_name)
	else:
		pending_term = animation_name
		push_warning("Cannot play term: no dancer instantiated yet")

# ----------------------------
# Fullscreen button handler
# ----------------------------
func _on_fullscreen_button_pressed() -> void:
	if not current_dancer:
		push_warning("Cannot launch fullscreen: no dancer selected")
		return

	# Ensure the fullscreen scene has a setter method for the dancer
	if fullscreen_scene_instance.has_method("set_dancer"):
		fullscreen_scene_instance.set_dancer(current_dancer)

	# Show fullscreen scene
	fullscreen_scene_instance.show()
	_hide_recursive(main_scene_ui)  # hide main UI
	is_fullscreen = true
	print("[DEBUG] Fullscreen started")

# ----------------------------
# Exiting fullscreen
# ----------------------------
func _exit_fullscreen() -> void:
	if fullscreen_scene_instance:
		fullscreen_scene_instance.hide()

	_show_recursive(main_scene_ui)  # restore main UI
	is_fullscreen = false
	print("[DEBUG] Fullscreen exited")

# ----------------------------
# Navigation handlers
# ----------------------------
func _on_nav_left() -> void:
	_on_back_button_pressed()

func _on_nav_right() -> void:
	_on_index_button_pressed()

func _on_back_button_pressed() -> void:
	GameManager.selected_term = ""
	GameManager.last_played_animation = ""
	get_tree().call_deferred("change_scene_to_file", "res://Scenes/title_page.tscn")

func _on_index_button_pressed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://Scenes/index.tscn")

# ----------------------------
# Helpers to hide/show UI
# ----------------------------
func _hide_recursive(node: Node) -> void:
	if node is CanvasItem:
		node.visible = false
	for child in node.get_children():
		_hide_recursive(child)

func _show_recursive(node: Node) -> void:
	if node is CanvasItem:
		node.visible = true
	for child in node.get_children():
		_show_recursive(child)

# ----------------------------
# Input handler for F1 / nav
# ----------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				print("[DEBUG] LEFT pressed, calling _on_nav_left")
				_on_nav_left()
			KEY_RIGHT:
				print("[DEBUG] RIGHT pressed, calling _on_nav_right")
				_on_nav_right()
			KEY_F1:
				if main_scene_ui and main_scene_ui.fullscreen_container and main_scene_ui.fullscreen_container.visible:
					print("[DEBUG] F1 pressed → request fullscreen")
					_on_fullscreen_button_pressed()
				else:
					print("[DEBUG] F1 pressed but fullscreen container is hidden; ignoring")
