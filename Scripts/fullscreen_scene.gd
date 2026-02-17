# ----------------------------
# fullscreen_scene.gd
# ----------------------------
extends Control

# ----------------------------
# Signals emitted up to MainScene
# ----------------------------
signal exit_requested
signal character_changed(scene_path: String)

# ----------------------------
# Nodes
# ----------------------------
@onready var video_controls: Control = $VideoControls
@onready var dancer_viewport: SubViewport = $SubViewportContainer/DancerViewport

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	# Wire up signals from VideoControls
	video_controls.exit_requested.connect(_on_exit_requested)
	video_controls.character_requested.connect(_on_character_requested)


# ----------------------------
# Called by MainScene when fullscreen is shown
# Passes the current dancer down to VideoControls
# ----------------------------
func set_dancer(dancer: Node3D) -> void:
	if not dancer:
		push_warning("[FullscreenScene] No dancer passed to set_dancer")
		return
	video_controls.set_dancer(dancer)
	print("[FullscreenScene] Dancer set")


# ----------------------------
# Exit requested from VideoControls
# ----------------------------
func _on_exit_requested() -> void:
	emit_signal("exit_requested")


# ----------------------------
# Character swap requested from VideoControls
# ----------------------------
func _on_character_requested(scene_path: String) -> void:
	emit_signal("character_changed", scene_path)
