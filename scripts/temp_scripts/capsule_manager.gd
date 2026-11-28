# helper script for moving the capsule
extends MeshInstance3D

var move_weight: float = 0.2
var target_pos: Vector3 = Vector3.ZERO

# Offset between true north and your scene's -Z axis (degrees).
# 0 if the campus model is aligned so that -Z points north.
@export var north_offset_deg: float = 0.0

# initialize
func _ready() -> void:
	# setup variables
	target_pos = position
	
	# setup connections
	PedestrianDeadReckoning.step_occured.connect(step_occured)

# on step occured
func step_occured(step: Dictionary) -> void:
	var h := deg_to_rad(step.heading + north_offset_deg)
	# compass heading: 0 = north (-Z), 90 = east (+X), clockwise
	var added_pos := Vector3(step.length * sin(h), 0.0, -step.length * cos(h))
	target_pos += added_pos
	rotation.y = -h   # optional: make the capsule face its walking direction
	
	# get closest path point
	var closest_point = PathManager.get_closest_point(target_pos,5)
	if closest_point != Vector3.ZERO:
		target_pos = closest_point

# lerp to target position
func _process(delta: float) -> void:
	position = position.lerp(target_pos, 1.0 - exp(-12.0 * delta))
