extends RefCounted
## La Terre des Apex (chapter 9) and the epilogue: the decor shared by the plans (tools/zones/apex_terre.gd,
## apex_coeur.gd, and the epilogue's additions in cabinet.gd, port_ambre.gd, volcan_porte.gd): the
## pictures wanted, each with its stand-ins (docs/chapitre-9-scenes.md « Personnages, doublures, images
## nécessaires »); the first one Prop.KINDS knows is placed (volcan_decor.gd kind(): its « pretend » list
## also serves the scratch checks), nothing when none is drawn. The people: their sheet, or a stand-in
## (tinted) while the agent IMAGES has not drawn them. The climate of the crater.

const B := preload("res://tools/zone_builder.gd")
const VD := preload("res://tools/zones/volcan_decor.gd")
const CHARS := "res://assets/art/characters/%s.png"
const FLAGGED_PROP := "res://world/flagged_prop.gd"

## The props (contract names first, then stand-ins already drawn).
const BLOC_SOUVERAIN := ["bloc_souverain", "crane_geant_desert"]
const BLOC_ECLATE := ["bloc_souverain_eclate", "cristaux"]
const BLOCS_GEANTS := [["bloc_geant_1", "squelette_geant"], ["bloc_geant_2", "squelette_geant"],
	["bloc_geant_3", "squelette_geant"], ["bloc_geant_4", "os_geant"]]
const CAIRN := ["cairn_helene", "pierre_plate"]
const ISAURE_HELENE := ["isaure_helene"]
const CRISTAUX := ["cristaux"]
const ROCHER_ABRI := ["rocher"]
const PORTAIL_OUVERT := ["portail_apex_ouvert"]
const TORCHE_ETEINTE := ["torche_eteinte"]
const TASSE := ["tasse_bleue"]
const CAISSE_CARNETS := ["caisse_carnets"]
const TABLE := ["table_cuisine"]
## The people (sheets, contract names first) and their stand-in's tint while only a stand-in is drawn.
const HELENE := ["helene", "pervenche"]
const HELENE_TINT := Color(0.84, 0.9, 1.0)
const FIRMIN := ["firmin", "sbire"]   # (« sans masque » at the jetty: a sheet to draw; his masked one meanwhile)
## The species: the Souverain (agent MÉCANIQUES), or a big theropod meanwhile; his size in the scenes
## (« ×1,5 en scène, trop grand pour l'écran »), and the stand-in's (smaller species).
const SOUVERAIN := &"souverain"
const SOUVERAIN_STAND_IN := &"trex_magma"
const SOUVERAIN_SIZE := 1.5
const SOUVERAIN_STAND_IN_SIZE := 1.8
## The Roi des Cieux (the Quetzalcoatlus of the Nids géants, his size there).
const ROI := &"quetzalcoatlus"
const ROI_SIZE := 1.3
## The rocks and pebbles of the crater's open ground (volcan_decor.gd scatter's table format).
const BLACK_ROCK := [
	["rocher_grotte", 0.006, ""], ["cailloux", 0.009, ""], ["rocher", 0.002, ""], ["cristaux", 0.0008, ""],
]
## Just south of a trail or a kept place (the camera looks north): low things only, and no plant (« de la
## roche noire » : the ash ferns of volcan_decor.gd LOW stay in the volcano).
const LOW := [["cailloux", 0.010, ""]]

## The battles' backdrop (agent IMAGES: the round hall, its veins), the volcano's meanwhile.
const BACKDROP := ["res://assets/art/battle/apex.jpg", "res://assets/art/battle/volcan.jpg"]
## The flight is refused in the crater (the spiral is walked down, the fond is a hall): what it says.
const NO_FLIGHT := "Ton ptérosaure regarde le fond du cratère, et replie ses ailes. Ici, on descend à pied."


static func kind(wanted: Array) -> String:
	return VD.kind(wanted)


static func put(entities: Node2D, wanted: Array, t: Vector2, flip := false, script: Script = null) -> Node2D:
	return VD.put(entities, wanted, t, flip, script)


static func story_prop(entities: Node2D, wanted: Array, t: Vector2, node_name: String, event: StringName, opts := {}) -> Node2D:
	return VD.story_prop(entities, wanted, t, node_name, event, opts)


static func flagged(entities: Node2D, wanted: Array, t: Vector2, node_name: String, show: StringName, hide: StringName,
		flip := false) -> Node2D:
	return VD.flagged(entities, wanted, t, node_name, show, hide, flip)


## The first of `sheets` drawn (characters), and whether it is the wanted one (the first).
static func sheet(sheets: Array) -> Array:
	for i in sheets.size():
		if ResourceLoader.exists(CHARS % sheets[i]):
			return [CHARS % sheets[i], i == 0]
	return [CHARS % sheets[-1], false]


