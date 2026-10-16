class_name Saddle
extends RefCounted
## Chloé on her mount (Player.mount), or on her swimmer's back in deep water (Player.swimmer),
## carried by the Companion: where she sits for each way
## it is seen, and her pictures in the saddle (chloe_selle.png: sitting astride, from the
## front, facing left, facing right, from behind). From the side, the mount stands behind
## her: her near leg hangs on its flank. From behind too (her legs on each side of its body).
## From the front, the mount stands a hair nearer the camera, its head before her waist.
## Both are cut out (WorldView._sync), so they are sorted by depth, never blended.
## A big mount shrinks as she climbs on, to DinoSize.MOUNT_MAX_M (and grows back as she gets
## down, Companion): the saddle is measured on its pictures at scale 1, and place() follows
## the scale it has at that moment.

const SHEET := preload("res://assets/art/characters/chloe_selle.png")
const POSES := [&"ride_down", &"ride_left", &"ride_right", &"ride_up"]   # columns of SHEET
## Where she sits on her picture: px of SHEET above the bottom of a frame (the seat of her
## shorts), for each pose.
const SEAT_PX := {&"ride_down": 70.0, &"ride_left": 68.0, &"ride_right": 68.0, &"ride_up": 64.0}
## Where the saddle is on the mount's pictures, as shares of them. "side": [towards its
## head, height of its back]; "front", "back": height of its back seen that way (from the
## front, high enough that its head or frill does not hide her face).
const SEATS := {
	&"parasaurolophus": {"side": Vector2(-0.09, 0.68), "front": 0.84, "back": 0.64},
	&"triceratops": {"side": Vector2(-0.12, 0.66), "front": 0.86, "back": 0.64},
	&"ankylosaurus": {"side": Vector2(0.0, 0.72), "front": 0.6, "back": 0.6},
	# The swimmers (Swim): on the back just behind the shoulders; the Spinosaurus's sail
	# stands behind her, so she sits in front of it, at the foot of its neck.
	&"baryonyx": {"side": Vector2(0.03, 0.64), "front": 0.8, "back": 0.62},
	&"suchomimus": {"side": Vector2(0.03, 0.62), "front": 0.8, "back": 0.62},
	&"spinosaurus": {"side": Vector2(0.13, 0.58), "front": 0.8, "back": 0.6},
	# The sea reptiles (Swim, Dive): on the back, behind the neck (to check on their pictures).
	&"plesiosaurus": {"side": Vector2(0.06, 0.6), "front": 0.7, "back": 0.6},
	&"ichthyosaurus": {"side": Vector2(0.02, 0.64), "front": 0.72, "back": 0.62},
	&"elasmosaurus": {"side": Vector2(0.1, 0.58), "front": 0.7, "back": 0.6},
	&"archelon": {"side": Vector2(-0.02, 0.66), "front": 0.64, "back": 0.62},
}
const SEAT_DEFAULT := {"side": Vector2(0.0, 0.68), "front": 0.62, "back": 0.64}
## In the air (Vol), on a pterosaur's flight pictures (Wings): on its back between the wings, as
## shares of a flight picture (the body lies across its middle). From the front, just behind its head,
## her legs on each side of its neck: high enough that its head does not hide her face, and its crest
## (a blade raised before her) stops under her chin with its wings flat (16/10: at 0.46 its head hid her
## face; measured by tools/test_vol.gd only=photo, flyer=<species> for the others). Per species when
## they need it.
const FLY_SEATS := {}
const FLY_SEAT_DEFAULT := {"side": Vector2(-0.08, 0.5), "front": 0.62, "back": 0.5}
## In the air she is drawn smaller than on foot (Greg, 11/10: « trop grande par rapport au dino ») :
## a pterosaur's body is slender, and she must not be as tall as it is thick.
const FLY_RIDER_SCALE := 0.8
## Her flight pictures are not all drawn on the middle of their frames (her ponytail, blown to one
## side, widened the drawing): px of each sheet her body stands left of the middle, from the front and
## from behind, put back so she sits on the pterosaur's axis (measured on her bust and legs, 16/10;
## checked on screen by tools/test_vol.gd only=photo). Per look (Outfits.flight_look).
const FLY_BODY_X := {
	Outfits.FLIGHT: {&"ride_down": 14.0, &"ride_up": 4.5},
	Outfits.FLIGHT_COAT: {&"ride_down": 5.5, &"ride_up": 0.5},
}
const DEPTH := 2.0   # px the mount stands nearer the camera (+) or farther (-) than her

var _side := Vector2.ZERO   # the saddle, px from the mount's feet (facing right), at scale 1
var _front := 0.0
var _back := 0.0
var _seat := {}             # pose -> px from Chloé's feet (her node) down to where she sits
var _rider: AnimatedSprite2D   # her picture (its Player: the mask, the vest, Outfits.saddle_look)
var _base_scale := Vector2.ONE   # her picture's scale on foot, put back by release()
var _rider_scale := 1.0          # the share of it she has on this mount (FLY_RIDER_SCALE in the air)
var _flying := false        # on a pterosaur in the air (Vol): its flight pictures, her flight poses


