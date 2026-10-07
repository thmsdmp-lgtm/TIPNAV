extends Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = "SG: " + str(Accelerometer.data_magn_smooth) + "BUFFER: " + str(Accelerometer.raw_magn_buffer)
