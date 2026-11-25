extends Node3D

@export var camera3d: Camera3D
@export var input_area: Control ## Camera only reacts to input that lands on this control
@export var smoothing: float = 20.0
@export var focus: bool = false ## false = freecam, true = follow the capsule

@export_group("Rotation")
@export var rotate_speed: float = 0.15 ## degrees per pixel of one-finger drag
@export var min_pitch: float = 10.0
@export var max_pitch: float = 85.0
@export var rotate_start_delay_ms: int = 80 ## a lone finger must be down this long before it rotates (lets a second finger land first)

@export_group("Pan")
@export var pan_speed: float = 2.0 ## 1.0 = ground follows your fingers 1:1

@export_group("Zoom")
@export var min_distance: float = 3.0
@export var max_distance: float = 100
@export var zoom_smoothing: float = 12.0
@export var wheel_zoom_step: float = 1.1 ## desktop testing

const MOUSE_IGNORE_AFTER_TOUCH_MS := 500

var _pending_rotate: Vector2 = Vector2.ZERO  # pixels still to be applied
var _pending_pan: Vector2 = Vector2.ZERO     # pixels still to be applied

var _touches: Dictionary = {}                # finger index -> position
var _last_pinch_distance: float = 0.0
var _last_centroid: Vector2 = Vector2.ZERO
var _gesture_locked: bool = false            # true from 2-finger start until ALL fingers are lifted
var _single_touch_start_msec: int = 0
var _last_touch_msec: int = -100000

var _camera_dir: Vector3 = Vector3.BACK
var _distance: float = 10.0
var _target_distance: float = 10.0


func _ready() -> void:
	if camera3d == null:
		push_error("camera3d is not assigned.")
		set_process(false)
		return
	if input_area == null:
		push_error("input_area is not assigned.")
		set_process(false)
		return

	# The control must not ignore the mouse/touch, otherwise it never gets gui_input.
	if input_area.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		input_area.mouse_filter = Control.MOUSE_FILTER_STOP
	input_area.gui_input.connect(_on_input_area_gui_input)
	# If the area gets hidden (e.g. tab switch) mid-touch, drop stale fingers.
	input_area.visibility_changed.connect(_reset_touch_state)

	# Assumes the camera is a child of this node, positioned away from the pivot.
	var offset := camera3d.position
	if offset.length() < 0.001:
		offset = Vector3(0, 0, 10)
	_camera_dir = offset.normalized()
	_distance = clampf(offset.length(), min_distance, max_distance)
	_target_distance = _distance


func _reset_touch_state() -> void:
	_touches.clear()
	_gesture_locked = false
	_last_pinch_distance = 0.0
	_last_centroid = Vector2.ZERO
	_pending_rotate = Vector2.ZERO
	_pending_pan = Vector2.ZERO


# --- Input ------------------------------------------------------------------

func _on_input_area_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_last_touch_msec = Time.get_ticks_msec()
		var was_two_fingers := _touches.size() >= 2

		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_single_touch_start_msec = Time.get_ticks_msec()
		else:
			_touches.erase(event.index)

		if _touches.size() >= 2:
			_gesture_locked = true
		elif _touches.is_empty():
			_gesture_locked = false

		# Entering/leaving a two-finger gesture: drop pending motion so nothing jumps.
		# A plain one-finger release keeps gliding via the smoothing.
		if was_two_fingers or _touches.size() >= 2:
			_pending_rotate = Vector2.ZERO
			_pending_pan = Vector2.ZERO

		# Re-baseline so the first drag after a change doesn't produce a jump.
		_update_two_finger_baseline()

	elif event is InputEventScreenDrag:
		_last_touch_msec = Time.get_ticks_msec()
		_touches[event.index] = event.position

		if _touches.size() == 2:
			_handle_two_finger_gesture()
		elif _touches.size() == 1 and not _gesture_locked:
			# Wait briefly so a second finger can land before we start rotating.
			if Time.get_ticks_msec() - _single_touch_start_msec >= rotate_start_delay_ms:
				_pending_rotate += event.relative  # one finger = rotate

	elif event is InputEventMagnifyGesture:  # trackpad pinch
		_zoom_by_factor(event.factor)

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by_factor(wheel_zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by_factor(1.0 / wheel_zoom_step)

	elif event is InputEventMouseMotion:
		# Desktop testing only. Touches must never reach this branch, otherwise
		# the emulated mouse (which follows one finger) would rotate the camera
		# during a two-finger gesture.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if not _touches.is_empty() or _gesture_locked:
			return
		if Time.get_ticks_msec() - _last_touch_msec < MOUSE_IGNORE_AFTER_TOUCH_MS:
			return
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_pending_rotate += event.relative
		elif event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE):
			_pending_pan += event.relative


