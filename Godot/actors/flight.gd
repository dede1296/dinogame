class_name Flight
extends RefCounted
## Chloé in the air, on the back of a great pterosaur in Joss's flying harness (le Vol, chapter 7:
## story/vol.gd says when she may take off and land). One per flight, kept by the Player
## (Player.flight) while her flyer (Player.flyer) carries her.
## - Free and steered (Greg, 11/10): the eight directions of the stick or the keys, faster than on
##   foot, over everything — water, cliffs, woods, the void between the pitons — and nothing in the
##   zone stops her (her collision mask is empty); only the zone's edges hold her (clamped here).
## - Its height: CRUISE_M over the highest ground around her and where she is heading, climbing
##   fast before a rise and coming down slowly after it; a gentle bob with the wingbeats. The
##   pictures are lifted (sprite.position, which the 3D view turns into height), the shadows stay
##   on the ground; the camera rises with her (meta LIFT_META) and steps back a little.
## - The zone's edges: an open way out on the edge of the map is crossed as on foot (she is set
##   down at the next zone's arrival: Player.teleport ends the flight); a closed one pushes her back
##   in the air, with its words; a cave mouth or a door inside the map is not taken from the air.
## - A safe place under her is kept (safe_point): what the game saves while she flies, and where
##   she is set down if a scene starts in the air.

enum Phase { TAKING_OFF, FLYING, LANDING }

const PX := 48.0                 # 2D px per metre (HeightMap.PX)
const STRETCH := 1.15            # WorldView.STRETCH: the 3D view stretches pictures this much upwards
## Height over the highest ground around her (m), and how much of the ground around counts.
const CRUISE_M := 5.5
const AROUND_TILES := 1.6
const AHEAD_S := 0.45            # …and where she will be this soon
const RISE_M_S := 7.0
const SINK_M_S := 1.6
const TAKE_OFF_S := 0.8
const LAND_S := 0.7
const BOB_M := 0.12
const BOB_S := 1.4
## × her walking speed (Player.SPEED); held « run »: a dive forward, faster still.
const SPEED := 2.8
const DIVE_SPEED := 3.4
const ACCEL := 700.0
## The camera steps back this much (m) while she flies (WorldView.close_up, set by Vol), and its
## view rises with her: the share of her height it is lifted by (CameraRig turns the 2D camera's
## offset into its v_offset; seen from 40° up, a height h shows about 0.77 h up the view).
const CAMERA_BACK_M := 4.0
const CAMERA_LIFT_SHARE := 0.77
const LIFT_META := &"air_lift_m"
const SAFE_EVERY_S := 0.3
const EDGE_INSET := 4.0          # px inside the zone's edges
const BLOCKED_PUSH := 56.0       # a closed way out pushes her back this far (px)
## The wind in her ears, louder as she goes faster.
const WIND := preload("res://assets/audio/ambience/monts.ogg")   # (the clean low wind of the heights)
const WIND_DB := Vector2(-20.0, -8.0)   # still, full speed
const WIND_FADE_S := 0.6
## Its shadow is not drawn on ground more than this far below (the void, the sea of clouds).
const SHADOW_DROP_M := 9.0

var player: Player
var region: Region
var phase := Phase.TAKING_OFF
## Absolute height of the flyer's feet (m) once up, before the take-off and landing curve.
var altitude := 0.0
## Shown height over the ground under her (m): what lifts the pictures.
var lift := 0.0
## Ground under her (m), and where she could be set down (a landable point flown over).
var ground := 0.0
var safe_point := Vector2.ZERO
var _t := 0.0                    # time in the current phase (s)
var _bob_t := 0.0
var _safe_timer := 0.0
var _wind: AudioStreamPlayer
var _pushed_by := {}             # closed exits already told (their instance ids)


func _init(chloe: Player, zone: Region) -> void:
	player = chloe
	region = zone
	safe_point = chloe.global_position
	ground = _ground_at(chloe.global_position)
	altitude = _target_altitude(chloe.global_position, Vector2.ZERO)
	_start_wind()


# ------------------------------------------------------------------ each frame

## Called by the Player every physics frame of the flight, after she moved.
func update(delta: float) -> void:
	_t += delta
	_bob_t += delta
	var at := player.global_position
	ground = _ground_at(at)
	var target := _target_altitude(at, player.velocity)
	var rate := RISE_M_S if target > altitude else SINK_M_S
	altitude = move_toward(altitude, target, rate * delta)
	altitude = maxf(altitude, ground + CRUISE_M * 0.5)   # (never through a rise it did not see coming)
	var up := _up_share()
	var bob := sin(TAU * _bob_t / BOB_S) * BOB_M * up
	lift = maxf(0.0, (altitude - ground) * up + bob)
	player.set_meta(LIFT_META, lift)
	_lift_camera(lift)
	_track_safe_point(delta)
	_wind_level()


## The view rises with her: the 2D camera's offset, which the 3D camera follows (its v_offset), left
## alone while it shakes (an impact: GameCamera).
func _lift_camera(metres: float) -> void:
	var cam := player.get_node_or_null("Camera") as Camera2D
	if cam == null:
		return
	var shaking = cam.get(&"_shake_time")
	if shaking is float and shaking > 0.0:
		return
	cam.offset = Vector2(0.0, -metres * CAMERA_LIFT_SHARE * PX)


## 0 on the ground, 1 up in the air: the take-off and landing curves.
func _up_share() -> float:
	match phase:
		Phase.TAKING_OFF:
			if _t >= TAKE_OFF_S:
				phase = Phase.FLYING
				return 1.0
			return smoothstep(0.0, 1.0, _t / TAKE_OFF_S)
		Phase.LANDING:
			return 1.0 - smoothstep(0.0, 1.0, minf(_t / LAND_S, 1.0))
	return 1.0


