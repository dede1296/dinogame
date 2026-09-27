class_name SpriteMotion
## Life for sprites drawn with few pictures (3 or 4 a walk cycle): motion computed on top of
## them. Walking, a little hop at each step drawn, and a squash when the foot lands; standing,
## slow breathing. Scaled around the feet (the node's origin), so they stay planted; the
## ground shadow does not hop.
## A hop for each step drawn in the cycle (one, or as the sheet says: SheetFrames.STEPS_META),
## timed on the pictures themselves: the body is highest on the picture where the legs pass
## each other (see _peak), and a foot lands half a step later.

const HOP := 0.035          # hop height, share of the picture's height
const SQUASH := 0.05        # squash when a foot lands
const BREATH := 0.012       # breathing, share of the height
const BREATH_S := 2.6       # one breath (s)
const WALK_PX_S := 90.0     # from this speed on, the whole walking motion
const EASE := 10.0          # how fast it goes from standing to walking and back
const FEET_BAND := 0.12     # the bottom of the drawing where the feet are (share of its height)

## Off: the pictures alone (to compare, tools/capture.gd).
static var enabled := true
## Per walk animation of a sheet: where in its cycle (0 to 1) the legs pass each other.
static var _peaks := {}


## Moves and squashes `vis` (already placed and scaled like its 2D sprite). Returns the hop
## (m), which a rider takes from its mount. `p`: the proxy, where its state is kept.
static func apply(p: Dictionary, sprite: AnimatedSprite2D, vis: SpriteBase3D, delta: float) -> float:
	if not enabled:
		return 0.0
	var speed := (p["cur"] as Vector2).distance_to(p["prev"]) * Engine.physics_ticks_per_second
	var walking: float = lerpf(p.get("walking", 0.0), clampf(speed / WALK_PX_S, 0.0, 1.0), 1.0 - exp(-EASE * delta))
	p["walking"] = walking
	if not p.has("breath"):
		p["breath"] = randf() * TAU   # not all breathing together
	var frames := sprite.sprite_frames
	if frames == null or not frames.has_animation(sprite.animation):
		return 0.0
	var count := frames.get_frame_count(sprite.animation)
	var texture := frames.get_frame_texture(sprite.animation, sprite.frame)
	var height := (texture.get_height() if texture else 0) * vis.pixel_size * vis.scale.y
	var hop := 0.0
	var land := 0.0
	if count > 1:   # a single picture (sitting in the saddle) has no steps of its own
		var t := (sprite.frame + sprite.frame_progress) / float(count)
		var steps: int = frames.get_meta(SheetFrames.STEPS_META, {}).get(sprite.animation, 1)
		var up := 0.5 + 0.5 * cos(TAU * steps * (t - _peak(frames, sprite.animation)))
		hop = up * walking * HOP * height
		land = pow(1.0 - up, 3.0) * walking * SQUASH
	var breath := sin(TAU * Time.get_ticks_msec() / 1000.0 / BREATH_S + float(p["breath"])) * BREATH * (1.0 - walking)
	vis.position.y += hop
	vis.scale = Vector3(vis.scale.x * (1.0 + land * 0.5 - breath * 0.4), vis.scale.y * (1.0 - land + breath), vis.scale.z)
	return hop


## Where in the cycle of `anim` the legs pass each other: the middle of the picture whose
## feet take the least room seen from the side, or the most seen from the front or the back
## (there, a foot stepping forward sits lower than the other and leaves the bottom band).
## Measured once per sheet and animation.
static func _peak(frames: SpriteFrames, anim: StringName) -> float:
	var first := frames.get_frame_texture(anim, 0) as AtlasTexture
	var key := "%s:%s" % [first.atlas.resource_path if first and first.atlas else str(frames.get_instance_id()), anim]
	if _peaks.has(key):
		return _peaks[key]
	var count := frames.get_frame_count(anim)
	var front_back := String(anim).ends_with("_down") or String(anim).ends_with("_up")
	var best := 0
	var best_width := -1.0
	for i in count:
		var width := _feet_width(frames.get_frame_texture(anim, i))
		if best_width < 0.0 or (width > best_width if front_back else width < best_width):
			best_width = width
			best = i
	var peak := (best + 0.5) / float(count)
	_peaks[key] = peak
	return peak


## Width (px) of the drawing at its feet: the bottom FEET_BAND of what is not transparent.
static func _feet_width(texture: Texture2D) -> float:
	var image := texture.get_image() if texture else null
	if image == null:
		return 0.0
	if image.is_compressed():
		image.decompress()
	var used := image.get_used_rect()
	var top := used.end.y - maxi(1, int(used.size.y * FEET_BAND))
	var left := used.end.x
	var right := used.position.x
	for y in range(top, used.end.y):
		for x in range(used.position.x, used.end.x, 2):
			if image.get_pixel(x, y).a > 0.5:
				left = mini(left, x)
				right = maxi(right, x)
	return maxf(0.0, right - left)
