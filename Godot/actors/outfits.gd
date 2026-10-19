class_name Outfits
extends RefCounted
## Character variants (docs/direction-artistique.md, « Variantes de personnages »): someone with
## an accessory, or in another position than walking. Drawn at the scale of the person's base
## sheet (tools/art-jobs/variantes.mjs), so they join the same SpriteFrames and keep its sprite
## scale. Which picture is shown:
## - Chloé on foot: in her down coat in a cold region (Region.cold: the Monts) once she has it,
##   else in Rosalie's walking boots once she has them (walk_look);
## - Chloé carried (Saddle): with Joss's mask under the sea (Player.diving), with the swimming
##   vest on a swimmer's back in the water, in her coat in a cold region, else as she is
##   (saddle_look);
## - a pose of a scene (Stage.pose): crouching, swimming on her own…, held until released,
##   turned where the actor looks (Player._animate);
## - another look for a scene (Stage.dress): Joss's jar at the lagoon.

const DIR := "res://assets/art/characters/%s.png"
## On foot: the prefix of her walk and idle animations in the boots (the key item). (Prefixes:
## the steps of sprite_motion.gd read the direction at the end of the name.)
const BOOTS := "bottes:"
const BOOTS_ITEM := "bottes"
const BOOTS_SHEET := "chloe_bottes"
## In a cold region: her down coat (hood lined with down, warm boots; the key item), on foot
## (chloe.png's grid) and in the saddle. Not drawn yet: as she is.
const COAT := "manteau:"
const COAT_ITEM := "manteau_duvet"
const COAT_SHEET := "chloe_manteau"
const COAT_POSE := "manteau_"   # (her poses of a scene in the coat: see POSES "coat")
## In the saddle: prefixes of her ride poses (Saddle.POSES) with an accessory, and their sheets
## (chloe_selle.png's grid; one not drawn yet is left out).
const MASK := "masque:"
const VEST := "gilet:"
const SADDLE_SHEETS := {MASK: "chloe_selle_masque", VEST: "chloe_selle_gilet", COAT: "chloe_selle_manteau"}
## In the air (Vol), on a pterosaur in Joss's harness: leaning forward, hands on the grips, hair
## blown back (chloe_vol.png: chloe_selle.png's grid, 4 columns, a 2nd row optional for the wind in
## her hair), in her coat in a cold region (chloe_vol_manteau.png). Not drawn yet: her saddle poses.
const FLIGHT := "vol:"
const FLIGHT_COAT := "vol_manteau:"
const FLIGHT_SHEETS := {FLIGHT: "chloe_vol", FLIGHT_COAT: "chloe_vol_manteau"}
const FLIGHT_CELL_H := 228.0
const FLIGHT_FPS := 3.0
## Poses drawn for a person (base sheet's name): pose -> its sheet, grid, the frames of each
## direction (down, left, right, up), fps; `afloat`: share of the drawing under the water line
## (on deep water, the picture is set at the surface).
## &"assis": sitting on the ground (knees up; Tante Sirocco cross-legged; the fisherman mending his
## net, the ex-henchman emptying his boot), Roc in his armchair (the chair is the room's prop).
## &"main": Chloé reaching one arm forward, palm open (offering her hand). &"grimpe": Chloé
## climbing onto a rock just in front of her (knee up, hands pressed down; draw the rock separately,
## she is drawn as if it were invisible). Maïa's &"accroupi": kneeling on one knee, like
## `chloe_accroupie`. `coat`: the same pose in her down coat (same grid), shown in a cold region
## once she has it (when drawn).
const POSES := {
	"chloe": {
		&"accroupi": {"sheet": "chloe_accroupie", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]],
			"coat": "chloe_manteau_accroupie"},
		&"nage": {"sheet": "chloe_nage", "cols": 4, "rows": 2, "frames": [[0, 4], [1, 5], [2, 6], [3, 7]], "fps": 2.5,
			"afloat": 0.48},
		&"assis": {"sheet": "chloe_assise", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]},
		&"main": {"sheet": "chloe_main", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]],
			"coat": "chloe_manteau_main"},
		&"grimpe": {"sheet": "chloe_grimpe", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]},
	},
	"maia": {
		&"assis": {"sheet": "maia_assise", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]},
		&"accroupi": {"sheet": "maia_accroupi", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]},
	},
	# Her own coat (AJOUT du 29/09) : once tools/zones/monts.gd gives her the maia_manteau sheet as
	# her base, Outfits.person() reads that sheet's name ("maia_manteau"), so her poses at the Monts
	# need their own entry here (same format as "maia").
	"maia_manteau": {
		&"assis": {"sheet": "maia_manteau_assise", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]},
	},
	# Élise digs in the pile on her KNEES, arms out in front of her (agenouille); accroupi is her
	# other low pose, on her heels.
	"elise": {
		&"accroupi": {"sheet": "elise_accroupie", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]},
		&"agenouille": {"sheet": "elise_agenouillee", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]},
	},
	"tante_sirocco": {&"assis": {"sheet": "tante_sirocco_assise", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]}},
	"roc": {&"assis": {"sheet": "roc_assis", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]}},
	"pecheur": {&"assis": {"sheet": "pecheur_assis", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]}},
	"sbire": {&"assis": {"sheet": "sbire_assis", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]}},
	# Chapter 8 (docs/direction-artistique.md § Plaine Volcanique): Brac on his cage (the cage is in the
	# picture); Léonce, a bone mask of the forges (sbire.png) with his mask on his knee: his Npc says
	# whose poses it wears (meta « person », see person()); Maïa in Joss's coat on her stone (the
	# stone is in the picture, its cell taller than her sheet's: lowered so their feet meet, _add_pose).
	"brac": {&"assis": {"sheet": "brac_assis_cage", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]}},
	"leonce": {&"assis": {"sheet": "leonce_assis", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]}},
	"maia_arche": {&"assis": {"sheet": "maia_pierre", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]}},
	# Chapter 9 (docs/direction-artistique.md § Hélène, docs/chapitre-9-scenes.md): Hélène sits on the ground
	# in the crater (helene_sol: held by Isaure, the scenes' Stage.sit), in Roc's armchair at the Cabinet: her
	# Npc there says it wears the armchair's poses (meta « person » « helene_fauteuil », tools/zones/cabinet.gd).
	# The armchair is the room's prop: her picture without it once drawn, else the one with it (`sheet`: a
	# list, the first drawn wins). Isaure without her mask, cross-legged (the 3rd version; the old one: _v2).
	"helene": {&"assis": {"sheet": "helene_sol", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]}},
	"helene_fauteuil": {&"assis": {"sheet": ["helene_assise_sans_fauteuil", "helene_assise"], "cols": 4, "rows": 2,
		"frames": [[0], [1], [2], [3]]}},
	"isaure_sans_masque": {&"assis": {"sheet": "isaure_sans_masque_assise", "cols": 4, "rows": 2, "frames": [[0], [1], [2], [3]]}},
}
## Other looks of a person for a scene: base sheet's name -> look -> sheet (same grid as it).
## Dame Suie without her smoked glasses (chapter 8, the great forge out: story/volcan_suie.gd); Isaure
## holding Maïa's cardboard mask in her hand (chapter 9, the jetty: story/apex_jetee.gd).
const LOOKS := {
	"joss": {&"bocal": "joss_bocal"},
	"dame_suie": {&"sans_lunettes": "dame_suie_sans_lunettes"},
	"isaure_sans_masque": {&"masque_carton": "isaure_masque_carton"},
}
const DIRS := ["down", "left", "right", "up"]
## Npc metas: whose poses it wears (person()); a pose it holds from the start, in its zone (Npc._ready:
## Léonce, the bone masks, Brac on his cage, Maïa on her stone), until a scene stands it up.
const PERSON_META := &"person"
const HELD_META := &"held_pose"


