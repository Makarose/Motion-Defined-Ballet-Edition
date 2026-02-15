# ----------------------------
# fullscreenScene.gd
# ----------------------------

extends Control

# ----------------------------
# Scene Nodes
# ----------------------------
@onready var video_controls: Control = $VideoControls
@onready var character_slot: Node3D = $SubViewportContainer/DancerViewport/CharacterSlot

# ----------------------------
# Runtime state
# ----------------------------
var dancer_node: Node3D = null

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	hide()  # ensure hidden initially

# ----------------------------
# Set dancer
# ----------------------------
func set_dancer(dancer: Node3D) -> void:
	if not dancer:
		push_warning("No dancer passed to fullscreen scene")
		return

	# Reparent dancer into this fullscreen scene
	if dancer.get_parent():
		dancer.get_parent().remove_child(dancer)
	character_slot.add_child(dancer)
	dancer_node = dancer
	print("[DEBUG] Dancer assigned to fullscreen scene")
