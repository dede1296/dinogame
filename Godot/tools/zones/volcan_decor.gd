extends RefCounted
## La Plaine Volcanique (chapter 8): the decor shared by the plans of its five zones
## (tools/zones/volcan_*.gd): the scattered rocks, burnt trunks and ash ferns, the fires, the story's
## props (StoryProp, FlaggedProp), the dinos of the scenes. Pictures: the contract's names first
## (docs/chapitre-8-scenes.md « Personnages, doublures, images nécessaires »), then a stand-in already
## in Prop.KINDS while the agent IMAGES has not drawn them; nothing when neither exists. Species: the
## chapter's, or a stand-in of the same family while their sheets are not in SpeciesDB (the zones are
## built again once they are).

const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/volcan_canvas.gd")
const STORY_PROP := "res://world/story_prop.gd"
const FLAGGED_PROP := "res://world/flagged_prop.gd"
const SIGN := "res://world/sign.gd"
const PICKUP := "res://world/pickup.gd"
## The pictures wanted, each with its stand-ins (the first that Prop.KINDS knows is placed). The agent
## IMAGES drew them all (17/10, docs/direction-artistique.md § Plaine Volcanique); they are placed once
## world/prop.gd lists them (scratchpad patch_carte.md), the zones built again.
const FORGE := ["forge_allumee", "autel"]
## Each small forge once out (StoryProp after_kind): knocked over, its bellows torn off, its barrel in it.
const FORGES_ETEINTES := [["forge_eteinte"], ["forge_eteinte_2", "forge_eteinte"], ["forge_eteinte_3", "forge_eteinte"]]
const GRANDE_FORGE := ["grande_forge_allumee", "phare_ruine"]
const CAGE := ["cage_fermee", "cage"]
const CAGE_OUVERTE := ["cage_ouverte", "cage"]
const CAGE_GRANDE := ["cage_grande", "cage"]
const FUT := ["fut_ambre_noir", "caisse_ambre_noir"]
const FUT_RENVERSE := ["fut_renverse", "fut_ambre_noir", "caisse_ambre_noir"]
const PIERRE_PLATE := ["pierre_plate_volcan", "pierre_plate"]
const ENCLUME := ["enclume"]
const AUVENT := ["auvent"]
const SOUFFLET := ["soufflet"]
const MARMITE := ["marmite", "bouilloire_poele"]
const BARRICADE := ["barricade", "rempart_eboulis"]
const BARRICADE_TOMBEE := ["barricade_tombee", "cloture_brisee"]
const ETABLI := ["etabli_suie", "etabli"]
const GANTS := ["gants_gris"]
const TRAINEAU := ["traineau_roues", "traineau_suie"]
const FIOLES := ["fioles_suie"]
const MASQUE_OS := ["masque_os_sol", "masque_pierre"]
const PLAQUE := ["plaque_fer"]
const VASQUE := ["vasque_source", "flaque_ronde"]
const AUTEL := ["autel_magma", "autel"]
const LAVE_PAROI := ["lave_paroi", "mur_fissure"]
const COQUE := ["coque_lave"]
const PORTAIL := ["portail_apex", "porte_vents"]
const TORCHE := ["torche", "lanterne"]
const CAMP_HELENE := ["camp_helene", "natte_fouilles"]
## What stands on the open ground (scatter): [kind, chance per tile, stand-in] — the first row that
## wins the roll is placed. LOW: just south of a trail or a kept place (the camera looks north: nothing
## taller than Chloé there).
const ASH_FIELDS := [
	["rocher", 0.005, ""], ["rocher_grotte", 0.004, ""], ["tronc_calcine", 0.006, ""], ["fougere_cendre", 0.012, ""],
	["cailloux", 0.009, ""],
]
const BLACK_ROCK := [
	["rocher_grotte", 0.007, ""], ["rocher", 0.004, ""], ["cailloux", 0.010, ""], ["tronc_calcine", 0.002, ""],
	["cristaux", 0.0012, ""],
]
const LOW := [["fougere_cendre", 0.012, ""], ["cailloux", 0.010, ""]]
## Just south of a trail or a kept place, over this many rows: low things only.
const VIEW_SHADOW := 5


