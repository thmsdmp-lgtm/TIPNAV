# singleton for handling pedestrian dead reckoning stuff
extends Node

#	----------	DATA STRUCTURE	----------

# data point structure
#{
	#"recorded_time":Time.get_ticks_msec(),
	#
	#"acc_time":Accelerometer.data_timestamp,
	#"gyro_time":Gyroscope.data_timestamp,
	
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
var sampling_rate:int = 100
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
var steps_buffer:Array = []

# sampling rate variables
var sampling_interval:float:
	get:
		return 1.0 / sampling_rate
var accumulator:float = 0.0

# data timestamp
var prev_acc_timestamp:float = -1.0
var prev_gyro_timestamp:float = -1.0

#	-----------	FUNCTIONS	----------

# calculate
func _process(delta: float) -> void:
	
	# execute according to sampling rate
	accumulator += delta
	while  accumulator >= sampling_interval:
		accumulator -= sampling_interval
		
		# check data timestamp
		#if Accelerometer.data_timestamp == prev_acc_timestamp: continue
		#if Gyroscope.data_timestamp == prev_gyro_timestamp: continue
		
		# record data
		var data:Dictionary = {
			"recorded_time":Time.get_ticks_msec(),
			
			"acc_time":Accelerometer.data_timestamp,
			"gyro_time":Gyroscope.data_timestamp,
			
			"acc":Accelerometer.data,
			"acc_magn":Accelerometer.data_magn,
			"acc_magn_smooth":Accelerometer.data_magn_smooth,
			
			"gyro":Gyroscope.data,
			"gyro_magn":Gyroscope.data_magn,
			"gyro_magn_smooth":Gyroscope.data_magn_smooth,
		}
		
		buffer.append(data)
		
		# update time stamp
		prev_acc_timestamp = Accelerometer.data_timestamp
		prev_gyro_timestamp = Gyroscope.data_timestamp
		
		# find peaks
		print("Finding peaks")
		var peak = PeakHandler.find(buffer,peaks_buffer,temp_peak_data)
		
		if peak != null:
			print("Found peak")
			
			print("Validating peak")
			var step = PeakHandler.validate(peak,steps_buffer)
			if step:
				# calculate step length
				var step_length = StepHandler.calculate_step(step)
				
				# emit stepped signal
				if step_length:
					print("Step detected")
					step_occured.emit(step,step_length)
		print("No steps found")
		
		# clean steps buffer
		if steps_buffer.size() > max_steps_buffer_size:
			steps_buffer.pop_front()
		
		# clean buffer
		if buffer.size() > 2:
			buffer.pop_front()
