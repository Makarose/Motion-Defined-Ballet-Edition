# ----------------------------
# main_scene_ui.gd
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
@onready var item_list: ItemList = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel
@onready var title_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerTitle/TitleLabel

@onready var fullscreen_container: MarginContainer = $CanvasLayer/Fullscreen
@onready var fullscreen_button: TextureButton = $CanvasLayer/Fullscreen/HBoxContainer/FullscreenButton

# ----------------------------
# Resources
# ----------------------------
@export var database: BalletMoveDatabase

# ----------------------------
# Runtime state
# ----------------------------
var current_index := -1
var clear_timer: Timer
var has_selected_term := false

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("[DEBUG] MainScene UI ready")
	
	has_selected_term = false

	# Force fullscreen container hidden at start
	if fullscreen_container:
		fullscreen_container.visible = false

	# LineEdit signals
	if not search_bar.text_changed.is_connected(Callable(self, "_on_line_edit_text_changed")):
		search_bar.text_changed.connect(Callable(self, "_on_line_edit_text_changed"))

	if not search_bar.text_submitted.is_connected(Callable(self, "_on_line_edit_text_submitted")):
		search_bar.text_submitted.connect(Callable(self, "_on_line_edit_text_submitted"))

	if not search_bar.gui_input.is_connected(Callable(self, "_on_search_bar_gui_input")):
		search_bar.gui_input.connect(Callable(self, "_on_search_bar_gui_input"))

	search_bar.grab_focus()
	print("[DEBUG] Connected LineEdit signals")

	# ItemList signals
	if not item_list.item_selected.is_connected(Callable(self, "_on_item_selected")):
		item_list.item_selected.connect(Callable(self, "_on_item_selected"))

	item_list.visible = false

	# Clear timer
	clear_timer = Timer.new()
	clear_timer.one_shot = true
	clear_timer.wait_time = 0.8
	clear_timer.timeout.connect(Callable(self, "_clear_search_now"))
	add_child(clear_timer)
	print("[DEBUG] Timer created and connected")

	# GameManager navigation signals
	if not GameManager.nav_left.is_connected(Callable(self, "_on_nav_left")):
		GameManager.nav_left.connect(Callable(self, "_on_nav_left"))

	if not GameManager.nav_right.is_connected(Callable(self, "_on_nav_right")):
		GameManager.nav_right.connect(Callable(self, "_on_nav_right"))

	print("[DEBUG] Connected GameManager nav_left/right signals")

	# Database fallback
	if not database:
		database = load("res://Definition Resources/ballet_moves_database.tres")
		print("[DEBUG] Loaded database")

	# Ensure unhandled input works even if LineEdit is focused
	set_process_input(true)
	set_process_unhandled_input(true)
	print("[DEBUG] set_process_unhandled_input(true) called")



# ----------------------------
# Search / Item List
# ----------------------------
func _on_line_edit_text_changed(new_text: String) -> void:
	print("[DEBUG] _on_line_edit_text_changed:", new_text)
	item_list.clear()
	current_index = -1

	if new_text == "":
		item_list.visible = false
		return

	var normalized_input = GameManager.normalize(new_text)
	for balletmove in database.moves:
		if GameManager.normalize(balletmove.name).begins_with(normalized_input):
			item_list.add_item(balletmove.name)

	item_list.visible = item_list.get_item_count() > 0

func _on_item_selected(index: int) -> void:
	print("[DEBUG] _on_item_selected:", index)
	current_index = index
	_select_item(index)

