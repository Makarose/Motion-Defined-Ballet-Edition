@tool
extends Control

signal apply_button_pressed(checkbutton_state, distance)

func _on_apply_button_pressed():
	var cbs = %CheckButton.button_pressed
	var distance = %DistanceSpinBox.value
	apply_button_pressed.emit(cbs, distance)
