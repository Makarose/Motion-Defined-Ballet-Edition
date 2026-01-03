extends Node

signal dancer_changed(dancer_id)
signal animation_changed(animation_name)
signal playback_position_changed(time, length)
signal playback_started
signal playback_stopped

var current_dancer_id: String = ""
var current_animation: String = ""
var animation_time: float = 0.0
var animation_length: float = 0.0
var is_playing: bool = false
