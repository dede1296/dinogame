class_name Apex
## Chapter 9, la Terre des Apex, and the epilogue (docs/chapitre-9-scenes.md, validated by Greg on
## 19/10: five Alphas help in the last battle, the guardians of the Cœurs). What the chapter's files
## share: the places by name (story/apex_places.gd, the CARTE agent's class ApexPlaces, read by path
## with fallbacks so a scene never breaks: FALLBACK_PLACES), the battles (battle/apex_battles.gd, the
## MÉCANIQUES agent's class ApexBattles, read by path: the scenes fall back on their own), the species
## or their stand-ins, the people a scene needs (the zone's node, else one brought on), the events
## (run: one branch of Story._run, BEFORE chapter 8's: it takes over Isaure at the door once the dawn
## can come), the scenes on entering the zones (on_zone).
## Scene 1 (the dawn, the duel, the door) is in story/apex_aube.gd; scene 2 (the crater) here; scene
## 3 (the block, the drop, the battle) in story/apex_coeur.gd, Hélène in story/apex_helene.gd; the
## epilogue (the Cabinet, the jetty, page 40) in story/epilogue.gd; the post-game lines in
## story/apex_autour.gd; the plain lines and pages 39-40 in data/dialogue_apex.gd.
## Flags (here): apex_arrivee, bloc_geant_vu (found_journal_39 / page_39: DialogueApex).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const C := preload("res://story/cieux.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
const HELENE := "Hélène"
const ROC := "Prof. Roc"
## The zones of the chapter and of the epilogue.
const PORTE := &"porte_cratere"
const TERRE := &"terre_apex"
const COEUR := &"coeur_apex"
const CABINET := &"cabinet"
const PORT := &"port_ambre"
## The places' script (the CARTE agent's, class ApexPlaces): read by path, never by its class.
const PLACES_SCRIPT := "res://story/apex_places.gd"
## The chapter's battles (the MÉCANIQUES agent's, class ApexBattles), read by path.
const BATTLES_SCRIPT := "res://battle/apex_battles.gd"
## Where things are (tiles), with their zone: [zone, tile or list of tiles]. The names are the CARTE
## agent's (story/apex_places.gd, class ApexPlaces, 19/10), read there first; the values here are a
## copy of that day's, so a scene still has a place if the file goes. A name in this table belongs
## to its zone (ISAURE, MAIA, CAILLOU are the bottom's; the door's are VolcanPlaces').
const FALLBACK_PLACES := {
	# porte_cratere, the dawn (ApexPlaces; the portal, the torches, Isaure, Maïa, Caillou: VolcanPlaces)
	"AUBE_CHLOE": [PORTE, Vector2(25.0, 12.8)], "DEVANT_PORTAIL": [PORTE, Vector2(25.0, 7.6)],
	"DEVANT_CAMP": [PORTE, Vector2(17.4, 10.4)],
	"DINOS_ISAURE_CACHES": [PORTE, [Vector2(44.2, 9.4), Vector2(45.2, 13.0), Vector2(44.6, 16.4), Vector2(43.4, 19.8)]],
	"DINOS_ISAURE_RANG": [PORTE, [Vector2(28.8, 11.6), Vector2(33.2, 12.2), Vector2(36.4, 14.4), Vector2(32.2, 16.0)]],
	# terre_apex (80 x 70): in by the north edge, the rim's ledge, the spiral down to the fond
	"TERRE_ENTREE": [TERRE, Vector2(40.5, 3.2)], "LE_BORD": [TERRE, Vector2(40.5, 10.4)],
	"ISAURE_ARRIVEE": [TERRE, Vector2(39.2, 9.2)], "MAIA_ARRIVEE": [TERRE, Vector2(41.9, 9.5)],
	"CAILLOU_ARRIVEE": [TERRE, Vector2(45.6, 8.0)], "CAIRN": [TERRE, Vector2(32.6, 11.4)], "PAGE_39": [TERRE, Vector2(33.4, 11.9)],
	"ROI_PERCHE": [TERRE, Vector2(49.5, 2.2)], "ROI_CIEL": [TERRE, Vector2(40.0, 30.0)],
	"BLOCS_GEANTS": [TERRE, [Vector2(17.0, 30.0), Vector2(27.0, 9.6), Vector2(68.0, 20.5), Vector2(56.5, 47.0)]],
	"SPIRALE": [TERRE, [Vector2(40.5, 8.0), Vector2(33.0, 9.2), Vector2(25.0, 12.5), Vector2(17.0, 16.0)]],
	"FOND": [TERRE, Vector2(40.0, 44.0)], "BLOC_LOIN": [TERRE, Vector2(38.5, 43.0)], "SORTIE_COEUR": [TERRE, Vector2(47.5, 44.3)],
	# coeur_apex (50 x 40): in by the north edge, the round hall, the bloc in its north half
	"COEUR_ENTREE": [COEUR, Vector2(42.5, 3.0)], "BLOC": [COEUR, Vector2(24.0, 16.0)],
	"HELENE_AMBRE": [COEUR, Vector2(22.2, 15.8)], "MAIN_HELENE": [COEUR, Vector2(22.2, 17.2)],
	"ISAURE": [COEUR, Vector2(22.2, 17.9)], "MAIA": [COEUR, Vector2(20.0, 19.0)], "CAILLOU": [COEUR, Vector2(16.6, 21.2)],
	"CHLOE_BLOC": [COEUR, Vector2(25.6, 19.6)], "ESSAIS": [COEUR, Vector2(25.4, 17.6)],
	"ROCHER_ABRI": [COEUR, Vector2(12.8, 18.4)], "ISAURE_ABRI": [COEUR, Vector2(11.2, 20.6)],
	"HELENE_ABRI": [COEUR, Vector2(12.0, 21.2)], "MAIA_ABRI": [COEUR, Vector2(13.6, 21.0)],
	"CAILLOU_REMPART": [COEUR, Vector2(16.8, 18.8)], "SOUVERAIN_PAROI": [COEUR, Vector2(24.0, 11.2)],
	"COMBAT_CHLOE": [COEUR, Vector2(24.0, 24.6)], "COMBAT_DINO": [COEUR, Vector2(24.0, 22.4)],
	"SOUVERAIN_COUCHE": [COEUR, Vector2(24.0, 14.6)], "ROI_POSE": [COEUR, Vector2(36.0, 13.6)],
	"ROI_CIEL_COEUR": [COEUR, Vector2(24.0, 6.0)],
	# the Cabinet, three days later (16 x 11)
	"CABINET_HELENE": [CABINET, Vector2(9.4, 3.65)], "CABINET_TABLE": [CABINET, Vector2(9.4, 5.1)],
	"TASSE_BLEUE": [CABINET, Vector2(9.75, 5.16)], "TASSE_ETAGERE": [CABINET, Vector2(3.3, 1.95)],
	"CAISSE_CARNETS": [CABINET, Vector2(4.75, 3.06)], "CABINET_ROC": [CABINET, Vector2(7.6, 4.9)],
	"CABINET_SEUIL": [CABINET, Vector2(8.0, 9.9)], "CABINET_ISAURE": [CABINET, Vector2(10.9, 5.6)],
	"CABINET_COUVEUSE": [CABINET, Vector2(13.4, 4.2)],
	# Port-Ambre, the step and the jetty (40 x 24)
	"MARCHE_MAIA": [PORT, Vector2(32.8, 9.0)], "RUELLE_CAILLOU": [PORT, Vector2(27.4, 10.5)],
	"JETEE_HELENE": [PORT, Vector2(19.6, 15.3)], "JETEE_ROC": [PORT, Vector2(20.7, 15.0)],
	"JETEE_CHLOE": [PORT, Vector2(19.5, 17.6)], "JETEE_MAIA": [PORT, Vector2(18.4, 16.4)],
	"JETEE_CAILLOU": [PORT, Vector2(22.0, 12.9)], "JETEE_ISAURE": [PORT, Vector2(20.55, 19.7)],
	"JETEE_SUIE": [PORT, Vector2(15.8, 12.6)], "JETEE_HAMON": [PORT, Vector2(22.4, 15.6)],
	"JETEE_JOSS": [PORT, Vector2(22.9, 14.3)], "JETEE_LEONCE": [PORT, Vector2(18.6, 18.6)],
	"JETEE_GUSTAVE": [PORT, Vector2(16.6, 16.6)], "JETEE_FIRMIN": [PORT, Vector2(14.2, 16.4)],
	"JETEE_ROSALIE": [PORT, Vector2(15.4, 15.6)], "JETEE_PERVENCHE": [PORT, Vector2(16.4, 14.6)],
	"JETEE_BRAC": [PORT, Vector2(18.6, 22.3)], "JETEE_MASTOC": [PORT, Vector2(19.7, 21.0)],
	"JETEE_CABOSSE": [PORT, Vector2(12.4, 16.3)], "JETEE_GROGNON": [PORT, Vector2(10.2, 16.1)],
	"JETEE_BOUT": [PORT, Vector2(19.4, 21.6)],
}
## The spawns' names (ApexPlaces), when the file does not say.
const FALLBACK_SPAWNS := {
	"SPAWN_APEX": &"DepuisApex",    # porte_cratere, back out of the portal
	"SPAWN_PORTE": &"DepuisPorte",  # terre_apex, through the portal
	"SPAWN_COEUR": &"DepuisCoeur",  # terre_apex, back up from the fond
	"SPAWN_TERRE": &"DepuisTerre",  # coeur_apex, down from the crater
	"LOSE_AUBE": &"DevantCamp",     # porte_cratere, the duel lost: by Hélène's camp
}
## The chapter's species and what stands in for them while their sheets are not in SpeciesDB.
const STAND_INS := {&"souverain": &"trex_magma"}
## The people's sheets, the first drawn wins (assets/art/characters/<sheet>.png); sitting is a pose
## (Stage.sit: Outfits « assis », when it is drawn for them). Hélène's are the IMAGES agent's (until
## then: an old lady of the island, tinted like the CARTE agent's stand-in, so a scene shows someone).
const HELENE_SHEETS := ["helene", "pervenche"]
const HELENE_TINT := Color(0.84, 0.9, 1.0)
const ISAURE_SHEETS := ["isaure_sans_masque", "isaure"]
const MAIA_SHEETS := ["maia_arche", "maia_manteau", "maia"]
## Amber light, the veins of the crater; violet (black amber).
const AMBER := Color(1.0, 0.72, 0.3)
const AMBER_BITS: Array[Color] = [Color(1.0, 0.8, 0.35), Color(1.0, 0.92, 0.6), Color(0.95, 0.6, 0.2)]
const VIOLET := Color(0.62, 0.3, 1.0)
const XP_ARRIVEE := 40
const XP_BLOC := 5
## The Roi perched high on the rim (px of picture lift), the size it is drawn at.
const ROI_PERCH_PX := 120.0
const ROI_SIZE := 1.3
## How far Isaure and Maïa walk down the spiral before the ash hides them (tiles), how fast.
const AHEAD_TILES := 8.0
const AHEAD_SPEED := 52.0


