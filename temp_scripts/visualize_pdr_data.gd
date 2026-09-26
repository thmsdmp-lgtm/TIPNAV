extends Node

@export var container:Control

func _process(delta: float) -> void:
	update_container()
func update_container():
	
	# delete all children
	for c in container.get_children():
		c.queue_free()
	
	# add panel per data
	for data in PedestrianDeadReckoning._data_mem:
		var panel = Panel.new()
		container.add_child(panel)
		panel.size = Vector2(panel.size.x,100.0 * data.accelerometer_data.length())
