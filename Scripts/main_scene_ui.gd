# ----------------------------
# ui_scene.gd (refactored)
# ----------------------------

extends Control

# ----------------------------
# Signals
# ----------------------------
signal term_selected(animation_name: String)
signal character_requested(character_scene_path: String)
signal fullscreen_requested()

# ----------------------------
# UI Nodes
# ----------------------------
@onready var search_bar: LineEdit = $CanvasLayer/Search/MarginContainerText/VBoxContainer/LineEdit
@onready var item_list = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel
@onready var title_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerTitle/TitleLabel
@onready var fullscreen_button: Button = $CanvasLayer/Fullscreen/FullscreenButton
@onready var male_button: Button = $CanvasLayer/Fullscreen/MaleButton
@onready var female_button: Button = $CanvasLayer/Fullscreen/FemaleButton

# ----------------------------
# Resources
# ----------------------------
@export var database: BalletMoveDatabase

# ----------------------------
# Runtime state
# ----------------------------
var current_index := -1
var clear_timer: Timer
var has_selected_term: bool = false

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	_show_fullscreen_controls(false)

	search_bar.text_changed.connect(_on_search_text_changed)
	search_bar.gui_input.connect(_on_search_bar_gui_input)
	search_bar.connect("text_submitted", Callable(self, "_on_search_bar_entered"))
	item_list.item_selected.connect(_on_item_selected)
	item_list.visible = false

	clear_timer = Timer.new()
	clear_timer.one_shot = true
	clear_timer.wait_time = 0.8
	clear_timer.connect("timeout", Callable(self, "_clear_search_now"))
	add_child(clear_timer)

	# Connect buttons
	if fullscreen_button:
		fullscreen_button.pressed.connect(Callable(self, "_on_fullscreen_pressed"))
	if male_button:
		male_button.pressed.connect(Callable(self, "_on_male_pressed"))
	if female_button:
		female_button.pressed.connect(Callable(self, "_on_female_pressed"))

	if not database:
		database = load("res://Definition Resources/ballet_moves_database.tres")

# ----------------------------
# Search / Item List
# ----------------------------
func _on_search_text_changed(new_text: String) -> void:
	item_list.clear()
	current_index = -1
	if new_text == "":
		item_list.visible = false
		return

	var normalized_input = normalize(new_text)
	for balletmove in database.moves:
		if normalize(balletmove.name).begins_with(normalized_input):
			item_list.add_item(balletmove.name)

	item_list.visible = item_list.get_item_count() > 0

func _on_item_selected(index: int) -> void:
	current_index = index
	_select_item(index)

func _on_search_bar_gui_input(event: InputEvent) -> void:
	# left unchanged as requested
	if not item_list.visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DOWN:
				if current_index < item_list.get_item_count() - 1:
					current_index += 1
					item_list.select(current_index)
					item_list.ensure_current_is_visible()
			KEY_UP:
				if current_index > 0:
					current_index -= 1
					item_list.select(current_index)
					item_list.ensure_current_is_visible()
			KEY_ENTER, KEY_KP_ENTER:
				if current_index >= 0 and current_index < item_list.get_item_count():
					_select_item(current_index)

func _on_search_bar_entered(new_text: String) -> void:
	if current_index >= 0 and current_index < item_list.get_item_count():
		_select_item(current_index)
		return

	var normalized_input = normalize(new_text)
	for i in range(item_list.get_item_count()):
		if normalize(item_list.get_item_text(i)) == normalized_input:
			_select_item(i)
			return

func _select_item(index: int) -> void:
	if index < 0 or index >= item_list.get_item_count():
		return

	var selected_move_name = item_list.get_item_text(index)
	var move_resource: BalletMove = null
	var norm_selected = normalize(selected_move_name)

	for balletmove in database.moves:
		if normalize(balletmove.name) == norm_selected:
			move_resource = balletmove
			break

	if move_resource == null:
		return

	title_label.set_text(move_resource.name)
	definition_label.set_text(move_resource.definition)
	search_bar.text = selected_move_name
	item_list.visible = false
	search_bar.grab_focus()
	clear_timer.start()

	has_selected_term = true

	var animation_name = move_resource.animation_name.strip_edges()
	if animation_name != "":
		emit_signal("term_selected", animation_name)

func _clear_search_now() -> void:
	search_bar.text = ""
	current_index = -1
	item_list.clear()
	item_list.visible = false

# ----------------------------
# Fullscreen & Character Buttons
# ----------------------------
func _on_fullscreen_pressed() -> void:
	emit_signal("fullscreen_requested")

func _on_male_pressed() -> void:
	emit_signal("character_requested", "res://Scenes/male.tscn")

func _on_female_pressed() -> void:
	emit_signal("character_requested", "res://Scenes/female.tscn")

# ----------------------------
# Helpers
# ----------------------------
func strip_accents(text: String) -> String:
	var mapping = {
		"á":"a","à":"a","ä":"a","â":"a","ã":"a","å":"a","Á":"A","À":"A","Â":"A","Ä":"A","Ã":"A","Å":"A",
		"é":"e","è":"e","ë":"e","ê":"e","É":"E","È":"E","Ê":"E","Ë":"E",
		"í":"i","ì":"i","ï":"i","î":"i","Í":"I","Ì":"I","Ï":"I","Î":"I",
		"ó":"o","ò":"o","ö":"o","ô":"o","õ":"o","Ó":"O","Ò":"O","Ö":"O","Ô":"O","Õ":"O",
		"ú":"u","ù":"u","ü":"u","û":"u","Ú":"U","Ù":"U","Û":"U","Ü":"U",
		"ñ":"n","Ñ":"N","ç":"c","Ç":"C"
	}
	var result := ""
	for c in text:
		result += mapping.get(c, c)
	return result

func normalize(text: String) -> String:
	return strip_accents(text).to_lower()

func _show_fullscreen_controls(visible: bool) -> void:
	if fullscreen_button and fullscreen_button.is_inside_tree():
		fullscreen_button.visible = visible


# ----------------------------
# Navigational Buttons
# ----------------------------
func _on_back_button_pressed() -> void:
	GameManager.selected_term = ""
	GameManager.last_played_animation = ""
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")

func _on_index_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/index.tscn")
