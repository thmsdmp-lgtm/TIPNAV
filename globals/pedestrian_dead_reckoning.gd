# singleton for handling pedestrian dead reckoning stuff
extends Node

#	----------	SETTINGS	----------
var max_steps_buffer_size:int = 10
var max_data_buffer_size:int = 10

#	-----------	SIGNALS	----------
signal step_occurred(step_data:Dictionary)

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

# class for peak finding and validation
var peak = PeakHandler.new()

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
	peak.find(buffer,peaks_buffer,temp_peak_data)
	
	# validate peaks
	var step = peak.validate(peaks_buffer,steps_buffer)
	if step:
		step_occurred.emit(step)
	
	# clean steps buffer
	if steps_buffer.size() > max_steps_buffer_size:
		steps_buffer.pop_front()
	
	# clean buffer
	if buffer.size() > max_data_buffer_size:
		buffer.pop_front()
