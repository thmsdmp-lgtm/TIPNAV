@tool
extends Control
class_name CustomColumnContainer

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

## If true, extra vertical space is shared among the children.
@export var stretch_to_fill: bool = true:
	set(value):
		stretch_to_fill = value
		_queue_arrange()

## If true, children are widened to fill this node when it is wider than needed.
@export var stretch_to_fill_horizontally: bool = true:
	set(value):
		stretch_to_fill_horizontally = value
		_queue_arrange()

## This node can never be smaller than this. Leave at (0, 0) to use the
## size the node has when the scene loads.
@export var default_size: Vector2 = Vector2.ZERO:
	set(value):
		default_size = value
		_queue_arrange()

var _base_size := Vector2.ZERO
var _queued := false

func _ready() -> void:
	_base_size = default_size if default_size != Vector2.ZERO else size
	resized.connect(_queue_arrange)
	child_order_changed.connect(_queue_arrange)
	_queue_arrange()

func _queue_arrange() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	_arrange.call_deferred()

# resize this node itself (not just its minimum size)
func _fit_to(v: Vector2) -> void:
	if not custom_minimum_size.is_equal_approx(v):
		custom_minimum_size = v
	if not size.is_equal_approx(v):
		size = v

func _arrange() -> void:
	_queued = false

	# an explicit default_size set later (e.g. in the inspector) wins
	var base := default_size if default_size != Vector2.ZERO else _base_size

	var items: Array[Control] = []
	for child in get_children():
		if child is Control and child.visible:
			items.append(child)
	if items.is_empty():
		_fit_to(base)
		return

	# cell size: the larger of min_size and what the children actually require
	var cell_min := min_size
	for child in items:
		var m := child.get_combined_minimum_size()
		cell_min.x = maxf(cell_min.x, m.x)
		cell_min.y = maxf(cell_min.y, m.y)

	var n := items.size()

	# size needed by the children
	var content_w := padding.x * 2.0 + cell_min.x
	var content_h := padding.y * 2.0 + n * cell_min.y + (n - 1) * padding.y

	# this node becomes exactly the content size, but never below its default size
	var target := Vector2(maxf(base.x, content_w), maxf(base.y, content_h))
	_fit_to(target)

	# children keep their minimum size; they only grow to use leftover
	# space when the default size is bigger than the content
	var cell_w := cell_min.x
	var cell_h := cell_min.y
	if stretch_to_fill_horizontally:
		cell_w = target.x - padding.x * 2.0
	if stretch_to_fill:
		cell_h = (target.y - padding.y * 2.0 - padding.y * (n - 1)) / n

	for i in n:
		var child := items[i]
		child.set_anchors_preset(Control.PRESET_TOP_LEFT)
		child.position = Vector2(padding.x, padding.y + i * (cell_h + padding.y))
		child.size = Vector2(cell_w, cell_h)
