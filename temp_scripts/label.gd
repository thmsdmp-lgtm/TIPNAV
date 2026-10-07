extends Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = "SG SMOOTHED (NO INTERVAL): " + str(Accelerometer.data_magn_smooth)
