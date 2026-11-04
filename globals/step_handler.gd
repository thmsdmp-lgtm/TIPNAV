# singleton for handling step length estimation using the weinberg model
extends Node

#	----------	VARIABLES	----------

var k = 0.48

#	----------	FUNCTIONS	----------

# calculate step length
func calculate_step(step_data:Dictionary):
	if step_data.is_empty(): return
	
	# estimate step length
	
	#get min and max
	var max_acc = step_data.data[step_data.peak_index].acc_magn_smooth
	var min_acc = step_data.data[0].acc_magn_smooth
	
	#find min acc value
	for data in step_data.data:
		if data.acc_magn_smooth < min_acc:
			min_acc = data.acc_magn_smooth
	
	#calculate step length in meters using weinberg model
	var step_length = k * pow(max_acc-min_acc, 0.25)
	
	# estimate step direction
	
