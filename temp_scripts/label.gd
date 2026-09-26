extends Label

func _process(delta: float) -> void:
	var peak_data = PedestrianDeadReckoning.data_set[PedestrianDeadReckoning.peak_index]
	var peak_acc = peak_data.accelerometer_data.length()
	
	text = str("Peak Index: ",PedestrianDeadReckoning.peak_index," Peak Acc: ",peak_acc)
