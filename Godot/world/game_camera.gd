extends Camera2D
## Follows Chloé smoothly, stays inside the region, and can shake (impacts, boulders…).

var _shake_strength := 0.0
var _shake_time := 0.0


func fit_to(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)
	reset_smoothing()


func shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_time = duration


func _process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength
		if _shake_time <= 0.0:
			offset = Vector2.ZERO