## The pictures' lift (px of the 2D sprites, negative = up), as the 3D view reads it.
func lift_px() -> float:
	return -lift * PX / STRETCH


func is_landing() -> bool:
	return phase == Phase.LANDING


func is_up() -> bool:
	return phase == Phase.FLYING


## The landing has played out: she can get down.
func landed() -> bool:
	return phase == Phase.LANDING and _t >= LAND_S


func start_landing() -> void:
	phase = Phase.LANDING
	_t = 0.0
	_fade_wind()


## Her top speed in the air (px/s).
func top_speed(diving: bool) -> float:
	return Player.SPEED * (DIVE_SPEED if diving else SPEED)


## Is the shadow worth drawing under her (ground not too far below, not on the water)?
func shadow_shown() -> bool:
	return lift < SHADOW_DROP_M and region.surface_at(player.global_position) != &"water"


# ------------------------------------------------------------------ height of the ground

func _heights() -> HeightMap:
	var view := player.get_tree().get_first_node_in_group(&"world_view") if player.is_inside_tree() else null
	return view.get(&"heights") if view else null


## The ground (or the water's surface) under a point (m).
func _ground_at(p: Vector2) -> float:
	var hm := _heights()
	var h := hm.to_3d(p).y if hm else region.tile_height(Vector2i((p / PX).floor()))
	if region.surface_at(p) == &"water":
		h = maxf(h, HeightMap.WATER_LEVEL)
	return h


## The highest ground (or water) around a point, AROUND_TILES each way (m).
func _highest_around(p: Vector2) -> float:
	var t := p / PX
	var box := Rect2(t - Vector2.ONE * AROUND_TILES, Vector2.ONE * AROUND_TILES * 2.0)
	var hm := _heights()
	if hm:
		return maxf(hm.range_in(box).y, HeightMap.WATER_LEVEL)
	var high := -INF
	for y in range(floori(box.position.y), ceili(box.end.y)):
		for x in range(floori(box.position.x), ceili(box.end.x)):
			high = maxf(high, region.tile_height(Vector2i(x, y)))
	return maxf(high, HeightMap.WATER_LEVEL)


func _target_altitude(at: Vector2, velocity: Vector2) -> float:
	return maxf(_highest_around(at), _highest_around(at + velocity * AHEAD_S)) + CRUISE_M


# ------------------------------------------------------------------ the zone's edges

## Keeps her inside the zone; an open way out on its edge is taken, a closed one pushes her back.
## (Her collision mask is empty in the air: only this holds her.)
func after_move() -> void:
	var inside := region.bounds().grow(-EDGE_INSET)
	var at := player.global_position
	var held := at.clamp(inside.position, inside.end)
	if held != at:
		player.global_position = held
	if phase != Phase.FLYING:
		return
	for exit in region.exits():
		if region.exit_on_edge(exit) and region.exit_rect(exit).has_point(player.global_position):
			_cross(exit)
			return


func _cross(exit: ZoneExit) -> void:
	if exit.is_open():
		# (when: the next zone's arrival scene can tell she came flying, Vol.came_flying)
		player.set_meta(Vol.CROSSED_META, Time.get_ticks_msec())
		exit.taken.emit(exit)   # (the world changes zone; arriving sets her down: Player.teleport)
		return
	var back := (region.bounds().get_center() - player.global_position).normalized() * BLOCKED_PUSH
	player.global_position += back
	player.velocity = Vector2.ZERO
	if _pushed_by.has(exit.get_instance_id()) or exit.blocked_dialogue == &"":
		return
	_pushed_by[exit.get_instance_id()] = true
	_tell_blocked(exit.blocked_dialogue)


func _tell_blocked(dialogue: StringName) -> void:
	player.busy = true
	await Dialogue.run(DialogueDB.lines(dialogue))
	player.busy = false


# ------------------------------------------------------------------ a safe place under her

func _track_safe_point(delta: float) -> void:
	_safe_timer -= delta
	if _safe_timer > 0.0:
		return
	_safe_timer = SAFE_EVERY_S
	if Vol.landing_problem(region, player.global_position, player) == "":
		safe_point = player.global_position


# ------------------------------------------------------------------ the wind

func _start_wind() -> void:
	if not player.is_inside_tree():
		return
	_wind = AudioStreamPlayer.new()
	_wind.name = "FlightWind"
	var stream := WIND.duplicate() as AudioStream
	if &"loop" in stream:
		stream.set(&"loop", true)
	_wind.stream = stream
	_wind.bus = &"Ambience"
	_wind.volume_db = -60.0
	player.add_child(_wind)
	_wind.play()
	player.create_tween().tween_property(_wind, "volume_db", WIND_DB.x, WIND_FADE_S)


func _wind_level() -> void:
	if _wind == null or phase == Phase.LANDING:
		return
	var speed := clampf(player.velocity.length() / top_speed(false), 0.0, 1.0) * _up_share()
	_wind.volume_db = lerpf(_wind.volume_db, lerpf(WIND_DB.x, WIND_DB.y, speed), 0.08)


func _fade_wind() -> void:
	if _wind == null or not is_instance_valid(_wind):
		return
	var wind := _wind
	var t := wind.create_tween()
	t.tween_property(wind, "volume_db", -60.0, WIND_FADE_S)
	t.tween_callback(wind.queue_free)
	_wind = null


## The flight is over (landed, or set down at once): the wind, the camera's lift.
func finish() -> void:
	_fade_wind()
	if not is_instance_valid(player):
		return
	if player.has_meta(LIFT_META):
		player.remove_meta(LIFT_META)
	_lift_camera(0.0)
