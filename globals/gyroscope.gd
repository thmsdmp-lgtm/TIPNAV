# singleton for providing gyro scope data
extends Node

# settings
var smoothing_weight:float = 0.2

# variabless
var data:Vector3
var data_magn:float
var data_magn_smooth:float

func _process(delta: float) -> void:
	data = Input.get_gyroscope()
	data_magn = data.length()
	data_magn_smooth = lerpf(data_magn_smooth,data_magn,smoothing_weight)
