extends RefCounted
## Les outils partagés des tests de parcours (tests/parcours/test_*.gd), sans fenêtre : les zones ouvertes
## sans être affichées (Region.open_for_preview), la marche de Chloé dans une zone, et la marche sur toute
## l'île par les sorties ouvertes.
##
## La marche dans une zone est le calcul de tools/zones/volcan_verif.gd (reach) — celui de
## tools/zone_builder.gd _reachable, plus la lave — dans l'état de la partie (Game) :
## - le relief (pas de falaise entre deux cases), le sol praticable (ZoneBuilder.WALKABLE) ;
## - l'eau profonde, à la nage, quand l'équipe a un nageur et le gilet (Swim.can_swim : ZoneBuilder
##   _reachable « swimming ») ;
## - la lave (méta « lave ») : seulement sur le dos du dino de tête qui a le cuir pour (Lava.walker) ;
## - la lave qui se retire (méta « lave_retrait ») : personne, jusqu'à son drapeau (« lave_retiree ») ;
## - les décors de l'HISTOIRE présents à ce moment (StoryProp, FlaggedProp, Obstacle, panneaux : leurs
##   show_flag / hide_flag / cleared_flag / after_flag) : leur pied solide est un mur (le calcul de
##   tools/zones/apex_verif.gd solid_box, élargi du rayon de Chloé) ; un Obstacle que l'équipe sait
##   franchir (Game.ability_user) ne compte pas : Chloé le dégage en passant. Les décors ordinaires
##   (arbres, rochers) ne comptent pas : les plans des zones vérifient déjà qu'aucun n'est sur un chemin.
## Les zones des chapitres 1 à 5 (déjà jouées de bout en bout) ne sont pas recalculées : sur l'île,
## chacune de leurs arrivées mène à chacune de leurs sorties ouvertes.

const VV := preload("res://tools/zones/volcan_verif.gd")
const AV := preload("res://tools/zones/apex_verif.gd")
const ZB := preload("res://tools/zone_builder.gd")
const TILE := 48.0
## Chloé parle à quelqu'un à cette distance (actors/player.gd INTERACT_REACH, px) ; plus le bonus de
## chaque sorte de nœud (son _ready : StoryProp 40, Obstacle 30, un dino selon sa largeur…).
const INTERACT_REACH := 62.0
const REACH_BONUS := {"StoryProp": 40.0, "Obstacle": 30.0, "DinoNpc": 20.0, "Pickup": 10.0, "Sign": 10.0, "Npc": 0.0}
## Un repère d'objectif est atteint quand Chloé arrive à cette distance (px) de son point.
const MARKER_REACH := 2.0 * TILE
## Les zones dont la marche est calculée (chapitres 6 à 9, et le port, le Cabinet, le Havre de l'épilogue).
const WALKED := [&"cote", &"monts", &"grottes_glace", &"sanctuaire_givre", &"cieux", &"nids_geants", &"arche_du_vent",
	&"champs_cendres", &"forges_ombre", &"coulees_lave", &"sanctuaire_magma", &"porte_cratere", &"terre_apex", &"coeur_apex",
	&"port_ambre", &"cabinet", &"havre_dore"]
## Les huit portes de la chaîne des chapitres 6 à 9 : [zone, sortie, drapeau attendu].
const GATES := {
	"monts": [&"cote", "VersMonts", &"monts_ouverts"],
	"givre": [&"monts", "VersSanctuaireGivre", &"sanctuaire_givre_ouvert"],
	"cieux": [&"monts", "VersCieux", &"cieux_ouverts"],
	"arche": [&"nids_geants", "VersArcheDuVent", &"vol_obtenu"],
	"volcan": [&"arche_du_vent", "VersChampsCendres", &"volcan_ouvert"],
	"coulees": [&"forges_ombre", "VersCouleesLave", &"suie_partie"],
	"porte": [&"coulees_lave", "VersPorteCratere", &"lave_retiree"],
	"apex": [&"porte_cratere", "VersTerreApex", &"apex_ouvert"],
}

static var _zones := {}    # id -> Region
static var _reach := {}    # clé -> Dictionary (cases atteintes)


# ------------------------------------------------------------------ les zones

static func paths() -> Dictionary:
	return (load("res://world/world.gd") as Script).get_script_constant_map()["ZONES"]


static func zone(id: StringName) -> Region:
	if not _zones.has(id):
		var path: String = paths().get(id, "")
		_zones[id] = Region.open_for_preview(path) if path != "" and ResourceLoader.exists(path) else null
	return _zones[id]


static func free_all() -> void:
	for r: Node in _zones.values():
		if r:
			r.free()
	_zones.clear()
	_reach.clear()


static func tile_of(px: Vector2) -> Vector2i:
	return Vector2i((px / TILE).floor())


