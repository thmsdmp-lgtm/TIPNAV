@tool
extends Control
class_name CustomRowContainer

## Space between children, and between children and this node's edges.
@export var padding: Vector2 = Vector2(8, 8):
	set(value):
		padding = value
		_queue_arrange()

## Minimum size of each child. Controls how many fit per row.
@export var min_size: Vector2 = Vector2(120, 120):
	set(value):
		min_size = value
		_queue_arrange()

## If true, extra horizontal space in a row is shared among the children.
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
		custom_minimum_size.y = 0
		return

	# wait until this node has a real width (resized will call us again)
	if size.x <= 0.0:
		return

	# cell size: the larger of min_size and what the children actually require
	var cell_min := min_size
	for child in items:
		var m := child.get_combined_minimum_size()
		cell_min.x = maxf(cell_min.x, m.x)
		cell_min.y = maxf(cell_min.y, m.y)

	var avail_w := size.x - padding.x * 2.0
	var cols := maxi(1, int(floor((avail_w + padding.x) / (cell_min.x + padding.x))))

	var cell_w := cell_min.x
	if stretch_to_fill:
		cell_w = maxf(cell_min.x, (avail_w - padding.x * (cols - 1)) / cols)
	var cell_h := cell_min.y

	for i in items.size():
		var child := items[i]
		var col := i % cols
		var row := i / cols

		# anchors must be top-left or the parent's size will move the child
		child.set_anchors_preset(Control.PRESET_TOP_LEFT)
		child.position = Vector2(
			padding.x + col * (cell_w + padding.x),
			padding.y + row * (cell_h + padding.y)
		)
		child.size = Vector2(cell_w, cell_h)

	var rows := ceili(float(items.size()) / cols)
	var total_h := padding.y * 2.0 + rows * cell_h + (rows - 1) * padding.y
	if not is_equal_approx(custom_minimum_size.y, total_h):
		custom_minimum_size.y = total_h
