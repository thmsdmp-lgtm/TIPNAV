# singleton for handling pedestrian dead reckoning stuff
extends Node

#	----------	SETTINGS	----------
var max_steps_buffer_size:int = 10

#	----------	STEP CONDITIONS	----------

# min time between peaks (msec)
var min_time_between_peaks:float = 500

# minimum difference between avg of 2
# valleys to peak
var min_avg_valley_peak_diff:float = 1

# the maximum difference between the negative
# valley and the positive valley
var max_valley_diff:float = 0.7

# min and max duration between valleys
# (or peak duration/length)
var min_valley_valley_time:float = 200
var max_valley_valley_time:float = 1500

#	-----------	SIGNALS	----------
signal step_occured

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
	var settings = peak.create_settings()
	for key in settings:
		if key is String and key in self:
			settings[key] = self[key]
	peak.validate(peaks_buffer,steps_buffer,settings)
	
	# clean peak buffer
	if peaks_buffer.size() > 2:
		peaks_buffer.pop_front()
	
	# clean steps buffer
	if steps_buffer.size() > max_steps_buffer_size:
		steps_buffer.pop_front()
	
	# clean buffer
	if buffer.size() > 2:
		buffer.pop_front()
