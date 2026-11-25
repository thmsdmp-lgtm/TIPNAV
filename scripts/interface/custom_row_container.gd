@tool
extends Control
class_name CustomRowContainer

## Space between children, and between children and this node's edges.
@export var padding: Vector2 = Vector2(8, 8):
	set(value):
		padding = value
		_queue_arrange()

## Minimum size of each child.
@export var min_size: Vector2 = Vector2(120, 120):
	set(value):
		min_size = value
		_queue_arrange()

## If true, extra horizontal space is shared among the children
## (only applies when everything already fits; otherwise it overflows).
@export var stretch_to_fill: bool = true:
	set(value):
		stretch_to_fill = value
		_queue_arrange()

var _queued := false

func _ready() -> void:
	resized.connect(_queue_arrange)
	child_order_changed.connect(_queue_arrange)
	_queue_arrange()

func _queue_arrange() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	_arrange.call_deferred()

func _arrange() -> void:
	_queued = false

	var items: Array[Control] = []
	for child in get_children():
		if child is Control and child.visible:
			items.append(child)
	if items.is_empty():
		custom_minimum_size = Vector2.ZERO
		return

	if size.x <= 0.0:
		return

	# cell size: the larger of min_size and what the children actually require
	var cell_min := min_size
	for child in items:
		var m := child.get_combined_minimum_size()
		cell_min.x = maxf(cell_min.x, m.x)
		cell_min.y = maxf(cell_min.y, m.y)

	var count := items.size()

	# width needed to fit everything in one row (unstretched)
	var needed_w := padding.x * 2.0 + count * cell_min.x + (count - 1) * padding.x

	var cell_w := cell_min.x
	if stretch_to_fill:
		var avail_w := size.x - padding.x * 2.0
		cell_w = maxf(cell_min.x, (avail_w - padding.x * (count - 1)) / count)
	var cell_h := cell_min.y

	for i in count:
		var child := items[i]
		child.set_anchors_preset(Control.PRESET_TOP_LEFT)
		child.position = Vector2(padding.x + i * (cell_w + padding.x), padding.y)
		child.size = Vector2(cell_w, cell_h)

	# report the real size so a parent ScrollContainer can scroll horizontally
	var total_h := padding.y * 2.0 + cell_h
	var new_min := Vector2(needed_w, total_h)
	if not custom_minimum_size.is_equal_approx(new_min):
		custom_minimum_size = new_min
