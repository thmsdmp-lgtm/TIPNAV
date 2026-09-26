# script for handling pedestrian dead reckoning shit
extends Node

# settings
var updates_per_second:int = 60
var data_size_limit:int = 50

# variables
var _update_timer:float
var data_set:Array = []
var peak_index:int
var valley_index:int

# signals
signal data_updated

# get data
func get_data():
	return data_set.duplicate(true)

# get data size
func get_data_size():
	return data_set.size()

# find peaks and vallies in the data
func _find_peak_valley():
	
	# loop for every data in data set
	for d_i in data_set.size():
		
		# get variables
		var data = data_set[d_i]
		var acc = data.accelerometer_data.length()
		
		# check variables
		if data == null or acc == null: return
		
		# check current peak data
		var peak_data = data_set[peak_index]
		var peak_acc = peak_data.accelerometer_data.length()
		
		# check peak variables
		if peak_data == null or peak_acc == null: return
		
		# check peak
		if acc > peak_acc:
			peak_index = d_i

# process
func _process(delta: float) -> void:
	
	# limit update per second
	_update_timer += delta
	if _update_timer < 1.0 / updates_per_second: return
	_update_timer -= 1.0 / updates_per_second
	
	# get data
	var d = {
		"time":Time.get_ticks_msec() / 1000.0,
		"accelerometer_data":Accelerometer.data_smoothed,
		"gyroscope_data":null,
		"magnetometer_data":null,
	}
	
	# check if mem full
	if data_set.size() >= data_size_limit:
		
		# if yes then remove last, push new data to front
		data_set.pop_back()
		data_set.push_front(d)
	else:
		
		# if not, add data to mem
		data_set.append(d)
	
	# fire updated signal
	data_updated.emit()
	
	# look for peak and valley
	_find_peak_valley()
