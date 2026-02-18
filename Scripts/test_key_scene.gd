extends Control

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	print("Physical keycode:", event.physical_keycode)
	print("Keycode:", event.keycode)
	print("Key label:", event.key_label)
	print("Unicode:", event.unicode)
	print("---")
