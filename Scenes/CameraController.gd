extends Camera3D

var move_speed := 0.5
var zoom_speed := 0.5

func move_left():  translate(Vector3(-move_speed, 0, 0))
func move_right(): translate(Vector3(move_speed, 0, 0))
func move_up():    translate(Vector3(0, move_speed, 0))
func move_down():  translate(Vector3(0, -move_speed, 0))
func zoom_in():    translate(Vector3(0, 0, -zoom_speed))
func zoom_out():   translate(Vector3(0, 0, zoom_speed))
