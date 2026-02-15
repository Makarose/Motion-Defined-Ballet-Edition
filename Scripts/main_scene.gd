# ----------------------------
# main_scene.gd
# ----------------------------

extends Control

# ----------------------------
# Scene Nodes
# ----------------------------
@onready var main_scene_ui: Control = $MainSceneUI
@onready var dancer_viewport: SubViewport = $SubViewportContainer/DancerViewport
@onready var fullscreen_scene_instance: Control = $FullscreenScene  # already in tree

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

	# Connect UI signals
	if main_scene_ui:
		main_scene_ui.connect("term_selected", Callable(self, "_on_term_selected"))
		main_scene_ui.connect("character_requested", Callable(self, "_on_character_selected"))
		main_scene_ui.connect("fullscreen_requested", Callable(self, "_on_fullscreen_button_pressed"))

	# Spawn last selected character from GameManager
	if GameManager.chosen_character != "":
		print("[DEBUG] Spawning last selected character:", GameManager.chosen_character)
		_on_character_selected(GameManager.chosen_character, true)


# ----------------------------
# Character spawning
# ----------------------------
func _on_character_selected(character_scene_path: String, is_restore: bool = false) -> void:
	#Remove previous dancer
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

	# Play pending term if one exists
	if pending_term != "":
		print("[DEBUG] Playing pending term:", pending_term)
		current_dancer.play_animation(pending_term)
		pending_term = ""


# ----------------------------
# Term selection handler
# ----------------------------
func _on_term_selected(animation_name: String) -> void:
	print("[DEBUG] MainScene received term_selected:", animation_name)

	if current_dancer:
		current_dancer.play_animation(animation_name)
		var fs_button = main_scene_ui.get_node_or_null("FullscreenButton")
		if fs_button:
			fs_button.visible = true
			main_scene_ui.current_dancer_node = current_dancer
	else:
		pending_term = animation_name

# ----------------------------
# Fullscreen button handler
# ----------------------------
func _on_fullscreen_button_pressed() -> void:
	if not current_dancer:
		push_warning("Cannot launch fullscreen: no dancer selected")
		return

	if fullscreen_scene_instance.has_method("set_dancer"):
		fullscreen_scene_instance.set_dancer(current_dancer)

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
