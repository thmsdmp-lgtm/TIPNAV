# script for managing map card functionalities
extends Panel

@export var button:Button
@export var camera_pivot:Node3D

# initialize
func _ready() -> void:
	if not button: return
	button.pressed.connect(Callable(%tab_bar,"switch_tab").bind("map"))

# rotate model
func _process(delta: float) -> void:
	if not camera_pivot: return
	camera_pivot.rotation.y += .004
