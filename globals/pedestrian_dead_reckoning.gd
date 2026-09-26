# script for handling pedestrian dead reckoning shit
extends Node

# settings
var updates_per_second:int = 60
var data_size_limit:int = 50

# variables
var _update_timer:float
var _data_mem:Array = []

# signals
signal data_updated

# get data
func get_data():
	return _data_mem.duplicate(true)

# process
func _process(delta: float) -> void:
	
	# limit update per second
	_update_timer += delta
	if _update_timer < 1.0 / updates_per_second: return
	_update_timer -= 1.0 / updates_per_second
	
	# get data
	var data = {
		"time":Time.get_ticks_msec() / 1000.0,
		"accelerometer_data":Accelerometer.data_smoothed,
		"gyroscope_data":null,
		"magnetometer_data":null,
	}
	
	# check if mem full
	if _data_mem.size() >= data_size_limit:
		
		# if yes then remove last, push new data to front
		_data_mem.pop_back()
		_data_mem.push_front(data)
	else:
		
		# if not, add data to mem
		_data_mem.append(data)
	
	# fire updated signal
	data_updated.emit()
