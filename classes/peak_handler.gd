# class used for peak finding and validation
extends Node
class_name PeakHandler

# create validation settings
# returns a dictionary with default settings
func create_settings():
	return {
		# min time between peaks (msec)
		"min_time_between_peaks":500,
		
		# minimum difference between avg of 2
		# valleys to peak
		"min_avg_valley_peak_diff":1,
		
		# the maximum difference between the negative
		# valley and the positive valley
		"max_valley_diff":0.7,
		
		# min and max duration between valleys
		# (or peak duration/length)
		"min_valley_valley_time":200,
		"max_valley_valley_time":1500,
	}

# find peaks
func find(buffer:Array, peaks_buffer:Array, temp_peak_data:Dictionary):
	if buffer.size() < 2: return
	
	# get data
	var cur_data = buffer[buffer.size() - 1]
	var prev_data = buffer[buffer.size() - 2]
	
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
			# return, then clear to repeat cycle
			var peak = temp_peak_data.duplicate(true)
			temp_peak_data.data.clear()
			temp_peak_data.peak_index = null
			
			return peak
		else:
			temp_peak_data.data.append(prev_data.duplicate(true))

# validate peaks
func validate(peaks_buffer:Array, steps_buffer:Array, settings:Dictionary):
	if peaks_buffer.size() != 2: return
	if settings == null:
		settings = create_settings()
	
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
	if prev_peak_data and cur_neg_val.time - prev_peak_data.data[prev_peak_data.data.size() - 1].time < settings.min_time_between_peaks:
		return false
	
	# check average of 2 current 
	# valleys accelerometer and compare to peak accelerometer
	var val_avg = (cur_neg_val.acc_magn_smooth + cur_pos_val.acc_magn_smooth) / 2
	if cur_peak.acc_magn_smooth - val_avg <= settings.min_avg_valley_peak_diff:
		return false
	
	# check duration between
	# negative to positive valleyss
	var val_dur = cur_pos_val.time - cur_neg_val.time
	if val_dur < settings.min_valley_valley_time or val_dur > settings.max_valley_valley_time:
		return false
	
	# check difference between
	# negative and positive valley
	if absf(cur_neg_val.acc_magn_smooth - cur_pos_val.acc_magn_smooth) > settings.max_valley_diff:
		return false
	
	# if all condition passed, return peak
	return cur_peak_data
