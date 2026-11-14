# singleton for accessing accelerometer data
extends Node

# settings
var lerp_weight:float = 0.2
var window_size:int = 11
var polynomial:int = 2

# flags 
var is_initialized: bool = false

# variables
var raw_magn_buffer:Array = []

var data_timestamp:float
var data: Vector3 = Vector3.ZERO
var data_magn:float
var data_magn_lerped:float
var data_magn_smooth:float

# constants
const gravity:float = 9.81

func _ready():
	if OS.has_feature("web"):
		# Attempt initial JS check
		JavaScriptBridge.eval("if (window.initAccelerometer) { window.initAccelerometer(); }")

func _unhandled_input(event: InputEvent):
	# Required for iOS Safari: Call init on first touch/click event frame
	if not is_initialized and (event is InputEventScreenTouch or event is InputEventMouseButton):
		if event.pressed:
			is_initialized = true
			if OS.has_feature("web"):
				JavaScriptBridge.eval("window.initAccelerometer();")

var timer:float = 0.0
func _process(_delta: float):
	
	# get data
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		if window and window.accelerometerData:
			var js_data = window.accelerometerData
			
			var new_x = float(js_data.x)
			var new_y = float(js_data.y)
			var new_z = float(js_data.z)
			var timestamp = float(js_data.timestamp)
			
			data_timestamp = timestamp
			data = Vector3(new_x, new_y, new_z)
	else:
		data = Input.get_accelerometer()
	
	# update other data type
	data_magn = data.length()
	
	# calculate lerped data
	data_magn_lerped = lerpf(data_magn_lerped,data_magn,lerp_weight)
	
	# fill buffer
	raw_magn_buffer.append(data_magn)
	
	# clear buffer overflow
	if raw_magn_buffer.size() > window_size:
		raw_magn_buffer.pop_front()
	
	if raw_magn_buffer.size() == window_size and OS.has_feature("web"):
		
		# smooth magn using sg filter
		var data = JSON.stringify(raw_magn_buffer)
		var result = JSON.parse_string(JavaScriptBridge.eval("""
		JSON.stringify(
			window.savitzkyGolay(
				%s,
				1,
				{
					windowSize: %d,
					derivative: 0,
					polynomial: %d,
				}
			)
		)
		""" % [data,window_size,polynomial]))
		
		# assign result to variable
		data_magn_smooth = result[0]
