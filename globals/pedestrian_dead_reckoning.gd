# singleton for handling pedestrian dead reckoning stuff
extends Node

#	----------	SETTINGS	----------
var max_steps_buffer_size:int = 10

#	----------	PEAK CONDITIONS	----------

# min time between peaks (msec)
var min_time_between_peaks:float = 500

# minimum difference between avg of 2
# valleys to peak
var min_avg_valley_peak_diff:float = 1

# min and max duration between valleys
# (or peak duration/length)
var min_valley_valley_time:float = 100
var max_valley_valley_time:float = 500

#	-----------	VARIABLES	----------

# buffer
var buffer:Array = []
var peaks_buffer:Array = []
var steps_buffer:Array = []

#	-----------	FUNCTIONS	----------

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
	
	# validate peaks
	_validate_peaks()
	
	# clean peak buffer
	if peaks_buffer.size() > 2:
		peaks_buffer.pop_front()
	
	# clean steps buffer
	if steps_buffer.size() > max_steps_buffer_size:
		steps_buffer.pop_front()
	
	# clean buffer
	if buffer.size() > 2:
		buffer.pop_front()

# validate peaks
func _validate_peaks():
	if peaks_buffer.size() != 2: return
	
	# get current unvalidated data
	var cur_peak_data = peaks_buffer[peaks_buffer.size() - 1]
	
	# get previous validated data
	var prev_peak_data = null
	if steps_buffer.size() != 0:
		prev_peak_data = steps_buffer[steps_buffer.size() - 1] 
	
	# get current valleys and peak
	var cur_neg_val = cur_peak_data.data[0]
	var cur_peak = cur_peak_data.data[cur_peak_data.peak_index]
	var cur_pos_val = cur_peak_data.data[cur_peak_data.data.size() - 1]
	
	# check conditions 
	
	# check previous positive valley time and
	# current negative valley time difference
	if prev_peak_data and cur_neg_val.time - prev_peak_data.data[prev_peak_data.data.size() - 1].time < min_time_between_peaks:
		return
	
	# check average of 2 current 
	# valleys accelerometer and compare to peak accelerometer
	var val_avg = (cur_neg_val.acc_magn_smooth + cur_pos_val.acc_magn_smooth) / 2
	if cur_peak.acc_magn_smooth - val_avg <= min_avg_valley_peak_diff:
		return
	
	# check duration between
	# negative to positive valleyss
	var val_dur = cur_pos_val.time - cur_neg_val.time
	if val_dur < min_valley_valley_time or val_dur > max_valley_valley_time:
		return
	
	# if all condition passed
	steps_buffer.append(cur_peak_data)
	print("STEP, I THINK..")

# template peak data
var temp_peak_data:Dictionary = {
	"data":[],
	"peak_index":null,
}

# find peaks
func _find_peaks():
	if buffer.size() < 2: return
	
	# get data
	var cur_data = buffer[buffer.size() - 1]
	var prev_data = buffer[buffer.size() - 2]
	
	# monitor negative valley
	if temp_peak_data.data.size() == 0:
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
			peaks_buffer.append(temp_peak_data.duplicate(true))
			temp_peak_data.data.clear()
			temp_peak_data.peak_index = null
		else:
			temp_peak_data.data.append(prev_data.duplicate(true))
