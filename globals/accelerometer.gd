# singleton for accessing accelerometer data
extends Node

signal updated(data: Vector3)
var is_initialized: bool = false
var data: Vector3 = Vector3.ZERO

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

func _process(_delta: float):
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		if window and window.accelerometerData:
			var js_data = window.accelerometerData
			
			var new_x = float(js_data.x)
			var new_y = float(js_data.y)
			var new_z = float(js_data.z)
			
			data = Vector3(new_x, new_y, new_z)
			updated.emit(data)
	else:
		data = Input.get_accelerometer()
		updated.emit(data)