func _get_two_finger_state() -> Dictionary:
	# Sorted keys so the same two fingers are always compared in the same order
	var keys := _touches.keys()
	keys.sort()
	var a: Vector2 = _touches[keys[0]]
	var b: Vector2 = _touches[keys[1]]
	return {"distance": a.distance_to(b), "centroid": (a + b) * 0.5}


func _update_two_finger_baseline() -> void:
	if _touches.size() == 2:
		var s := _get_two_finger_state()
		_last_pinch_distance = s.distance
		_last_centroid = s.centroid
	else:
		_last_pinch_distance = 0.0
		_last_centroid = Vector2.ZERO


func _handle_two_finger_gesture() -> void:
	var s := _get_two_finger_state()
	var dist: float = s.distance
	var centroid: Vector2 = s.centroid

	# Both are computed from the same event, so zoom and pan happen simultaneously.
	if _last_pinch_distance > 0.0 and dist > 0.0:
		# Fingers spreading -> factor > 1 -> zoom in
		_zoom_by_factor(dist / _last_pinch_distance)
		_pending_pan += centroid - _last_centroid

	_last_pinch_distance = dist
	_last_centroid = centroid


# --- Per-frame update -------------------------------------------------------

func _process(delta: float) -> void:
	# Frame-rate independent smoothing: each frame applies a fraction of the pending input.
	var t := 1.0 - exp(-smoothing * delta)

	# Two fingers down: rotation is never allowed, whatever else produced it.
	if _gesture_locked:
		_pending_rotate = Vector2.ZERO

	# Rotation (one finger)
	var rot_step := _pending_rotate * t
	_pending_rotate -= rot_step
	rotation_degrees.y -= rot_step.x * rotate_speed
	rotation_degrees.x -= rot_step.y * rotate_speed
	rotation_degrees.x = clampf(rotation_degrees.x, min_pitch, max_pitch)

	# Pan (two fingers)
	var pan_step := _pending_pan * t
	_pending_pan -= pan_step

	if focus and is_instance_valid(%capsule):
		position = %capsule.position
	elif pan_step != Vector2.ZERO:
		var right := camera3d.global_basis.x
		var forward := -camera3d.global_basis.z
		right.y = 0.0
		forward.y = 0.0
		right = right.normalized()
		forward = forward.normalized()

		var world_per_pixel := _world_units_per_pixel() * pan_speed
		# Dragging the ground: fingers move right -> pivot moves left, etc.
		var movement := right * -pan_step.x + forward * pan_step.y
		position += movement * world_per_pixel

	_update_zoom(delta)


func _world_units_per_pixel() -> float:
	var viewport_h := maxf(get_viewport().get_visible_rect().size.y, 1.0)
	if camera3d.projection == Camera3D.PROJECTION_ORTHOGONAL:
		return camera3d.size / viewport_h
	# Perspective (assumes the default vertical FOV): scale with distance so panning
	# feels the same whether you're zoomed in or out.
	return 2.0 * tan(deg_to_rad(camera3d.fov) * 0.5) * _distance / viewport_h


# --- Zoom -------------------------------------------------------------------

func _zoom_by_factor(factor: float) -> void:
	if factor <= 0.0:
		return
	_target_distance = clampf(_target_distance / factor, min_distance, max_distance)


func _update_zoom(delta: float) -> void:
	_distance = lerpf(_distance, _target_distance, 1.0 - exp(-zoom_smoothing * delta))
	camera3d.position = _camera_dir * _distance
