# singleton for providing gyro scope data
extends Node

# settings
var smoothing_weight:float = 0.2
var lerp_weight:int = 0.2

# variabless
var data_timestamp:float
var data:Vector3
var data_magn:float
var data_magn_lerped:float
var data_magn_smooth:float

func _process(delta: float) -> void:
	data = Input.get_gyroscope()
	data_timestamp = Time.get_ticks_msec()
	data_magn = data.length()
	data_magn_smooth = lerpf(data_magn_smooth,data_magn,smoothing_weight)
	data_magn_lerped = lerpf(data_magn_lerped,data_magn,lerp_weight)