## Computes the saddle on `species` and adds Chloé's sitting pictures to `rider`'s frames;
## `flying`: in the air, on its flight pictures (Wings) when they are drawn.
func _init(species: DinoSpecies, rider: AnimatedSprite2D, flying := false) -> void:
	_flying = flying
	_base_scale = rider.scale
	_rider_scale = FLY_RIDER_SCALE if flying else 1.0
	var cell := Vector2(species.sheet.get_width() / float(species.sheet_columns), species.sheet.get_height() / float(species.sheet_rows))
	if flying and Wings.drawn(species):
		_seat_in_flight(species, cell.y)
	else:
		_seat_on(species, cell)
	# Her frames are centred on rider.offset: the seat, from her node, for each pose.
	var frame_h := float(SHEET.get_height())
	for pose: StringName in POSES:
		_seat[pose] = (rider.offset.y + frame_h / 2.0 - float(SEAT_PX[pose])) * rider.scale.y * _rider_scale
	_add_poses(rider.sprite_frames)
	Outfits.add_saddle_looks(rider.sprite_frames, POSES)   # the same poses with the mask, the vest
	if flying:
		Outfits.add_flight_looks(rider.sprite_frames, POSES)   # (chloe_vol*.png, once drawn)
	_rider = rider


## The saddle on its walking pictures (`cell`: one of its side sheet).
func _seat_on(species: DinoSpecies, cell: Vector2) -> void:
	var def: Dictionary = SEATS.get(species.id, SEAT_DEFAULT)
	var side: Vector2 = def["side"]
	# The mount's pictures are centred 0.46 of a side picture above its feet (Companion.refresh).
	_side = Vector2(cell.x * side.x, -_height(cell.y, cell.y, side.y))
	var face_h := cell.y
	if species.face_back_sheet:
		face_h = species.face_back_sheet.get_height() / 2.0
	_front = -_height(cell.y, face_h, def["front"])
	_back = -_height(cell.y, face_h, def["back"])


## The harness on its flight pictures, centred where its walking ones are (`side_h`: one of those).
func _seat_in_flight(species: DinoSpecies, side_h: float) -> void:
	var def: Dictionary = FLY_SEATS.get(species.id, FLY_SEAT_DEFAULT)
	var cell: Vector2 = Wings.cell(species)
	var side: Vector2 = def["side"]
	_side = Vector2(cell.x * side.x, -_height(side_h, cell.y, side.y))
	_front = -_height(side_h, cell.y, def["front"])
	_back = -_height(side_h, cell.y, def["back"])
	if Wings.face_back_drawn(species):
		var fb_h: float = load(Wings.FACE_BACK % species.id).get_height() / 2.0
		_front = -_height(side_h, fb_h, def["front"])
		_back = -_height(side_h, fb_h, def["back"])


## Height above the mount's feet of a share `share` of a picture `picture` high.
static func _height(side_height: float, picture: float, share: float) -> float:
	return side_height * 0.46 - picture * 0.5 + picture * share


## Chloé gets down: her picture is back to its size on foot.
func release() -> void:
	if is_instance_valid(_rider):
		_rider.scale = _base_scale


## For the mount playing `anim` (flipped: facing left) at sprite scale `size`: Chloé's pose,
## where her picture goes, and where the mount stands from her (px, towards the camera).
func place(anim: StringName, flipped: bool, size: float) -> Dictionary:
	if is_instance_valid(_rider):
		_rider.scale = _base_scale * _rider_scale
	var pose: StringName = &"ride_left" if flipped else &"ride_right"
	var at := Vector2(-_side.x if flipped else _side.x, _side.y) * size
	var depth := -DEPTH
	if String(anim).ends_with("_down"):
		pose = &"ride_down"
		at = Vector2(0, _front * size)
		depth = DEPTH
	elif String(anim).ends_with("_up"):
		pose = &"ride_up"
		at = Vector2(0, _back * size)
	var chloe := _rider.get_parent() as Player if is_instance_valid(_rider) else null
	var look: String = Outfits.flight_look(chloe) if _flying else Outfits.saddle_look(chloe)
	if _flying and is_instance_valid(_rider):
		at.x += float(FLY_BODY_X.get(look, {}).get(pose, 0.0)) * _rider.scale.x
	return {"pose": StringName(look + String(pose)), "at": at - Vector2(0, _seat[pose]), "depth": depth}


static func _add_poses(frames: SpriteFrames) -> void:
	var cell := Vector2(SHEET.get_width() / float(POSES.size()), SHEET.get_height())
	for i in POSES.size():
		var pose: StringName = POSES[i]
		if frames.has_animation(pose):
			continue
		frames.add_animation(pose)
		frames.set_animation_speed(pose, 1.0)
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = Rect2(Vector2(i * cell.x, 0), cell)
		frames.add_frame(pose, atlas)
