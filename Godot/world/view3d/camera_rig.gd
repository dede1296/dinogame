class_name CameraRig
extends Camera3D
## The exploration camera: tilted perspective following Chloé, kept inside the zone.
## Zoom: pinch with two fingers, mouse wheel, or Paramètres → Caméra (remembered).
## Shakes when the 2D camera shakes (impacts, boulders…): `shake_source` offset in px.
## Framed for Chloé 1.50 m tall (Heights): about 15 % of the screen's height by default.

const PITCH_DEG := 40.0
const DISTANCE_MIN := 8.0
const DISTANCE_MAX := 20.0
const DISTANCE_DEFAULT := 12.0
const FOLLOW := 5.0        # smoothing (higher = tighter)
const LOOK_HEIGHT := 0.7   # metres above Chloé's feet
## A distance remembered before the sizes of 28/09/2026 (people were 1.4× taller) is brought
## down once, in proportion (settings.cfg: camera/sizes).
const SIZES_VERSION := 2
const OLD_DISTANCE_TO_NEW := 0.75
const EDGE := 3.0          # how far the target may go inside the zone's edges (m)

var target := Vector3.ZERO
var zone_size := Vector2(40, 26)
var shake_source: Camera2D
var touch_controls: Node

var _distance := DISTANCE_DEFAULT
var _focus := Vector3.ZERO
var _touches := {}
var _pinch_start := 0.0
var _pinch_distance := 0.0


func _ready() -> void:
	fov = 38.0
	near = 0.3
	far = 120.0
	_distance = saved_distance()


## The distance the player chose (Paramètres, pinch, wheel), or the default.
static func saved_distance() -> float:
	if int(Quality.pref("camera", "sizes", 1)) < SIZES_VERSION:
		var old = Quality.pref("camera", "distance", null)
		if old != null:
			Quality.set_pref("camera", "distance", clampf(float(old) * OLD_DISTANCE_TO_NEW, DISTANCE_MIN, DISTANCE_MAX), false)
		Quality.set_pref("camera", "sizes", SIZES_VERSION)
	return clampf(float(Quality.pref("camera", "distance", DISTANCE_DEFAULT)), DISTANCE_MIN, DISTANCE_MAX)


## Jumps to the target (entering a zone), no smoothing.
func snap() -> void:
	_focus = _clamped(target)
	_place()


## `remember` false: kept in memory only (a pinch going on), not written to settings.cfg.
func set_distance(d: float, remember := true) -> void:
	_distance = clampf(d, DISTANCE_MIN, DISTANCE_MAX)
	Quality.set_pref("camera", "distance", _distance, remember)   # (_process reads it back)


func distance() -> float:
	return _distance


func _process(delta: float) -> void:
	# The Paramètres slider may have changed it.
	_distance = clampf(float(Quality.pref("camera", "distance", _distance)), DISTANCE_MIN, DISTANCE_MAX)
	_focus = _focus.lerp(_clamped(target), 1.0 - exp(-FOLLOW * delta))
	_place()


func _clamped(t: Vector3) -> Vector3:
	var slack := EDGE + (DISTANCE_MAX - _distance) * 0.1
	return Vector3(clampf(t.x, slack, maxf(slack, zone_size.x - slack)), t.y,
		clampf(t.z, slack * 0.6, maxf(slack * 0.6, zone_size.y - slack * 0.3)))


func _place() -> void:
	var pitch := deg_to_rad(PITCH_DEG)
	var back := Vector3(0.0, sin(pitch), cos(pitch))
	position = _focus + Vector3(0, LOOK_HEIGHT, 0) + back * _distance
	look_at(position - back, Vector3.UP)
	if shake_source:
		h_offset = shake_source.offset.x / HeightMap.PX
		v_offset = -shake_source.offset.y / HeightMap.PX


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_distance(_distance - 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_distance(_distance + 1.0)
	elif event is InputEventMagnifyGesture:
		set_distance(_distance / event.factor)


## Pinch: two fingers down at once zoom (and take the joystick's finger back).
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
			if _touches.size() < 2 and _pinch_start > 0.0:
				_pinch_start = 0.0
				Quality.set_pref("camera", "distance", _distance)
		if _touches.size() == 2:
			var p: Array = _touches.values()
			_pinch_start = (p[0] as Vector2).distance_to(p[1])
			_pinch_distance = _distance
			if touch_controls and touch_controls.has_method(&"release_stick"):
				touch_controls.release_stick()
	elif event is InputEventScreenDrag and _touches.has(event.index):
		_touches[event.index] = event.position
		if _touches.size() == 2 and _pinch_start > 0.0:
			var p: Array = _touches.values()
			var now := (p[0] as Vector2).distance_to(p[1])
			if now > 1.0:
				set_distance(_pinch_distance * _pinch_start / now, false)
