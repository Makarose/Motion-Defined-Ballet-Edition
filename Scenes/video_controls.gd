extends Control  # or Node, depending on your root

# Reference to the camera that the UI will control
var camera: Camera3D

var move_speed := 0.5
var zoom_speed := 0.5

func move_left():
	camera.translate(Vector3(-move_speed, 0, 0))
func move_right():
	camera.translate(Vector3(move_speed, 0, 0))
func move_up():
	camera.translate(Vector3(0, move_speed, 0))
func move_down():
	camera.translate(Vector3(0, -move_speed, 0))
func zoom_in():
	camera.translate(Vector3(0, 0, -zoom_speed))
func zoom_out():
	camera.translate(Vector3(0, 0, zoom_speed))
