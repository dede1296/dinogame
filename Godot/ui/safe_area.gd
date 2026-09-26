class_name SafeArea
## Screen insets to keep UI away from notches, camera holes and rounded corners, in canvas
## units (what Control positions use). Phones only: on desktop the "safe area" is the
## screen minus the taskbar, which has nothing to do with the game window.
## Horizontal insets are symmetric, so a phone turned the other way round needs no relayout.

## Extra room so thumbs don't press against the very edge of the glass.
const COMFORT := 12.0


## Vector2(horizontal inset, vertical inset), each applied on both sides.
static func insets(vp: Viewport) -> Vector2:
	var visible := vp.get_visible_rect().size
	if not OS.has_feature("mobile"):
		return Vector2(COMFORT, COMFORT)
	var window := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if window.x <= 0.0 or safe.size.x <= 0.0:
		return Vector2(COMFORT, COMFORT)
	var k := visible / window
	var origin := Vector2(DisplayServer.window_get_position())
	var left := maxf(safe.position.x - origin.x, 0.0)
	var right := maxf(origin.x + window.x - safe.end.x, 0.0)
	var top := maxf(safe.position.y - origin.y, 0.0)
	var bottom := maxf(origin.y + window.y - safe.end.y, 0.0)
	return Vector2(maxf(left, right) * k.x, maxf(top, bottom) * k.y) + Vector2(COMFORT, COMFORT)