# ------------------------------------------------------------------ places and species

## Where `name` is (tiles): ApexPlaces when the CARTE agent has it, else the copy here, else the
## Plaine Volcanique's (VolcanPlaces: the door's places).
static func place(name: String) -> Vector2:
	var known = _places().get(name)
	if known is Vector2:
		return known
	if FALLBACK_PLACES.has(name) and FALLBACK_PLACES[name][1] is Vector2:
		return FALLBACK_PLACES[name][1]
	return V.place(name)


## A list of places (tiles: BLOCS_GEANTS, DINOS_ISAURE_RANG…), [] when unknown.
static func places(name: String) -> Array:
	var known = _places().get(name)
	if known is Array:
		return known
	if FALLBACK_PLACES.has(name) and FALLBACK_PLACES[name][1] is Array:
		return FALLBACK_PLACES[name][1]
	return []


## The `i`-th of a list of places (px) when Chloé is in its zone, else `fallback_px`.
static func spot_in(name: String, i: int, fallback_px: Vector2) -> Vector2:
	var list := places(name)
	if Game.region_id != zone_of(name) or i < 0 or i >= list.size():
		return fallback_px
	var tile: Vector2 = list[i]
	return S.at(tile.x, tile.y)


## The same, in world pixels.
static func px(name: String) -> Vector2:
	var tile := place(name)
	return S.at(tile.x, tile.y)