static func spawn_px(r: Region, spawn_name: StringName) -> Vector2:
	var s := r.get_node_or_null("Spawns/" + String(spawn_name)) as Node2D
	return s.position if s else Vector2.INF


static func exit_named(r: Region, exit_name: String) -> ZoneExit:
	return r.get_node_or_null("Exits/" + exit_name) as ZoneExit


## Every node of the zone carrying `property` (event, dialogue_id…), at any depth.
static func nodes_with(r: Region, property: String) -> Array[Node]:
	var out: Array[Node] = []
	for n in r.find_children("*", "", true, false):
		if property in n and String(n.get(property)) != "":
			out.append(n)
	return out


static func kind_of(n: Node) -> String:
	for k: String in ["Obstacle", "StoryProp", "Pickup", "Sign", "DinoNpc", "Npc", "StoryTrigger"]:
		if n.is_class(k) or (n.get_script() and _extends(n.get_script(), k)):
			return k
	return n.get_class()


static func _extends(s: Script, cls: String) -> bool:
	while s:
		if s.get_global_name() == cls:
			return true
		s = s.get_base_script()
	return false


# ------------------------------------------------------------------ l'état de la partie

## There in the current state of the story (Game's flags): show_flag set, hide_flag not, an obstacle
## not cleared, a page not taken.
static func present(n: Node) -> bool:
	if "show_flag" in n and String(n.get("show_flag")) != "" and not Game.flag(StringName(n.get("show_flag"))):
		return false
	if "hide_flag" in n and String(n.get("hide_flag")) != "" and Game.flag(StringName(n.get("hide_flag"))):
		return false
	if n is Obstacle and (n as Obstacle).cleared_flag != &"" and Game.flag((n as Obstacle).cleared_flag):
		return false
	if n is Pickup and (n as Pickup).taken_flag != &"" and Game.flag((n as Pickup).taken_flag):
		return false
	return true


## The tiles under the solid feet of the story's scenery there now (see the header), grown by Chloé's
## radius; `except`: a node left out (the one Chloé goes to talk to).
static func story_walls(r: Region, except: Node = null) -> Dictionary:
	var out := {}
	for n in r.entities.get_children():
		if not n is Prop or n == except or n is Pickup or n.get_script() == Prop or not present(n):
			continue
		if n is Obstacle and Game.ability_user((n as Obstacle).ability) != null:
			continue   # (the party clears it on the way)
		var kind: String = (n as Prop).kind
		if "after_flag" in n and String(n.get("after_flag")) != "" and String(n.get("after_kind")) != "" and Game.flag(StringName(n.get("after_flag"))):
			kind = String(n.get("after_kind"))
		var box := AV.solid_box(kind, (n as Node2D).position)
		if not box.has_area():
			continue
		box = box.grow(AV.PLAYER_RADIUS)
		for y in range(floori(box.position.y / TILE), ceili(box.end.y / TILE)):
			for x in range(floori(box.position.x / TILE), ceili(box.end.x / TILE)):
				if box.has_point((Vector2(x, y) + Vector2(0.5, 0.5)) * TILE):
					out[Vector2i(x, y)] = true
	return out


## On the back of the lead dino over the lava (Lava.walker: the « Cuir de feu »).
static func mounted() -> bool:
	return Lava.walker() != null


## The flags the zone's walking depends on (its story scenery's, its lava's, the swimmer): the cache key.
static func _state_key(r: Region) -> String:
	var bits: Array[String] = [str(mounted()), str(Swim.can_swim())]
	if r.has_meta(Lava.META_RETREAT):
		bits.append(str(Game.flag(StringName(r.get_meta(Lava.META_RETREAT_FLAG, Lava.RETREAT_FLAG)))))
	for n in r.entities.get_children():
		if n is Prop and not n is Pickup and n.get_script() != Prop:
			bits.append("1" if present(n) else "0")
			if n is Obstacle:
				bits.append("1" if Game.ability_user((n as Obstacle).ability) != null else "0")
			if "after_flag" in n and String(n.get("after_flag")) != "":
				bits.append("1" if Game.flag(StringName(n.get("after_flag"))) else "0")
	return "".join(bits)


## The tiles Chloé walks to in zone `id` from tile `from`, in the state of the game (see the header).
## `walls`: false = the relief and the lava only (the zone plans' own calculation).
static func reach(id: StringName, from: Vector2i, walls := true) -> Dictionary:
	var r := zone(id)
	if r == null:
		return {}
	var key := "%s|%s|%s|%s" % [id, from, walls, _state_key(r) if walls else "%s%s%s" % [mounted(), Swim.can_swim(), _retreat_holds(r)]]
	if _reach.has(key):
		return _reach[key]
	var lava := VV.tiles_of(r, Lava.META)
	var blocked := {} if not _retreat_holds(r) else VV.tiles_of(r, Lava.META_RETREAT)
	if walls:
		blocked.merge(story_walls(r))
		blocked.erase(from)
	var out := walk(r, from, lava, blocked, mounted(), Swim.can_swim())
	_reach[key] = out
	return out


