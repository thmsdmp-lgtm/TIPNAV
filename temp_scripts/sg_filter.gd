# temporary script for handling
# savitzky golay filter
extends Node

# variables
var test_data_set:Array = [
	
]

# init
func _ready() -> void:
	sg_filter(test_data_set)

# filter function
func sg_filter(data_set:Array):
	
	# create array
	var data = []
	
	# get needed values
	for y in test_data_set:
		var x = (data.size() - 1) + 1
		var d = {
			"x":x,
			"y":y,
			
			"x2":x*x,
			"x3":x*x*x,
			"x4":x*x*x*x,
			
			"xy":x*y,
			"x2y":(x*x)*y,}
	
	# sum needed values
	var sX:int
	var sY:int
	var sX2:int
	var sX3:int
	var sX4:int
	var sXY:int
	var sX2Y:int
	
	for x in range(data.size()):
		var d = data[x]
		
		sX += d.x
		sY += d.y
		sX2 += d.x2
		sX3 += d.x3
		sX4 += d.x4
		sXY += d.xy
		sX2Y += d.x2y