## The zone `name` is in (a name not in the table: the door's, VolcanPlaces').
static func zone_of(name: String) -> StringName:
	return FALLBACK_PLACES[name][0] if FALLBACK_PLACES.has(name) else PORTE


## True when the scenes may act at `name`: Chloé is in its zone, and the place is known (ApexPlaces,
## the copy here, or VolcanPlaces for the door). Elsewhere (a test on another zone) they act round her.
static func has_place(name: String) -> bool:
	if Game.region_id != zone_of(name):
		return false
	return _places().get(name) is Vector2 or FALLBACK_PLACES.has(name) or V.has_place(name)


## Where a scene acts (px): the place `name` when known there, else Chloé + `offset` (px).
static func spot(name: String, offset := Vector2.ZERO) -> Vector2:
	if has_place(name):
		return px(name)
	return chloe_px() + offset


## The place `name` (px) when known there, else `fallback_px`.
static func spot_or(name: String, fallback_px: Vector2) -> Vector2:
	return px(name) if has_place(name) else fallback_px


## A spawn's name (ApexPlaces.SPAWN_*), else the fallback.
static func spawn(name: String) -> StringName:
	var places := _places()
	if places.get(name) is StringName:
		return places[name]
	return FALLBACK_SPAWNS.get(name, &"Depart")


