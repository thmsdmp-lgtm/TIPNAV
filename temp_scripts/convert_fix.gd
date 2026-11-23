@tool
extends Node

@export var target: Control

@export_tool_button("Convert Controls", "Reload")
var convert_button = convert_controls


func convert_controls() -> void:
	if not is_instance_valid(target):
		push_warning("Please assign a target Control first.")
		return

	process_control(target)

	print("Control conversion complete.")


func process_control(control: Control) -> void:
	# Process descendants first
	for child in control.get_children():
		if child is Control:
			process_control(child)

	# Resize controls with zero dimensions
	if control.size == Vector2.ZERO:
		resize_to_contents(control)

	# Convert children into proportional anchors
	for child in control.get_children():
		if child is Control:
			convert_to_anchors(child)


func resize_to_contents(control: Control) -> void:
	var children := control.get_children()

	if children.is_empty():
		return

	var bounds := Rect2()
	var first := true

	for child in children:
		if child is Control:
			var rect := Rect2(child.position, child.size)

			if first:
				bounds = rect
				first = false
			else:
				bounds = bounds.merge(rect)

	if first:
		return

	# Resize parent to contain its children
	control.position += bounds.position
	control.size = bounds.size

	# Move children relative to the new parent origin
	for child in children:
		if child is Control:
			child.position -= bounds.position


func convert_to_anchors(control: Control) -> void:
	var parent := control.get_parent() as Control

	if parent == null:
		return

	var parent_size := parent.size

	if parent_size.x <= 0 or parent_size.y <= 0:
		return

	var pos := control.position
	var rect_size := control.size

	# Calculate normalized position and size
	var left := pos.x / parent_size.x
	var top := pos.y / parent_size.y
	var right := (pos.x + rect_size.x) / parent_size.x
	var bottom := (pos.y + rect_size.y) / parent_size.y

	# Set anchors to current ratios
	control.set_anchor(SIDE_LEFT, left)
	control.set_anchor(SIDE_TOP, top)
	control.set_anchor(SIDE_RIGHT, right)
	control.set_anchor(SIDE_BOTTOM, bottom)

	# Remove pixel offsets
	control.set_offset(SIDE_LEFT, 0)
	control.set_offset(SIDE_TOP, 0)
	control.set_offset(SIDE_RIGHT, 0)
	control.set_offset(SIDE_BOTTOM, 0)