## Kinds drawn but not yet in Prop.KINDS, with the entry proposed for them: only a scratch check fills
## it (to measure the zones as they will be once world/prop.gd lists them); empty in a real build.
static var pretend := {}


## The kind of `wanted`, or the first of its stand-ins that Prop.KINDS knows ("" when none does).
static func kind(wanted: Array) -> String:
	for k: String in wanted:
		if k != "" and (Prop.KINDS.has(k) or pretend.has(k)):
			return k
	return ""


## The entry of `kind_` (Prop.KINDS, or `pretend`), {} when unknown.
static func def(kind_: String) -> Dictionary:
	return Prop.KINDS.get(kind_, pretend.get(kind_, {}))


## A prop of `wanted` (or its stand-in) at tile point `t`; null when none is drawn.
static func put(entities: Node2D, wanted: Array, t: Vector2, flip := false, script: Script = null) -> Node2D:
	var k := kind(wanted)
	if k == "":
		return null
	return B.prop(entities, k, B.cell(t.x, t.y), flip, script)


## A piece of the story's scenery (StoryProp) named `node_name`: `event` when Chloé interacts,
## `opts`: show_flag, hide_flag, after_flag + after (the pictures it becomes then: kept only once
## drawn), flip. Null when neither its picture nor a stand-in exists.
static func story_prop(entities: Node2D, wanted: Array, t: Vector2, node_name: String, event: StringName, opts := {}) -> Node2D:
	var p: Node2D = put(entities, wanted, t, opts.get("flip", false), load(STORY_PROP))
	if p == null:
		return null
	p.name = node_name
	p.event = event
	p.show_flag = opts.get("show_flag", &"")
	p.hide_flag = opts.get("hide_flag", &"")
	var after := kind(opts.get("after", []))
	if after != "":
		p.after_flag = opts.get("after_flag", &"")
		p.after_kind = after
	return p


## A piece of scenery shown or hidden by a flag (FlaggedProp), named `node_name`.
static func flagged(entities: Node2D, wanted: Array, t: Vector2, node_name: String, show: StringName, hide: StringName,
		flip := false) -> Node2D:
	var p: Node2D = put(entities, wanted, t, flip, load(FLAGGED_PROP))
	if p == null:
		return null
	p.name = node_name
	p.show_flag = show
	p.hide_flag = hide
	return p


## A sign of `kind_` (a signpost, an engraved stone) that shows the lines `dialogue_id`.
static func sign_of(entities: Node2D, kind_: String, t: Vector2, dialogue_id: StringName, node_name: String) -> Node2D:
	var s: Node2D = B.prop(entities, kind_, B.cell(t.x, t.y), false, load(SIGN))
	s.name = node_name
	s.dialogue_id = dialogue_id
	return s


## Hélène's page `n` at tile `t` (taken_flag found_journal_<n>, its lines page_<n>); `show`: only once
## that flag is set.
static func page(entities: Node2D, n: int, t: Vector2, show: StringName = &"") -> Node2D:
	var p: Node2D = B.prop(entities, "ambre", B.cell(t.x, t.y), false, load(PICKUP))
	p.name = "Page%d" % n
	p.taken_flag = StringName("found_journal_%d" % n)
	p.dialogue_id = StringName("page_%d" % n)
	p.show_flag = show
	return p


## The battles' backdrop (none set while it is not drawn: battle/ then picks one, MÉCANIQUES' contract).
const BACKDROP := "res://assets/art/battle/volcan.jpg"
## The flight is refused in every zone of the volcano (it would skip the lava and the barricade); what
## the refusal says (story/vol.gd, meta « vol_interdit_texte », MÉCANIQUES' contract).
const NO_FLIGHT := "Trop de fumée et d'air brûlant : ton ptérosaure refuse de décoller ici."