static func _places() -> Dictionary:
	if ResourceLoader.exists(PLACES_SCRIPT):
		return (load(PLACES_SCRIPT) as Script).get_script_constant_map()
	return {}


## Chloé's position (px), Vector2.ZERO when there is no world (the tests without a window).
static func chloe_px() -> Vector2:
	var chloe := Stage.chloe()
	return chloe.global_position if chloe else Vector2.ZERO


## Where `who` stands (px), else Chloé + `offset`.
static func px_of(who, offset := Vector2.ZERO) -> Vector2:
	if who is Node2D and is_instance_valid(who):
		return (who as Node2D).global_position
	return chloe_px() + offset


## `id` when SpeciesDB has it, else its stand-in (a scene never breaks for a missing sheet).
static func species_or(id: StringName) -> StringName:
	if SpeciesDB.PATHS.has(id):
		return id
	return STAND_INS.get(id, V.species_or(id))


## A dino only a scene needs, its species or its stand-in; invisible at first (V.stand_in).
static func stand_in(id: StringName, at_px: Vector2, node_name: String, level := 0, size := 1.0, corrupted := false) -> DinoNpc:
	var w = S.world()
	if w == null or w.get("region") == null:
		return null
	var species := species_or(id)
	if not SpeciesDB.PATHS.has(species):
		return null
	var d := DinoNpc.new()
	d.name = node_name
	d.species_id = species
	d.level = level
	d.size_scale = size if SpeciesDB.PATHS.has(id) else 1.0
	d.corrupted = corrupted
	d.position = at_px
	d.modulate.a = 0.0
	w.region.entities.add_child(d)
	d.collision_layer = 0
	return d


## The zone's dino of `names`, else a stand-in of `id` at `at_px` (shown at once).
static func dino(names: Array, id: StringName, at_px: Vector2, size := 1.0, corrupted := false) -> Node2D:
	var d = V.actor_of(names)
	if d is Node2D:
		return d
	d = stand_in(id, at_px, names[0], 0, size, corrupted)
	if d:
		(d as Node2D).modulate.a = 1.0
	return d