func _on_search_bar_gui_input(event: InputEvent) -> void:
	print("\t[DEBUG] _on_search_bar_gui_input:", event)

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DOWN:
				if current_index < item_list.get_item_count() - 1:
					current_index += 1
					item_list.select(current_index)
					item_list.ensure_current_is_visible()
					print("\t\t[DEBUG] KEY_DOWN, current_index=", current_index)
			KEY_UP:
				if current_index > 0:
					current_index -= 1
					item_list.select(current_index)
					item_list.ensure_current_is_visible()
					print("\t\t[DEBUG] KEY_UP, current_index=", current_index)
			KEY_ENTER, KEY_KP_ENTER:
				if current_index >= 0:
					print("\t\t[DEBUG] ENTER, selecting item at index=", current_index)
					_select_item(current_index)

		# Force left/right navigation even if LineEdit has focus
		if event.keycode == KEY_LEFT:
			print("\t\t[DEBUG] LEFT pressed, forwarding nav_left")
			_on_nav_left()
		elif event.keycode == KEY_RIGHT:
			print("\t\t[DEBUG] RIGHT pressed, forwarding nav_right")
			_on_nav_right()


func _on_line_edit_text_submitted(_text: String) -> void:
	print("[DEBUG] _on_line_edit_text_submitted:", _text)
	if current_index >= 0:
		_select_item(current_index)

func _select_item(index: int) -> void:
	if index < 0 or index >= item_list.get_item_count():
		return

	var selected_name = item_list.get_item_text(index)
	var move: BalletMove = null

	for balletmove in database.moves:
		if GameManager.normalize(balletmove.name) == GameManager.normalize(selected_name):
			move = balletmove
			break

	if not move:
		return

	title_label.text = move.name
	definition_label.text = move.definition
	search_bar.text = selected_name
	item_list.visible = false
	search_bar.grab_focus()
	clear_timer.start()

	has_selected_term = true

	# Show fullscreen button only if animation exists
	if move.animation_name.strip_edges() != "":
		emit_signal("term_selected", move.animation_name)
		# DO NOT launch fullscreen automatically
		# current_dancer_node = GameManager.current_dancer
		show_fullscreen_button()
	else:
		hide_fullscreen_button()


# ----------------------------
# Clear search
# ----------------------------
func _clear_search_now() -> void:
	print("[DEBUG] _clear_search_now")
	search_bar.text = ""
	current_index = -1
	item_list.clear()
	item_list.visible = false


# ----------------------------
# Fullscreen & Character Controls
# ----------------------------
func show_fullscreen_button() -> void:
	# Only show if a term with animation is selected
	if has_selected_term and fullscreen_container:
		_show_fullscreen_controls(true)

func hide_fullscreen_button() -> void:
	has_selected_term = false
	_show_fullscreen_controls(false)

func _show_fullscreen_controls(show_container: bool) -> void:
	if not fullscreen_container:
		push_error("Fullscreen container is NULL")
		return
	fullscreen_container.visible = show_container

func _on_fullscreen_pressed() -> void:
	print("[DEBUG] Fullscreen requested")

	emit_signal("fullscreen_requested")


# ----------------------------
# Fullscreen keyboard trigger & navigation
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
				if fullscreen_container and fullscreen_container.visible:
					print("[DEBUG] F1 pressed → request fullscreen")
					emit_signal("fullscreen_requested")
				else:
					print("[DEBUG] F1 pressed but fullscreen container is hidden; ignoring")


# ----------------------------
# Navigation (scene-specific handlers for GameManager signals)
# ----------------------------
func _on_nav_left() -> void:
	print("[DEBUG] _on_nav_left triggered")
	_on_back_button_pressed()  # just do the nav, don’t check fullscreen

func _on_nav_right() -> void:
	print("[DEBUG] _on_nav_right triggered")
	_on_index_button_pressed()  # just do the nav, don’t check fullscreen


# ----------------------------
# Actual scene navigation
# ----------------------------
func _on_back_button_pressed() -> void:
	print("[DEBUG] Back button triggered")
	GameManager.selected_term = ""
	GameManager.last_played_animation = ""
	get_tree().call_deferred(
		"change_scene_to_file",
		"res://Scenes/title_page.tscn"
)

func _on_index_button_pressed() -> void:
	print("[DEBUG] Index button triggered")
	get_tree().call_deferred(
		"change_scene_to_file",
		"res://Scenes/index.tscn"
)