# ------------------------------------------------------------------ Chloé's accessories

## Adds her looks on foot to her frames (bottes:walk_<dir>, bottes:idle_<dir>; manteau:… once
## drawn).
static func dress_chloe(frames: SpriteFrames, fps: float) -> void:
	_merge(frames, SheetFrames.character(load(DIR % BOOTS_SHEET), fps), BOOTS)
	if drawn(COAT_SHEET):
		_merge(frames, SheetFrames.character(load(DIR % COAT_SHEET), fps), COAT)


## The prefix of her walk and idle animations: her coat in a cold region (Player.cold), else the
## boots once she has them.
static func walk_look(player: Player = null) -> String:
	if wears_coat(player) and drawn(COAT_SHEET):
		return COAT
	return BOOTS if Game.item_count(BOOTS_ITEM) > 0 else ""


## The prefix of her ride poses: the mask under the sea, the vest on a swimmer's back, the coat in
## a cold region.
static func saddle_look(player: Player) -> String:
	if player == null:
		return ""
	if player.diving:
		return MASK
	if player.swimmer and player.mount == null:
		return VEST
	if wears_coat(player) and drawn(SADDLE_SHEETS[COAT]):
		return COAT
	return ""


## The prefix of her poses in the air: her flight pictures (in her coat in a cold region), else
## her saddle's look (Saddle, in flight).
static func flight_look(player: Player) -> String:
	if player and wears_coat(player) and drawn(FLIGHT_SHEETS[FLIGHT_COAT]):
		return FLIGHT_COAT
	if drawn(FLIGHT_SHEETS[FLIGHT]):
		return FLIGHT
	return saddle_look(player)