## The zone's person of `names`, else one brought on (S.stranger, not to be talked to), drawn with
## the first of `sheets` there is, at `at_px`.
static func person(names: Array, sheets: Array, at_px: Vector2, facing := "down", display := "") -> Node2D:
	var p = V.actor_of(names)
	if p is Node2D:
		return p
	return S.stranger(names[0], V.sheet(sheets), at_px, facing, display)


## Hélène brought on by a scene: tinted while only her stand-in's picture is drawn.
static func tint_helene(n) -> void:
	if n is Npc and brought(n) and V.sheet(HELENE_SHEETS) != HELENE_SHEETS[0]:
		var sprite := Stage.sprite_of(n)
		if sprite:
			sprite.self_modulate = HELENE_TINT


## Someone who stays in a zone once a scene is over (post-game: Hélène in her armchair, Isaure at
## her boat…), to be talked to (`event`, Story.run): the zone's Npc of `names` when the map has one
## (given the event if it has none), else one made here (named `names[0]`). Null in 3D (no models
## yet) or when there is no world.
static func resident(names: Array, sheets: Array, at_px: Vector2, display: String, event: StringName, facing := "down") -> Npc:
	var there = V.actor_of(names)
	if there is Npc:
		if (there as Npc).event == &"":
			(there as Npc).event = event
			(there as Npc).add_to_group(&"interactable")
		return there
	var n := S.stranger(names[0], V.sheet(sheets), at_px, facing, display)
	if n == null:
		return null
	n.event = event
	n.add_to_group(&"interactable")
	return n


## The scene's actors gone (the ones brought on: the zone's own nodes stay, their flags decide).
static func clean_up(cast: Dictionary, keep: Array = []) -> void:
	for k in cast:
		if k in keep:
			continue
		var n = cast[k]
		if typeof(n) != TYPE_OBJECT or not is_instance_valid(n):
			continue   # (a place, or someone already gone)
		if n is Node and brought(n):
			(n as Node).queue_free()


## True for a node a scene brought on (S.stranger, a stand-in): not one of the zone's map, whose
## nodes belong to the zone's scene (their owner).
static func brought(n: Node) -> bool:
	return n.owner == null


# ------------------------------------------------------------------ the battles

## The MÉCANIQUES agent's battles of the chapter (ApexBattles), null while it is not there.
static func battles():
	return load(BATTLES_SCRIPT) if ResourceLoader.exists(BATTLES_SCRIPT) else null


## `method` of ApexBattles called with `args` when it has it, else `fallback`.
static func from_battles(method: StringName, args: Array, fallback: Variant) -> Variant:
	var b = battles()
	if b and (b as Script).get_script_method_list().any(func(m: Dictionary) -> bool: return m["name"] == String(method)):
		return b.callv(method, args)
	return fallback


## A constant of ApexBattles, else `fallback`.
static func battles_const(name: String, fallback: Variant) -> Variant:
	var b = battles()
	return (b as Script).get_script_constant_map().get(name, fallback) if b else fallback


# ------------------------------------------------------------------ the starter, Moustique, the mask

## Chloé's own hatchling (Vif, Bastion or Écho), null when there is none.
static func starter() -> Dino:
	return Game.starter_dino()


## Its species (&"velociraptor", &"ankylosaurus", &"parasaurolophus"), &"" when unknown.
static func starter_species() -> StringName:
	var d := starter()
	if d:
		return d.species().id
	var id = Game.flag(&"starter")
	return StringName(id) if id is String else &""


## Its name (« Vif »…), else « ton dino ».
static func starter_name() -> String:
	var d := starter()
	return d.nickname if d else "ton dino"


## True when Chloé's own hatchling is in the party (the dawn waits for it: « Va le chercher »).
static func starter_in_party() -> bool:
	var d := starter()
	return d != null and Game.party.has(d)


## True when Chloé still carries Maïa's cardboard mask (given back on the Arche, ch. 7).
static func has_cardboard_mask() -> bool:
	return Game.item_count("masque_carton") > 0 or (Game.flag(&"masque_carton_confie") and not Game.flag(&"masque_carton_rendu"))


# ------------------------------------------------------------------ the chapter's events

