# temporary script for handling
# savitzky golay filter
extends Node

# settings
var order:int = 2
var size:int = 5

# variables
var test_data_set:Array = [
	
]

# init
func _ready() -> void:
	sg_filter(test_data_set)

# filter function
func sg_filter(window:Array):
	
	# create array
	var data = []
	
	# get needed values from window
	for y in window:
		var x = data.size()
		var d = {
			"x":x,
			"y":y,
			
			"x2":x*x,
			"x3":x*x*x,
			"x4":x*x*x*x,
			
			"xy":x*y,
			"x2y":(x*x)*y,}
		
		data.append(d)
	
	# sum needed values
	var sX:float = 0.0
	var sY:float = 0.0
	var sX2:float = 0.0
	var sX3:float = 0.0
	var sX4:float = 0.0
	var sXY:float = 0.0
	var sX2Y:float = 0.0
	
	for x in range(data.size()):
		var d = data[x]
		
		sX += d.x
		sY += d.y
		sX2 += d.x2
		sX3 += d.x3
		sX4 += d.x4
		sXY += d.xy
		sX2Y += d.x2y
	
	# evaluate
	