## A person of the story (actors/npc.tscn) in `sheets` (or its stand-in, tinted `tint`); `opts` as
## zone_builder.gd npc(); `sitting`: holds the pose « assis » from the start (once drawn for that sheet).
static func person(root: Region, node_name: String, display_name: String, sheets: Array, t: Vector2, opts := {},
		tint := Color.WHITE, sitting := false) -> Node:
	var s := sheet(sheets)
	var o := opts.duplicate()
	if not s[1]:
		o["tint"] = tint
	var n := B.npc(root, node_name, display_name, s[0], t.x, t.y, o)
	if sitting:
		n.set_meta(Outfits.HELD_META, &"assis")
	return n


## The species `wanted`, or `stand_in` while its sheet is not in SpeciesDB.
static func species(wanted: StringName, stand_in: StringName) -> StringName:
	return VD.species(wanted, stand_in)


## The Souverain (DinoNpc) at `t`: his species or the stand-in, at his size in the scenes.
static func souverain(root: Region, node_name: String, t: Vector2, opts := {}) -> Node:
	var sp := species(SOUVERAIN, SOUVERAIN_STAND_IN)
	var o := opts.duplicate()
	o["size"] = SOUVERAIN_SIZE if sp == SOUVERAIN else SOUVERAIN_STAND_IN_SIZE
	return B.dino_npc(root, node_name, sp, t.x, t.y, o)


## Hélène's page `n` at tile `t` (Pickup « Page<n> »: found_journal_<n>, its lines page_<n>).
static func page(entities: Node2D, n: int, t: Vector2) -> Node2D:
	return VD.page(entities, n, t)


## The climate of a zone of the crater: its sounds (`ambience`; music: the first of `music` drawn, else
## silence), its backdrop, a little mist now and then, never rain nor snow, no flight.
static func climate(root: Region, ambience: StringName, music: Array, mist: float) -> void:
	var tune := _first(music)
	root.music = load(tune) if tune != "" else null
	root.ambience_id = ambience
	var backdrop := _first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	root.rain_chance = 0.0
	root.storm_chance = 0.0
	root.sandstorm_chance = 0.0
	root.mist_chance = mist
	root.snow_chance = 0.0
	root.blizzard_chance = 0.0
	root.set_meta(&"vol_interdit", true)
	root.set_meta(&"vol_interdit_texte", NO_FLIGHT)


static func _first(paths: Array) -> String:
	for p: String in paths:
		if ResourceLoader.exists(p):
			return p
	return ""


## Rocks and pebbles of `table` on the open ground (volcan_decor.gd scatter, with LOW): not on or by a
## path, not on a step, not in `keep` rects; low things only just south of the trails and of `keep`.
static func scatter(c, entities: Node2D, rng: RandomNumberGenerator, keep: Array, table: Array, density := 1.0) -> void:
	var paths: PackedInt32Array = c.distance_to(func(x: int, y: int) -> bool: return c.ground_at(x, y) == "path")
	for y in c.h:
		for x in c.w:
			if c.ground_at(x, y) != "grass" or paths[y * c.w + x] <= 1:
				continue
			if VD._kept_clear(keep, Vector2(x + 0.5, y + 0.5)) or not VD._steady(c, x, y):
				continue
			var rows: Array = LOW if VD._in_view(c, keep, x, y) else table
			for row: Array in rows:
				if rng.randf() < float(row[1]) * density:
					put(entities, [row[0], row[2]], Vector2(x + rng.randf_range(0.25, 0.75), y + rng.randf_range(0.35, 0.85)), rng.randf() < 0.5)
					break


## Amber crystals (lit) along the veins `lines` (tiles), one every `every` tiles or so, on level open
## ground (not on a path, not in `keep`).
static func crystals(c, entities: Node2D, rng: RandomNumberGenerator, lines: Array, every: float, keep: Array) -> void:
	for pts: Array in lines:
		var run := rng.randf_range(0.0, every)
		for k in pts.size() - 1:
			var a: Vector2 = pts[k]
			var b: Vector2 = pts[k + 1]
			var length := a.distance_to(b)
			while run < length:
				var at := a.lerp(b, run / length) + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.4, 0.4))
				var cell := Vector2i(at.floor())
				if c.inside(cell.x, cell.y) and c.ground_at(cell.x, cell.y) == "grass" and VD._steady(c, cell.x, cell.y) \
						and not keep.any(func(r: Rect2) -> bool: return r.has_point(at)):
					put(entities, CRISTAUX, at, rng.randf() < 0.5)
				run += every * rng.randf_range(0.7, 1.3)
			run -= length