## Adds her poses in the air (vol:<pose>, vol_manteau:<pose>) to `frames`, once drawn: `poses` are
## the columns of the flight sheets (Saddle.POSES); a 2nd row alternates with the first.
static func add_flight_looks(frames: SpriteFrames, poses: Array) -> void:
	for look: String in FLIGHT_SHEETS:
		if not drawn(FLIGHT_SHEETS[look]) or frames.has_animation(StringName(look + String(poses[0]))):
			continue
		var sheet: Texture2D = load(DIR % FLIGHT_SHEETS[look])
		var rows := maxi(1, roundi(sheet.get_height() / FLIGHT_CELL_H))
		var anims := {}
		for i in poses.size():
			anims[StringName(look + String(poses[i]))] = {"frames": [i, i + poses.size()] if rows > 1 else [i], "fps": FLIGHT_FPS}
		_merge(frames, SheetFrames.build(sheet, poses.size(), rows, anims), "")


## In a cold region with her down coat.
static func wears_coat(player: Player) -> bool:
	return player != null and player.cold and Game.item_count(COAT_ITEM) > 0


## Is that picture of characters/ there (a variant not drawn yet is left out)?
static func drawn(sheet: String) -> bool:
	return ResourceLoader.exists(DIR % sheet)


## A pose's sheet: its name, or the first drawn of a list of names (else the last one).
static func first_drawn(sheets) -> String:
	if sheets is String:
		return sheets
	for s: String in sheets:
		if drawn(s):
			return s
	return String(sheets[-1])


## Adds the ride poses with an accessory to `frames` (masque:<pose>, gilet:<pose>): `poses`
## are the columns of the saddle sheets.
static func add_saddle_looks(frames: SpriteFrames, poses: Array) -> void:
	for look: String in SADDLE_SHEETS:
		if not drawn(SADDLE_SHEETS[look]):
			continue
		var anims := {}
		for i in poses.size():
			anims[StringName(look + String(poses[i]))] = {"frames": [i], "fps": 1.0}
		_merge(frames, SheetFrames.build(load(DIR % SADDLE_SHEETS[look]), poses.size(), 1, anims), "")


