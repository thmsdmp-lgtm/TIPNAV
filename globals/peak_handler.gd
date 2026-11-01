# class used for peak finding and validation
extends Node

# step detection settings
var settings:Dictionary = {
		# min time between peaks (msec)
		"min_time_between_peaks":250,
		
		# min value difference between
		# candidate peak to valley
		"min_valley_peak_diff":0.2,
		
		# minimum difference between avg of 2
		# valleys to peak
		"min_avg_valley_peak_diff":0.5,
		
		# the maximum difference between the negative
		# valley and the positive valley value
		"max_valley_diff":0.3,
		
		# min and max duration between valleys
		# (or peak duration/length)
		"min_valley_valley_time":200,
		"max_valley_valley_time":1500,
	}

# find peaks
var highest_val_index:int = -1

func find(buffer:Array, peaks_buffer:Array, temp_peak_data:Dictionary):
	if buffer.size() < 2:
		return
	
	# get data
	var cur_data = buffer[buffer.size() - 1]
	var prev_data = buffer[buffer.size() - 2]
	
	if temp_peak_data.data.size() == 0:
		# check data movement
		if cur_data.acc_magn_smooth > prev_data.acc_magn_smooth:
			temp_peak_data.data.append(prev_data.duplicate(true))
			highest_val_index = 0
	
	elif temp_peak_data.peak_index == null:
		# check data movement
		if cur_data.acc_magn_smooth < prev_data.acc_magn_smooth:
		
			# check minimum difference between valley and highest peak
			if highest_val_index != -1 and temp_peak_data.data[highest_val_index].acc_magn_smooth - temp_peak_data.data[0].acc_magn_smooth >= settings.min_valley_peak_diff:
				
				# record current sample
				temp_peak_data.data.append(prev_data.duplicate(true))
				
				# determine highest sample
				if prev_data.acc_magn_smooth > temp_peak_data.data[highest_val_index].acc_magn_smooth:
					temp_peak_data.peak_index = temp_peak_data.data.size() - 1
				else:
					temp_peak_data.peak_index = highest_val_index
					
				return
		
		# append current candidate data
		temp_peak_data.data.append(prev_data.duplicate(true))
		
		# update highest sample index
		if highest_val_index == -1 or prev_data.acc_magn_smooth > temp_peak_data.data[highest_val_index].acc_magn_smooth:
			highest_val_index = temp_peak_data.data.size() - 1
	
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
			highest_val_index = -1
			
			peaks_buffer.append(peak)
			return peak
		
		else:
			temp_peak_data.data.append(prev_data.duplicate(true))

# validate peaks
func validate(peaks_buffer:Array, steps_buffer:Array):
	if peaks_buffer.size() == 0: return
	
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
	
	# check prev step exists 
	# and time between previous
	# and current peak
	if prev_peak_data and cur_peak.time - prev_peak_data.data[prev_peak_data.peak_index].time < settings.min_time_between_peaks:
		peaks_buffer.pop_back()
		return false
	
	# check average of 2 current 
	# valleys accelerometer and compare to peak accelerometer
	var val_avg = (cur_neg_val.acc_magn_smooth + cur_pos_val.acc_magn_smooth) / 2
	if cur_peak.acc_magn_smooth - val_avg <= settings.min_avg_valley_peak_diff:
		peaks_buffer.pop_back()
		return false
	
	# check duration between
	# negative to positive valley of current peak
	var val_dur = cur_pos_val.time - cur_neg_val.time
	if val_dur < settings.min_valley_valley_time or val_dur > settings.max_valley_valley_time:
		peaks_buffer.pop_back()
		return false
	
	# check difference between
	# negative and positive valley of current peak
	if absf(cur_neg_val.acc_magn_smooth - cur_pos_val.acc_magn_smooth) > settings.max_valley_diff:
		peaks_buffer.pop_back()
		return false
	
	# if all condition passed, return peak
	steps_buffer.append(cur_peak_data)
	peaks_buffer.pop_back()
	return cur_peak_data