## The scene on entering one of the chapter's zones (Story._on_zone_entered; porte_cratere after
## chapter 8's own, Volcan.on_zone).
static func on_zone(zone: StringName) -> void:
	match zone:
		&"porte_cratere":
			await ApexAube.on_porte()
		&"terre_apex":
			await arrival()
		&"coeur_apex":
			await ApexCoeur.arrival()


## The chapter's scenes started by talking to someone or something (one branch of Story._run,
## asked BEFORE Volcan.run). False when `event` is not the chapter's, or not yet (Isaure at the door
## is chapter 8's until the dawn can come; Brac and Léonce at the port until the epilogue).
static func run(event: StringName, who: Node) -> bool:
	match event:
		# The dawn, the duel, the door (story/apex_aube.gd)
		&"isaure_porte":
			if not ApexAube.takes_over():
				return false
			await ApexAube.isaure(who)
		&"hauban", &"bouline", &"etrave", &"carene":
			await ApexAube.sea_dino(who)
		# The crater (this file)
		&"bloc_geant_1", &"bloc_geant_2", &"bloc_geant_3", &"bloc_geant_4":
			await bloc(int(String(event).right(1)), who)
		&"bloc_geant":
			await bloc(_index_of(who), who)
		&"roi_apex":
			await roi(who)
		# The bottom (story/apex_coeur.gd, apex_helene.gd)
		&"bloc_souverain":
			await ApexCoeur.bloc(who)
		&"souverain":
			await ApexCoeur.souverain(who)
		&"helene_ambre", &"isaure_helene":
			await ApexCoeur.helene_ambre(who)
		# The post-game (story/apex_autour.gd)
		&"helene_cabinet":
			await ApexAutour.helene(who)
		&"isaure_barque":
			await ApexAutour.isaure(who)
		&"maia_gardienne":
			await ApexAutour.maia(who)
		&"suie_port":
			await ApexAutour.suie(who)
		&"joss_jetee":
			await ApexAutour.joss(who)
		# The epilogue's people (the CARTE agent's nodes): the jetty, the step, the Cabinet
		&"helene_jetee", &"roc_jetee", &"maia_jetee", &"hamon_jetee", &"gustave_jetee", &"firmin_jetee", &"rosalie_jetee", &"pervenche_jetee", &"caillou_jetee", &"mastoc_jetee", &"cabosse_jetee", &"grognon_jetee", &"isaure_jetee", &"suie_jetee":
			await Epilogue.jetty_event(event, who)
		&"maia_marche", &"caillou_ruelle":
			await Epilogue.step_event(event, who)
		&"tasse_bleue", &"caisse_carnets", &"isaure_cabinet":
			await Epilogue.cabinet_event(event, who)
		&"brac_jetee":
			if not Game.flag(&"epilogue_fini"):
				return false
			await ApexAutour.brac(who)
		&"leonce_port":
			if not Game.flag(&"epilogue_fini"):
				return false
			await ApexAutour.leonce(who)
		_:
			return false
	return true


## The number at the end of a node's name (« BlocGeant3 » → 3), 1 when none.
static func _index_of(who) -> int:
	var name := String((who as Node).name) if who is Node else ""
	var digits := ""
	for c in name:
		if c >= "0" and c <= "9":
			digits += c
	return clampi(int(digits), 1, 4) if digits != "" else 1


# ------------------------------------------------------------------ the Terre des Apex (scene 2)

## 2 a, the first time in the crater (7 lines): no lava, black rock, veins of amber lit without a
## moon, the spiral; the blocks with giants asleep; the big block at the bottom with a small figure
## against it; « C'est elle ? »; Moustique stops trembling. Then Isaure and Maïa go down ahead, and
## the way down is watched (no line). Chloé is free: page 39 at the cairn, the blocks, the path.
static func arrival() -> void:
	if Game.flag(&"apex_arrivee") or not Game.flag(&"apex_ouvert"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.4)
	var cast := {}
	_cast_ahead(cast)
	await S.say(arrival_lines(cast))
	await _down_ahead(cast)
	clean_up(cast)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)