# ------------------------------------------------------------------ poses of a scene

## Whose sheet the actor wears at heart ("chloe", "joss"…; "" when unknown). An Npc drawn with
## someone else's sheet says whose poses are its own with the meta « person » (Léonce: « leonce »,
## in a bone mask's sheet).
static func person(actor) -> String:
	if actor is Player:
		return "chloe"
	var npc := actor as Npc
	if npc:
		if npc.has_meta(PERSON_META):
			return String(npc.get_meta(PERSON_META))
		var base: Texture2D = npc.get_meta(&"base_sheet", npc.sheet)
		return base.resource_path.get_file().get_basename() if base else ""
	return ""


static func has_pose(actor, pose_name: StringName) -> bool:
	return (POSES.get(person(actor), {}) as Dictionary).has(pose_name)


## The animation of a pose turned `dir`; `look`: in another look (COAT_POSE: her coat).
static func pose_anim(pose_name: StringName, dir: String, look := "") -> StringName:
	return StringName("pose_%s%s_%s" % [look, pose_name, dir])


## Holds `pose_name` on the actor, turned as it looks (Chloé in her coat when she wears it and
## the pose is drawn so: POSES "coat"); &"" releases it. False when not drawn.
static func pose(actor, pose_name: StringName) -> bool:
	var sprite := Stage.sprite_of(actor) as AnimatedSprite2D
	if sprite == null:
		return false
	if pose_name == &"":
		_release(actor, sprite)
		return true
	var def: Dictionary = (POSES.get(person(actor), {}) as Dictionary).get(pose_name, {})
	if def.is_empty():
		return false
	var look := COAT_POSE if actor is Player and wears_coat(actor) and drawn(def.get("coat", "")) else ""
	_add_pose(sprite.sprite_frames, pose_name, def, look)
	var dir := _facing(actor, sprite)
	(actor as Node).set_meta(&"pose", pose_name)
	(actor as Node).set_meta(&"pose_look", look)
	sprite.play(pose_anim(pose_name, dir, look))
	_float(actor, sprite, float(def.get("afloat", -1.0)))
	return true


static func _add_pose(frames: SpriteFrames, pose_name: StringName, def: Dictionary, look := "") -> void:
	if frames.has_animation(pose_anim(pose_name, "down", look)):
		return
	var anims := {}
	for i in DIRS.size():
		anims[pose_anim(pose_name, DIRS[i], look)] = {"frames": def["frames"][i], "fps": def.get("fps", 1.0)}
	var sheet := first_drawn(def["coat"] if look == COAT_POSE else def["sheet"])
	var built := SheetFrames.build(load(DIR % sheet), def["cols"], def["rows"], anims)
	_feet_on_base(built, frames)
	_merge(frames, built, "")


## A pose sheet with taller cells than the person's own (Maïa's stone drawn under her): the sprite
## is centred, so its pictures get an empty margin below, as much as they are taller, and their
## feet meet the ground where the walking ones do (both sheets leave the same few pixels below).
static func _feet_on_base(built: SpriteFrames, frames: SpriteFrames) -> void:
	if not frames.has_animation(&"idle_down") or frames.get_frame_count(&"idle_down") == 0:
		return
	var base_h := frames.get_frame_texture(&"idle_down", 0).get_height()
	for anim in built.get_animation_names():
		for i in built.get_frame_count(anim):
			var atlas := built.get_frame_texture(anim, i) as AtlasTexture
			if atlas and atlas.region.size.y > base_h + 0.5:
				atlas.margin = Rect2(0.0, 0.0, 0.0, atlas.region.size.y - base_h)


static func _facing(actor, sprite: AnimatedSprite2D) -> String:
	if actor is Player:
		return SheetFrames.direction_name((actor as Player).facing)
	var parts := String(sprite.animation).split("_")
	var last: String = parts[parts.size() - 1]
	if last in DIRS:
		return last
	return String(actor.get("facing")) if actor.get("facing") in DIRS else "down"


