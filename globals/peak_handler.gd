# class used for peak finding and validation
extends Node

# create validation settings
var settings:Dictionary =  {
	# max and min step duration (msec)
	"max_step_duration":1000,
	"min_step_duration":300,
	
	# min time between peaks (msec)
	"min_time_between_peaks":500,
	
	# minimum difference between peak and valley
	"min_peak_valley_diff":0.1,
}

# temporary peak data
var temp_peak_data:Dictionary = {
	"data":[],
	"peak_index":null,
	"peak_time":null,
}

# previous peak time
var prev_peak_time:float = -INF

# reset temporary data
func reset_temp():
	temp_peak_data.data.clear()
	temp_peak_data.peak_index = null
	temp_peak_data.peak_time = null

# find steps
func find(buffer:Array):
	if buffer.size() < 3: return
	
	# get data
	var newest_data = buffer[buffer.size() - 1]
	var second_data = buffer[buffer.size() - 2]
	var third_data = buffer[buffer.size() - 3]
	
	if (temp_peak_data.data.size() == 0
	and temp_peak_data.peak_index == null
	and temp_peak_data.peak_time == null
	):
		# find neg valley
		
		# monitor movement
		if (newest_data.acc_magn_lerped > second_data.acc_magn_lerped
		and second_data.acc_magn_lerped <= third_data.acc_magn_lerped):
			
			# record neg valley
			temp_peak_data.data.append(second_data.duplicate(true))
			
	elif temp_peak_data.peak_index == null:
		# find peak
		
		# check elapsed time since neg valley
		var time = second_data.recorded_time
		if (time - temp_peak_data.data[0].recorded_time > settings.max_step_duration):
			reset_temp()
			return
		
		# monitor movement and check conditions
		if (newest_data.acc_magn_lerped < second_data.acc_magn_lerped
		and second_data.acc_magn_lerped > third_data.acc_magn_lerped
		
		# check condition 1
		and second_data.acc_magn_lerped - temp_peak_data.data[0].acc_magn_lerped
		>= settings.min_peak_valley_diff
		
		# check condition 2
		and second_data.recorded_time - prev_peak_time >= settings.min_time_between_peaks):
			
			# record peak
			temp_peak_data.data.append(second_data.duplicate(true))
			temp_peak_data.peak_index = temp_peak_data.data.size() - 1
			temp_peak_data.peak_time = second_data.recorded_time
			
		else:
			temp_peak_data.data.append(second_data.duplicate(true))
	else:
		# find pos valley
		
		# check elapsed time since neg valley
		var time = second_data.recorded_time
		if (time - temp_peak_data.data[0].recorded_time > settings.max_step_duration):
			reset_temp()
			return
		
		# monitor movement and check conditions
		if (newest_data.acc_magn_lerped >= second_data.acc_magn_lerped
		and second_data.acc_magn_lerped <= third_data.acc_magn_lerped
		
		# check condition
		and temp_peak_data.data[temp_peak_data.peak_index].acc_magn_lerped - second_data.acc_magn_lerped
		>= settings.min_peak_valley_diff):
			
			# check if completed peak is above min duration
			if (time - temp_peak_data.data[0].recorded_time < settings.min_step_duration):
				reset_temp()
				return
			
			# record last data (positive valley)
			temp_peak_data.data.append(second_data.duplicate(true))
			
			# once set is completed (negative valley, peak, positive valley)
			# validate, then reset temporary data to repeat cycle
			var peak = temp_peak_data.duplicate(true)
			
			# reset template
			reset_temp()
			
			# validate other conditions
			return validate(peak)
		else:
			temp_peak_data.data.append(second_data.duplicate(true))

# validate peaks (check if they are steps)
func validate(peak):
	if peak == null: return
	
	# get current unvalidated data
	var cur_peak_data = peak
	
	# get current valleys and peak
	var cur_neg_val = cur_peak_data.data[0]
	var cur_peak = cur_peak_data.data[cur_peak_data.peak_index]
	var cur_pos_val = cur_peak_data.data[cur_peak_data.data.size() - 1]
	
	prev_peak_time = cur_peak.recorded_time
	return peak
