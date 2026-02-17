# ----------------------------
# search_line_edit.gd
# ----------------------------
extends LineEdit
class_name SearchLineEdit

signal nav_left_pressed
signal nav_right_pressed
signal move_up
signal move_down
signal item_confirmed
signal fullscreen_pressed

func _ready() -> void:
	set_process_unhandled_key_input(true)

func _unhandled_key_input(event: InputEvent) -> void:
	print("[SearchLineEdit] _unhandled_key_input keycode:", event.keycode, " LEFT=", KEY_LEFT)
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_LEFT:
			accept_event()
			emit_signal("nav_left_pressed")
		KEY_RIGHT:
			accept_event()
			emit_signal("nav_right_pressed")
		KEY_UP:
			accept_event()
			emit_signal("move_up")
		KEY_DOWN:
			accept_event()
			emit_signal("move_down")
		KEY_ENTER, KEY_KP_ENTER:
			accept_event()
			emit_signal("item_confirmed")
		KEY_F1:
			accept_event()
			emit_signal("fullscreen_pressed")