## Floating: on deep water, the picture is lifted (or sunk) so the water line crosses it at
## `share` of its height; its shadow on the bottom is hidden.
static func _float(actor, sprite: AnimatedSprite2D, share: float) -> void:
	var view := (actor as Node).get_tree().get_first_node_in_group(&"world_view") as WorldView
	if share < 0.0 or view == null or view.heights == null:
		return
	var ground := view.heights.to_3d((actor as Node2D).global_position).y
	if ground >= HeightMap.WATER_LEVEL:
		return   # (not in the water)
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var drawn_m := SheetFrames.drawn_in(frame).size.y * absf(sprite.scale.y) / WorldView.PX * WorldView.STRETCH
	var up_m := HeightMap.WATER_LEVEL - ground - drawn_m * share
	sprite.position = Stage._rest(sprite) + Vector2(0.0, -up_m * WorldView.PX / WorldView.STRETCH)
	(actor as Node).set_meta(&"pose_afloat", (actor as Node).get_meta(&"cut_out", false))
	(actor as Node).set_meta(&"cut_out", true)   # (cut out, WorldView: the water hides what is under it)
	var shadow := (actor as Node).get_node_or_null("Shadow") as CanvasItem
	if shadow:
		shadow.visible = false


static func _release(actor, sprite: AnimatedSprite2D) -> void:
	var node := actor as Node
	if not node.has_meta(&"pose"):
		return
	var dir := _facing(actor, sprite)
	node.remove_meta(&"pose")
	node.remove_meta(&"pose_look")
	if node.has_meta(&"pose_afloat"):
		node.set_meta(&"cut_out", node.get_meta(&"pose_afloat"))
		node.remove_meta(&"pose_afloat")
		sprite.position = Stage._rest(sprite)
		var shadow := node.get_node_or_null("Shadow") as CanvasItem
		if shadow:
			shadow.visible = not (actor is Player and (actor as Player).carried_by())
	if not actor is Player:   # (her own _animate plays her idle again)
		sprite.play(StringName("idle_" + dir))


# ------------------------------------------------------------------ other looks

## Someone in another look for a scene (LOOKS), or back as usual (&""). False when not drawn.
static func dress(actor, look: StringName) -> bool:
	var npc := actor as Npc
	if npc == null or not is_instance_valid(npc):
		return false
	var base: Texture2D = npc.get_meta(&"base_sheet", npc.sheet)
	var sheet := base
	if look != &"":
		var name: String = (LOOKS.get(person(npc), {}) as Dictionary).get(look, "")
		if name == "":
			return false
		sheet = load(DIR % name)
	npc.set_meta(&"base_sheet", base)
	var anim := npc.sprite.animation
	npc.sheet = sheet
	npc.sprite.sprite_frames = SheetFrames.character(sheet)
	var scale := Vector2.ONE * Heights.sprite_scale(sheet)
	npc.sprite.scale = scale
	if npc.sprite.has_meta(&"stage_scale"):
		npc.sprite.set_meta(&"stage_scale", scale)
	npc.sprite.play(anim if npc.sprite.sprite_frames.has_animation(anim) else StringName("idle_" + npc.facing))
	return true


## Copies the animations of `from` into `frames`, their names preceded by `prefix`.
static func _merge(frames: SpriteFrames, from: SpriteFrames, prefix: String) -> void:
	for anim in from.get_animation_names():
		var name := StringName(prefix + String(anim))
		if frames.has_animation(name):
			continue
		frames.add_animation(name)
		frames.set_animation_speed(name, from.get_animation_speed(anim))
		frames.set_animation_loop(name, from.get_animation_loop(anim))
		for i in from.get_frame_count(anim):
			frames.add_frame(name, from.get_frame_texture(anim, i))
