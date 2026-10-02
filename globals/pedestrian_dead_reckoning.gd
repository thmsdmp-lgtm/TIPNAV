# singleton for handling pedestrian dead reckoning stuff
extends Node

# buffer
var buffer:Array = []
var peak_buffer:Array = []

func _process(delta: float) -> void:
	
	# record data
	var data:Dictionary = {
		"time":Time.get_ticks_msec(),
		
		"acc":Accelerometer.data,
		"acc_magn":Accelerometer.data_magn,
		"acc_magn_smooth":Accelerometer.data_magn_smooth,
		
		"gyro":Gyroscope.data,
		"gyro_magn":Gyroscope.data_magn,
		"gyro_magn_smooth":Gyroscope.data_magn_smooth,
	}
	
	buffer.append(data)
	
	# find peaks
	_find_peaks()
	
	if buffer.size() > 2:
		buffer.pop_front()

# template peak data
var temp_peak_data:Dictionary = {
	"data":[],
	"peak_index":null,
}

func _find_peaks():
	if buffer.size() < 2: return
	
	# get data
	var cur_data = buffer[buffer.size() - 1]
	var prev_data = buffer[buffer.size() - 2]
	
	# monitor negative valley
	if temp_peak_data.data.size() == 0:s
		# check data movement
		if cur_data.acc_magn_smooth > prev_data.acc_magn_smooth:
			temp_peak_data.data.append(prev_data.duplicate(true))
	elif temp_peak_data.peak_index == null:
		# check data movement
		if cur_data.acc_magn_smooth < prev_data.acc_magn_smooth:
			temp_peak_data.data.append(prev_data.duplicate(true))
			temp_peak_data.peak_index = temp_peak_data.data.size() - 1
		else:
			temp_peak_data.data.append(prev_data.duplicate(true))
	else:
		# check data movement
		if cur_data.acc_magn_smooth >= prev_data.acc_magn_smooth:
			
			# record last data (positive valley)
			temp_peak_data.data.append(prev_data.duplicate(true))
			
			# once set is completed (negative valley, peak, positive valley)
			# record, then clear to repeat cycle
			peak_buffer.append(temp_peak_data.duplicate(true))
			temp_peak_data.data.clear()
			temp_peak_data.peak_index = null
		else:
			temp_peak_data.data.append(prev_data.duplicate(true))