## Isaure and Maïa a few steps ahead on the rim's ledge, stopped, looking down (Caillou behind
## them); the Roi perched high on the rim. In terre_apex the crater lies south of the way in (towards
## the camera): the scenes look that way.
static func _cast_ahead(cast: Dictionary) -> void:
	var base := chloe_px()
	cast["isaure"] = person(["IsaureArrivee", "IsaureTerre"], ISAURE_SHEETS, spot_or("ISAURE_ARRIVEE", S.ground_near(base + Vector2(-40.0, 2.4 * S.CELL), 3)), "down", ISAURE)
	cast["maia"] = person(["MaiaArrivee", "MaiaTerre"], MAIA_SHEETS, spot_or("MAIA_ARRIVEE", S.ground_near(base + Vector2(50.0, 2.6 * S.CELL), 3)), "down", MAIA)
	cast["caillou"] = dino(["CaillouArrivee", "CaillouTerre"], &"triceratops", spot_or("CAILLOU_ARRIVEE", S.ground_near(base + Vector2(4.0 * S.CELL, 1.0 * S.CELL), 3)))
	var king = V.actor_of(["RoiApex"])
	if king == null:
		king = stand_in(&"quetzalcoatlus", spot_or("ROI_PERCHE", base + Vector2(5.0 * S.CELL, -1.0 * S.CELL)), "RoiApex", 0, ROI_SIZE)
		if king:
			_perch(king)
	cast["roi"] = king


## The bottom of the crater (px): the big block seen from the rim.
static func bottom_px() -> Vector2:
	return spot("BLOC_LOIN", Vector2(0.0, 9.0 * S.CELL))


## The lines of 2 a (also the tests': 7 lines, the flag at the end).
static func arrival_lines(cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var bottom := bottom_px()
	var rim := func() -> void:
		Stage.look_at(bottom.lerp(chloe_px(), 0.55), 1.8)
		for i in 4:
			CS.pulse(chloe_px() + Vector2(randf_range(-5.0, 5.0), randf_range(2.0, 7.0)) * S.CELL, AMBER, 2, 1.6, 2.0, 4.0)
			await S.wait(0.3)
	var giants := func() -> void:
		for i in [1, 0]:
			var b := spot_in("BLOCS_GEANTS", i, chloe_px() + Vector2((-1.0 if i == 1 else 1.0) * 6.0 * S.CELL, 5.0 * S.CELL))
			Stage.look_at(b, 1.0)
			CS.pulse(b, AMBER, 1, 1.2, 2.4, 5.0)
			await S.wait(1.2)
	var thinks := func() -> void:
		Stage.look_back(1.0)
		if chloe:
			Stage.bow(chloe, 0.8)
	var deep := func() -> void:
		await CS.pan(bottom, 2.2)
		CS.pulse(bottom, AMBER, 3, 1.4, 3.0, 7.0)
	var asks := func() -> void:
		Stage.look_back(1.0)
		var maia = cast.get("maia")
		if maia is Npc:
			(maia as Npc).face(bottom)
	var answers := func() -> void:
		var isaure = cast.get("isaure")
		if isaure is Npc:
			(isaure as Npc).face(bottom)
			Stage.emote(isaure, "…")
	var peeks := func() -> void:
		if chloe:
			V.shoulder_peek(chloe, 2.4)
	return [
		CS.cue({"text": "Le cratère. Pas de lave : de la roche noire, et dans la roche, des veines d'ambre qui luisent toutes seules, sans lune. Un chemin descend en spirale, comme l'île."}, rim),
		CS.cue({"text": "Ici et là, des blocs d'ambre gros comme des maisons. Dedans, des formes. Des très grandes formes, qui dorment."}, giants),
		CS.cue({"who": CHLOE, "text": "(Les géants. Elle les a trouvés, et elle les a laissés dormir. « Chacun chez soi. »)"}, thinks),
		CS.cue({"text": "Tout en bas, au centre, un bloc plus grand que le Cabinet. Quelque chose d'immense dedans, qu'on ne comprend pas d'ici. Et contre, une petite forme assise, une main posée."}, deep),
		CS.cue({"who": MAIA, "text": "C'est elle ?"}, asks),
		CS.cue({"who": ISAURE, "text": "C'est elle. Elle n'a jamais su rester loin de ce qui est trop grand."}, answers),
		CS.cue({"text": "Sur l'épaule de Chloé, Moustique sort la tête du col. Il a cessé de trembler : il n'y a pas de feu, ici."}, peeks),
		{"flag": &"apex_arrivee"},
	]


## Watched, no line: Isaure and Maïa go down the spiral ahead, side by side (Caillou behind); the
## camera follows the way down to the bottom, where the veins glow brighter, and comes back to Chloé.
static func _down_ahead(cast: Dictionary) -> void:
	var bottom := bottom_px()
	var path: Array = []
	if Game.region_id == TERRE:
		for t: Vector2 in places("SPIRALE").slice(1, 5):
			path.append(S.at(t.x, t.y))
	for k in ["isaure", "maia", "caillou"]:
		var n = cast.get(k)
		if not n is Node2D or not is_instance_valid(n):
			continue
		var at: Vector2 = (n as Node2D).global_position
		Stage.fade_out(n, AHEAD_TILES * S.CELL / AHEAD_SPEED, false)
		if n is Npc and not path.is_empty():
			(n as Npc).walk_path(path, "", AHEAD_SPEED)
		elif n is Npc:
			(n as Npc).walk_to(at + (bottom - at).normalized() * AHEAD_TILES * S.CELL, "", AHEAD_SPEED)
		elif n is DinoNpc:
			(n as DinoNpc).walk_to(at + (bottom - at).normalized() * AHEAD_TILES * S.CELL, AHEAD_SPEED)
	await S.wait(1.6)
	await CS.pan(bottom, 3.0)
	for i in 3:
		CS.pulse(bottom + Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0)) * S.CELL, AMBER, 2, 1.0, 2.0 + i, 5.0)
		await S.wait(0.5)
	await S.wait(0.8)
	Stage.look_back(1.4)
	await S.wait(1.0)


