# script for visualizing pdr data
extends Node

# settings
var line_height_mult:int = 50 
var buffer_size:int = 50
var data_raw_color:Color = Color.RED
var data_smooth_color:Color = Color.GREEN

# buffer
var buffer:Array = []

# variables
var chart:Control
var chart_step:Control

var line_chart_smooth:Line2D
var line_chart_raw:Line2D
var line_step:Line2D

func _ready() -> void:
	
	# signals
	PedestrianDeadReckoning.step_occured.connect(_step_occured)
	
	# get line containers
	chart = %PdrDataChartCombined
	chart_step = %PdrDataChartLatestStep
	
	# get lines
	line_chart_raw = Line2D.new()
	chart.add_child(line_chart_raw)
	line_chart_raw.width = 5
	line_chart_raw.default_color = data_raw_color
	
	line_chart_smooth = Line2D.new()
	chart.add_child(line_chart_smooth)
	line_chart_smooth.width = 3
	line_chart_smooth.default_color = data_smooth_color
	
	line_step = Line2D.new()
	chart_step.add_child(line_step)
	line_step.width = 5
	
	# setup lines
	var c_size = chart.size
	var ct_size = chart_step.size
	var x = 0
	
	for i in buffer_size + 1:
		line_chart_raw.add_point(Vector2(x,c_size.y/2))
		line_chart_smooth.add_point(Vector2(x,c_size.y/2))
		x += c_size.x / buffer_size
	
	x = 0
	
	for i in buffer_size + 1:
		line_step.add_point(Vector2(x,ct_size.y/2))
		x += ct_size.x / buffer_size

func _step_occured(peak):
	line_step.clear_points()
	
	var data:Array = peak.data
	var ct_size = chart_step.size
	var x = 0
	
	for i in range(data.size()):
		var acc = data[i].acc_magn_smooth
		
		line_step.add_point(Vector2(x,(ct_size.y/2) + (line_height_mult * acc)))
		x += ct_size.x / buffer_size

func _process(delta: float) -> void:
	
	# fill buffer
	if buffer.size() > buffer_size:
		buffer.pop_front()
	else:
		var data = {
			"raw":Accelerometer.data_magn,
			"smooth":Accelerometer.data_magn_smooth,
		}
		
		buffer.append(data)
	
	# checks
	if buffer.size() == 0: return
	if line_chart_raw.get_point_count() == 0: return
	if line_chart_smooth.get_point_count() == 0: return
	if line_step.get_point_count() == 0: return
	
	var c_size = chart.size
	
	# set lines pos
	for i in range(buffer.size()):
		var data = buffer[i]
		
		# raw
		var orig_raw_pos = line_chart_raw.get_point_position(i)
		line_chart_raw.set_point_position(i,Vector2(orig_raw_pos.x,(c_size.y/2) + (line_height_mult * data.raw)))
		
		# smooth
		var orig_sm_pos = line_chart_smooth.get_point_position(i)
		line_chart_smooth.set_point_position(i,Vector2(orig_sm_pos.x,(c_size.y/2) + (line_height_mult * data.raw)))
