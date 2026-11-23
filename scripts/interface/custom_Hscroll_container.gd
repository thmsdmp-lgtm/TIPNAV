extends Control
class_name CustomHScrollContainer

# external variables
@export var TouchSource:Control # the Control that receives the touch/drag input
@export var Sensitivity:float = 4

# internal variables
var holding:bool = false
var deltaX:float

func _ready() -> void:
	if TouchSource:
		TouchSource.clip_contents = true
		TouchSource.gui_input.connect(_on_touch_source_input)

func _on_touch_source_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				deltaX = 0
				holding = true
			else:
				holding = false

	if event is InputEventMouseMotion and holding:
		var finalSen = clamp(5-Sensitivity,.1,10)
		var dt = get_process_delta_time()
		if dt > 0.0:
			# convert this event's pixel movement into a velocity (px/sec)
			deltaX = (event.relative.x/finalSen) / dt
	elif event is InputEventScreenDrag:
		var finalSen = clamp(5-Sensitivity,.1,10)
		var dt = get_process_delta_time()
		if dt > 0.0:
			deltaX = (event.relative.x/finalSen) / dt

func _process(delta: float) -> void:
	if not TouchSource: return

	# frame-rate independent exponential decay
	deltaX = lerp(deltaX, 0.0, 1.0 - exp(-10.0*delta))

	# this node moves itself, bounded by the touch source's rect
	var new_x := global_position.x + deltaX*delta
	var max_x := TouchSource.global_position.x
	var min_x := (TouchSource.global_position.x + TouchSource.size.x) - size.x

	# if this node is narrower than the touch area, keep it pinned to the left
	min_x = min(min_x, max_x)

	global_position.x = clamp(new_x, min_x, max_x)