## A stand-in up on the rim: its picture lifted (and kept there by the moves that put it back).
static func _perch(bird: Node) -> void:
	var sprite := Stage.sprite_of(bird)
	if sprite == null:
		return
	sprite.position.y = -ROI_PERCH_PX
	sprite.set_meta(&"stage_rest", sprite.position)
	(bird as Node2D).modulate.a = 1.0


## 2 c, a block of amber with a giant asleep inside (StoryProp « BlocGeant1..4 »).
static func bloc(n: int, who: Node) -> void:
	var at := px_of(who, Vector2(0.0, -2.0 * S.CELL))
	var first: bool = not Game.flag(&"bloc_geant_vu")
	await S.say([CS.cue(DialogueApex.bloc_geant(n), func() -> void:
		Stage.look_at(at.lerp(chloe_px(), 0.3), 0.8)
		CS.pulse(at, AMBER, 2, 1.0, 2.4, 5.0)), {"flag": &"bloc_geant_vu"}])
	Stage.look_back()
	if first:
		Game.award_team_xp(XP_BLOC)
		Save.save_game()


## The Roi on the rim (DinoNpc « RoiApex »): he looks down, a long time (no line written: a cry).
static func roi(who: Node) -> void:
	Stage.turn_to(who, bottom_px())
	Stage.cry(who, &"neutre")
	Stage.emote(who, "…")
	await S.wait(1.2)


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): the crater's arrival on any zone (Isaure and Maïa
## brought on before Chloé), then page 39 and the four blocks.
static func static_terre() -> void:
	S.playing += 1
	Game.set_flag(&"apex_ouvert")
	await arrival()
	await S.say(DialogueApex.lines(&"page_39"))
	for i in [1, 2, 3, 4]:
		await bloc(i, null)
	S.playing -= 1


## The lines of each of `ids` said now (pages, blocks, examined things).
static func say_lines(ids: Array) -> void:
	S.playing += 1
	for id in ids:
		await S.say(DialogueApex.lines(StringName(id)))
	S.playing -= 1