## The climate of a zone of the volcano: its sounds (`ambience`, the first of `music` drawn, else
## silence), its backdrop, ash in the air now and then (`mist`), never rain nor snow, no flight.
static func climate(root: Region, ambience: StringName, music: Array, mist: float) -> void:
	var tune := C.first(music)
	root.music = load(tune) if tune != "" else null
	root.ambience_id = ambience
	if ResourceLoader.exists(BACKDROP):
		root.battle_backdrop = load(BACKDROP)
	root.rain_chance = 0.0
	root.storm_chance = 0.0
	root.sandstorm_chance = 0.0
	root.mist_chance = mist
	root.snow_chance = 0.0
	root.blizzard_chance = 0.0
	root.set_meta(&"vol_interdit", true)
	root.set_meta(&"vol_interdit_texte", NO_FLIGHT)


## The chapter's species `wanted`, or `stand_in` while its sheet is not in SpeciesDB.
static func species(wanted: StringName, stand_in: StringName) -> StringName:
	return wanted if SpeciesDB.PATHS.has(wanted) else stand_in


## The rows of the habitats whose species the game knows already (the chapter's come with their
## sheets: the zones are built again once they are in SpeciesDB).
static func known(rows: Array) -> Array:
	return rows.filter(func(r: Array) -> bool: return SpeciesDB.PATHS.has(r[0]))


## A campfire to rest by (see Rest) on level ground near `t`, away from the lava; the plain scenery
## within two tiles cleared.
static func fire(root: Region, entities: Node2D, c: C, t: Vector2) -> void:
	var at := B.cell(t.x, t.y)
	for r in 6:
		var found := false
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var cell := Vector2i(t.floor()) + Vector2i(dx, dy)
				if maxi(absi(dx), absi(dy)) == r and not c.near_lava(cell.x, cell.y, 2) and B.is_flat(root, cell, 1):
					at = B.cell(cell.x + 0.5, cell.y + 0.5) if r > 0 else B.cell(t.x, t.y)
					found = true
					break
			if found:
				break
		if found:
			break
	for n in entities.get_children():
		if n.get_script() == Prop and (n as Node2D).position.distance_to(at) < 2.0 * B.TILE:
			n.free()
	B.prop(entities, "feu_camp", at)


static func _kept_clear(keep: Array, p: Vector2) -> bool:
	return keep.any(func(r: Rect2) -> bool: return r.has_point(p))


## Rocks, burnt trunks and ferns of `table` on the open ground (not on or by a path, not on a step,
## not by the lava, not in `keep` rects); low things only just south of the trails and of `keep`.
static func scatter(c: C, entities: Node2D, rng: RandomNumberGenerator, keep: Array, table: Array, density := 1.0) -> void:
	var paths := c.distance_to(func(x: int, y: int) -> bool: return c.ground_at(x, y) == "path")
	for y in c.h:
		for x in c.w:
			if c.ground_at(x, y) != "grass" or paths[y * c.w + x] <= 1 or c.near_lava(x, y, 1):
				continue
			var middle := Vector2(x + 0.5, y + 0.5)
			if _kept_clear(keep, middle) or not _steady(c, x, y):
				continue
			var rows: Array = LOW if _in_view(c, keep, x, y) else table
			for row: Array in rows:
				if rng.randf() < float(row[1]) * density:
					put(entities, [row[0], row[2]], Vector2(x + rng.randf_range(0.25, 0.75), y + rng.randf_range(0.35, 0.85)), rng.randf() < 0.5)
					break


## Tile (x, y) is level with all its neighbours (nothing on a step's edge).
static func _steady(c: C, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if absf(c.height_at(x + dx, y + dy) - c.height_at(x, y)) > 0.3:
				return false
	return true


## A trail or a kept-clear place just north of tile (x, y): it must stay in sight.
static func _in_view(c: C, keep: Array, x: int, y: int) -> bool:
	for k in range(1, VIEW_SHADOW + 1):
		for dx in range(-2, 3):
			if c.ground_at(x + dx, y - k) == "path" or _kept_clear(keep, Vector2(x + dx + 0.5, y - k + 0.5)):
				return true
	return false
