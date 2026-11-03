# singleton for handling pedestrian dead reckoning stuff
extends Node

#	----------	DATA STRUCTURE	----------

# data point structure
#{
	#"time":Time.get_ticks_msec(),
	#
	#"acc":Accelerometer.data,
	#"acc_magn":Accelerometer.data_magn,
	#"acc_magn_smooth":Accelerometer.data_magn_smooth,
	#
	#"gyro":Gyroscope.data,
	#"gyro_magn":Gyroscope.data_magn,
	#"gyro_magn_smooth":Gyroscope.data_magn_smooth,
	#}

# peak data structure
#{
	#"data":[ array of multiple data points ],
	#"peak_index":int
#}

#	----------	SETTINGS	----------
var max_steps_buffer_size:int = 10

#	-----------	SIGNALS	----------
signal step_occured(step_data:Dictionary,step_length:float)

#	-----------	VARIABLES	----------

# template peak data
var temp_peak_data:Dictionary = {
	"data":[],
	"peak_index":null,
}

# buffer
var buffer:Array = []
var peaks_buffer:Array = []
var steps_buffer:Array = []

#	-----------	FUNCTIONS	----------

# per frame
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
	PeakHandler.find(buffer,peaks_buffer,temp_peak_data)
	
	# validate peaks (check if they are steps)
	var step = PeakHandler.validate(peaks_buffer,steps_buffer)
	if step:
		# calculate step length
		var step_length = StepHandler.calculate_step(step)
		
		# emit stepped signal
		if step_length:
			step_occured.emit(step,step_length)
	
	# clean steps buffer
	if steps_buffer.size() > max_steps_buffer_size:
		steps_buffer.pop_front()
	
	# clean buffer
	if buffer.size() > 2:
		buffer.pop_front()