## tools/zones/volcan_verif.gd reach, and the water when `swimming` (tools/zone_builder.gd _reachable):
## the tiles reached from `from`, never on `blocked`, on `lava` only when `on_back`.
static func walk(r: Region, from: Vector2i, lava: Dictionary, blocked: Dictionary, on_back: bool, swimming: bool) -> Dictionary:
	if not swimming:
		return VV.reach(r, from, lava, blocked, on_back)
	var terrain: TileMapLayer = r.get_node("Terrain")
	var seen := {from: true}
	var low := r.floor_height()
	var queue: Array[Vector2i] = [from]
	var i := 0
	while i < queue.size():
		var c := queue[i]
		i += 1
		var h := r.tile_height(c)
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := c + d
			if seen.has(n) or blocked.has(n) or (lava.has(n) and not on_back):
				continue
			var data := terrain.get_cell_tile_data(n)
			var kind := String(data.get_custom_data("terrain")) if data else ""
			if not (kind in ZB.WALKABLE or kind == "water"):
				continue
			if r.cliff_between(r.tile_height(n), h, low):
				continue
			seen[n] = true
			queue.append(n)
	return seen


static func _retreat_holds(r: Region) -> bool:
	return r.has_meta(Lava.META_RETREAT) and not Game.flag(StringName(r.get_meta(Lava.META_RETREAT_FLAG, Lava.RETREAT_FLAG)))


## Some tile of `reached` has its middle within `dist` px of `px`.
static func near(reached: Dictionary, px: Vector2, dist: float) -> bool:
	var c := tile_of(px)
	var span := ceili(dist / TILE) + 1
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var t := c + Vector2i(dx, dy)
			if reached.has(t) and ((Vector2(t) + Vector2(0.5, 0.5)) * TILE).distance_to(px) <= dist:
				return true
	return false


## Chloé can talk to (or walk into) node `n` from the tiles of `reached`.
static func can_use(reached: Dictionary, n: Node) -> bool:
	var at := (n as Node2D).position
	if n is StoryTrigger:
		return near(reached, at, (n as StoryTrigger).radius * TILE)
	return near(reached, at, INTERACT_REACH + float(REACH_BONUS.get(kind_of(n), 0.0)))


## Chloé walks into the exit's area from the tiles of `reached`.
static func at_exit(r: Region, reached: Dictionary, e: ZoneExit) -> bool:
	var rect := r.exit_rect(e).grow(6.0)
	for y in range(floori(rect.position.y / TILE) - 1, ceili(rect.end.y / TILE) + 1):
		for x in range(floori(rect.position.x / TILE) - 1, ceili(rect.end.x / TILE) + 1):
			if reached.has(Vector2i(x, y)) and Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE)).intersects(rect):
				return true
	return false


# ------------------------------------------------------------------ l'île

## Where Chloé gets to on foot, from tile `from` of zone `id`, through the exits open now (and the lava
## as her lead dino allows): zone -> the tiles reached there ({} for a zone not walked: all of it).
static func walk_island(id: StringName, from: Vector2i) -> Dictionary:
	var out := {}
	var seen := {}
	var queue: Array = [[id, from]]
	while not queue.is_empty():
		var here: Array = queue.pop_front()
		var key := "%s|%s" % here
		if seen.has(key):
			continue
		seen[key] = true
		var z: StringName = here[0]
		var r := zone(z)
		if r == null:
			continue
		var walked: bool = z in WALKED
		var got := reach(z, here[1]) if walked else {}
		if not out.has(z):
			out[z] = {}
		(out[z] as Dictionary).merge(got)
		for e in r.exits():
			if not e.is_open() or (walked and not at_exit(r, got, e)):
				continue
			var there := zone(e.target_zone)
			if there == null:
				continue
			var p := spawn_px(there, e.target_spawn)
			if p != Vector2.INF:
				queue.append([e.target_zone, tile_of(p)])
	return out


## The objective `o` (Objectives' dictionary) is reached from `walked` (walk_island's): its zone is,
## and its marker (if any) too. "" when it is, else why not.
static func objective_reached(walked: Dictionary, o: Dictionary) -> String:
	var z: StringName = o["zone"]
	if not walked.has(z):
		return "zone %s pas atteinte à pied" % z
	var tile: Vector2 = o["tile"]
	if tile == Vector2.INF or not z in WALKED:
		return ""
	if not near(walked[z], tile * TILE, MARKER_REACH):
		return "repère %s de %s pas atteint à pied" % [tile, z]
	return ""
