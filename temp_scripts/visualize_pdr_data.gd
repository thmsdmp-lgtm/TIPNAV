extends Node

@export var container:Control

func _ready() -> void:
	PedestrianDeadReckoning.data_updated.connect(update_container)
func update_container():
	
	# delete all children
	for c in container.get_children():
		c.queue_free()
	
	# add panel per data
	for data in PedestrianDeadReckoning.get_data():
		var panel = Panel.new()
		container.add_child(panel)
		panel.size.y = 100.0 * data.accelerometer_data.length()
