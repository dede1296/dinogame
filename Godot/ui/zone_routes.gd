class_name ZoneRoutes
extends RefCounted
## Les chemins entre zones, pour l'aide de quête (QuestTracker) et la mini-carte (Minimap) : quand
## l'objectif suivi est dans une autre zone, par où partir. LINKS : où mènent les sorties (ZoneExit) et
## les plongées (DiveSpot) de chaque zone, comme ses scènes les posent — tests/ui/test_zone_routes.gd
## vérifie que la table le dit toujours (une table plutôt que les scènes lues en jeu : un export ne
## garde pas les .tscn en texte, et charger toutes les zones serait lourd). Le chemin : le plus court,
## en nombre de zones (next_hop) ; dans la zone, la sortie la plus proche vers la suivante (heading).

const TILE := 48.0
const LINKS := {
	&"port_ambre": [&"cabinet", &"havre_dore", &"plaines"],
	&"cabinet": [&"port_ambre"],
	&"plaines": [&"antre_crane", &"foret", &"grotte_echos", &"port_ambre"],
	&"grotte_echos": [&"plaines"],
	&"antre_crane": [&"plaines"],
	&"havre_dore": [&"port_ambre"],
	&"foret": [&"camp_ombre", &"marais", &"plaines"],
	&"camp_ombre": [&"foret"],
	&"marais": [&"desert", &"foret", &"temple_englouti"],
	&"temple_englouti": [&"marais"],
	&"desert": [&"cote", &"marais", &"sanctuaire_vents"],
	&"sanctuaire_vents": [&"desert"],
	&"cote": [&"desert", &"grottes_marines", &"monts", &"recif_sanctuaire"],
	&"grottes_marines": [&"cote", &"recif_sanctuaire"],
	&"recif_sanctuaire": [&"cote", &"grottes_marines"],
	&"monts": [&"cieux", &"cote", &"grottes_glace", &"sanctuaire_givre"],
	&"grottes_glace": [&"monts"],
	&"sanctuaire_givre": [&"monts"],
	&"cieux": [&"monts", &"nids_geants"],
	&"nids_geants": [&"arche_du_vent", &"cieux"],
	&"arche_du_vent": [&"champs_cendres", &"nids_geants"],
	&"champs_cendres": [&"arche_du_vent", &"forges_ombre"],
	&"forges_ombre": [&"champs_cendres", &"coulees_lave"],
	&"coulees_lave": [&"forges_ombre", &"porte_cratere", &"sanctuaire_magma"],
	&"sanctuaire_magma": [&"coulees_lave"],
	&"porte_cratere": [&"coulees_lave", &"terre_apex"],
	&"terre_apex": [&"coeur_apex", &"porte_cratere"],
	&"coeur_apex": [&"terre_apex"],
	&"clos_blanc": [],
}


## The next zone on the shortest way from `from` to `to` (in zones), or &"" when Chloé is already
## there or no way is known (a boat, a flight…).
static func next_hop(from: StringName, to: StringName) -> StringName:
	if from == to or not LINKS.has(from) or not LINKS.has(to):
		return &""
	var came_from := {from: &""}
	var queue: Array[StringName] = [from]
	var i := 0
	while i < queue.size():
		var zone := queue[i]
		i += 1
		for n: StringName in LINKS.get(zone, []):
			if came_from.has(n):
				continue
			came_from[n] = zone
			if n == to:
				return _first_step(came_from, from, to)
			queue.append(n)
	return &""


static func _first_step(came_from: Dictionary, from: StringName, to: StringName) -> StringName:
	var step := to
	while came_from[step] != from:
		step = came_from[step]
	return step


## Where to head in zone `zone` (its scene `region`, null: unknown) for objective `goal` (Objectives),
## Chloé being at `here` (tiles): {} without objective, else
##   tile: the objective's place in this zone, or — when it is elsewhere — the nearest way into the next
##         zone on the way; Vector2.INF: nothing to point to;
##   via: that next zone (&"" when the objective is here); dest: the objective's zone;
##   kind: "sortie" (an edge of the map), "entrée" (a door, a cave mouth), "plongée", or "".
static func heading(goal: Dictionary, zone: StringName, region: Region, here: Vector2) -> Dictionary:
	if goal.is_empty():
		return {}
	var dest: StringName = goal.get("zone", &"")
	if dest == &"" or dest == zone:
		return {"tile": goal.get("tile", Vector2.INF), "via": &"", "kind": "", "dest": dest}
	var via := next_hop(zone, dest)
	if via == &"":
		return {"tile": Vector2.INF, "via": dest, "kind": "", "dest": dest}
	var best := {"tile": Vector2.INF, "via": via, "kind": "sortie", "dest": dest}
	if region == null:
		return best
	for way in ways_into(region, via):
		var tile: Vector2 = way["tile"]
		if best["tile"] == Vector2.INF or here.distance_to(tile) < here.distance_to(best["tile"]):
			best["tile"] = tile
			best["kind"] = way["kind"]
	return best


## The ways from `region` into zone `to`: [{tile (the middle, tiles), kind}]. Kept for the zone shown
## (its exits do not move; looking for them through the whole zone takes milliseconds).
static func ways_into(region: Region, to: StringName) -> Array[Dictionary]:
	var id := region.get_instance_id()
	if id != _cache_region:
		_cache.clear()
		_cache_region = id
	if not _cache.has(to):
		_cache[to] = _find_ways(region, to)
	return _cache[to]


static var _cache := {}
static var _cache_region := 0


static func _find_ways(region: Region, to: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for exit in region.exits():
		if exit.target_zone == to:
			var kind := "sortie" if region.exit_on_edge(exit) else "entrée"
			out.append({"tile": region.exit_rect(exit).get_center() / TILE, "kind": kind})
	for spot: Node in region.find_children("*", "DiveSpot", true, false):
		if spot.get("target_zone") == to:
			var corner := (spot as Node2D).position + _parent_offset(spot)
			out.append({"tile": corner / TILE + (spot.get("size") as Vector2) / 2.0, "kind": "plongée"})
	return out


## (As Region.exit_rect: the zone is at the origin, a node may sit in one group node.)
static func _parent_offset(node: Node) -> Vector2:
	var parent := node.get_parent() as Node2D
	return parent.position if parent else Vector2.ZERO
