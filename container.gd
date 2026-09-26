# for updating container
extends Control
@export var space = 1.0

func _ready() -> void:
	child_exiting_tree.connect(update)
	child_entered_tree.connect(update)
	get_viewport().size_changed.connect(update)
	
	update()

func update():
	var children = []
	
	for child in get_children():
		if child is Control:
			children.append(child)
	
	var count = children.size()
	var avail_width = size.x - space
	
	if avail_width <= 0: return
	
	var c_w = avail_width / count
	var x = 0.0
	
	for c in children:
		c.position = Vector2(x,0)
		c.size = Vector2(c_w,50)
		x += c_w + space
