class_name Npcs3D
extends Node3D
## The people of a 3D zone (docs/migration-3d.md, « Npc → Npc3D »), built when it starts from the
## 2.5D zone itself, like its scenery (Scatter3D) and its dinos: the same people, facing the same
## way, saying the same things — and the story's dinos (DinoNpc → DinoNpc3D: the Grand Voyageur, an
## Alpha). Who is there is the story's (show_flag / hide_flag), as in the 2.5D.
## Where they stand: the 2.5D's place, on the ground the zone is drawn with (ZoneTerrain.height_at).
## A REMODELLED zone (its plan's relief: docs/conception-zones-3d.md) moved its places by groups of
## scenes: there, each one stands where the plan puts them (npcs3d/<zone>.json, a copy of the plan's
## anchors — docs/ is not exported with the game). Once the zone's bodies are in the physics, anyone
## found in something solid, in the water or on too steep a slope is moved to the nearest free ground
## (SPOT_REACH_M at most), and that is noted (`spots`, the console).
## Used by Zone3D (or any other scene) with the ZoneSource and the ZoneTerrain it already has:
##
##     npcs = Npcs3D.new()
##     npcs.name = "Npcs"
##     add_child(npcs)
##     npcs.build(source, terrain)

## Everyone checked, and moved if they had to be (the tests wait for it).
signal settled

## A remodelled zone's places for its people, as the game reads them (the plan's anchors).
const PLACES_DIR := "res://world3d/actors/npcs3d/"
const OLD_DRIFT_M := 1.0       # the 2.5D's place further than this from the plan's « old »: said
const SPOT_REACH_M := 6.0      # how far from their place someone is moved, at most, to free ground
const SPOT_STEP_M := 0.5
const STEEP_DEG := 30.0        # steeper than this, no one is left standing there
const KNEE_M := 0.4            # what is in the way stands between the knee and the head
const HEAD_MIN_M := 1.5
const EDGE_M := 1.0            # kept this far inside the zone
const SOLID := Layers3D.WORLD | Layers3D.WATER

var people: Array[Npc3D] = []
var dinos: Array[DinoNpc3D] = []
## Where each one stands: node name → {from (the 2.5D's place), at, moved_m (from the 2.5D's place),
## why ("2,5D", "plan", "plan, écarté de … m : …")}.
var spots := {}
var is_settled := false

var _source: ZoneSource
var _ground: ZoneTerrain


## Puts down everyone the story has in the zone right now (their show_flag / hide_flag), on the
## ground of `ground`.
func build(src: ZoneSource, ground: ZoneTerrain) -> void:
	_source = src
	_ground = ground
	var places := places_of(src.id) if ground.is_remodelled() else {}
	for data in NpcSource.read(src):
		var npc := Npc3D.create(data)
		add_child(npc)
		npc.place_on(ground, _spot(String(data["name"]), data["at"], places))
		people.append(npc)
	for data in DinoNpc3D.read(src):
		var dino := DinoNpc3D.create(data)
		if dino == null:
			print("Npcs3D : %s (%s) n'a pas encore de fiche 3D : pas posé" % [data["name"], data["species_id"]])
			continue
		add_child(dino)
		dino.place_on(ground, _spot(String(data["name"]), data["at"], places))
		dinos.append(dino)
	_settle()


## The person called `node_name` in the 2.5D zone ("Maia", "Elise"…), for a scene; null if the
## story does not have them there.
func person(node_name: StringName) -> Npc3D:
	for npc in people:
		if npc.name == node_name:
			return npc
	return null


## The story's dino called `node_name` ("GrandVoyageur", "Alpha"…); null if it is not there.
func dino(node_name: StringName) -> DinoNpc3D:
	for d in dinos:
		if d.name == node_name:
			return d
	return null


## The people and the story's dinos.
func everyone() -> Array[Node3D]:
	var out: Array[Node3D] = []
	out.append_array(people)
	out.append_array(dinos)
	return out


## Who was placed, and how tall they are: for the log and the tests.
func counts() -> Dictionary:
	var out := {}
	for npc in people:
		out[String(npc.name)] = "%.2f m" % npc.height_m
	for d in dinos:
		out[String(d.name)] = "%s, %.1f m de long" % [d.species.id, d.length_m]
	return out


## A remodelled zone's places (npcs3d/<zone>.json): node name → {old, at, group}; {} without a file.
static func places_of(zone_id: StringName) -> Dictionary:
	var path := PLACES_DIR + String(zone_id) + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not (data as Dictionary).get("people") is Dictionary:
		push_error("Npcs3D : %s illisible (attendu {\"people\": {nom: {old, at}}}) : places du 2,5D" % path)
		return {}
	return data["people"]


## Where `who` stands: the plan's place in a remodelled zone (when it lists them), else the 2.5D's.
func _spot(who: String, from: Vector3, places: Dictionary) -> Vector3:
	var at := from
	var why := "2,5D"
	var entry: Variant = places.get(who)
	if entry is Dictionary and (entry as Dictionary).get("at") is Array:
		var old := _xz(entry.get("old", [from.x, from.z]))
		if old.distance_to(Vector2(from.x, from.z)) > OLD_DRIFT_M:
			push_warning("Npcs3D : %s n'est plus là où le plan l'a pris (2,5D (%.1f, %.1f), plan %s) : mis à la place du plan" % [who, from.x, from.z, old])
		var p := _xz(entry["at"])
		at = Vector3(p.x, 0.0, p.y)
		why = "plan"
	spots[who] = {"from": from, "at": at, "moved_m": Vector2(at.x - from.x, at.z - from.z).length(), "why": why}
	return at


static func _xz(value: Variant) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) if value is Array else Vector2.ZERO


## Once the zone's bodies are in the physics (two physics frames): anyone in something solid, in the
## water or on too steep a slope goes to the nearest free ground. Then `settled`.
func _settle() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	var space := get_world_3d().direct_space_state
	var skip := _ground_rid()
	var moved: Array[String] = []
	for actor in everyone():
		if not is_instance_valid(actor):
			continue
		var who := String(actor.name)
		var r := float(actor.get("radius"))
		var tall := maxf(float(actor.get("height_m")), HEAD_MIN_M)
		var here := Vector2(actor.global_position.x, actor.global_position.z)
		var why := _what_stops(space, skip, here, r, tall)
		if why == "":
			continue
		var free := _nearest_free(space, skip, here, r, tall)
		if free == Vector2.INF:
			push_warning("Npcs3D : %s est en (%.1f, %.1f) %s, sans sol libre à moins de %.0f m : laissé là" % [who, here.x, here.y, why, SPOT_REACH_M])
			continue
		actor.call(&"place_on", _ground, Vector3(free.x, 0.0, free.y))
		var spot: Dictionary = spots.get(who, {"from": actor.global_position, "why": "2,5D"})
		var from: Vector3 = spot["from"]
		spot["at"] = Vector3(free.x, 0.0, free.y)
		spot["moved_m"] = Vector2(free.x - from.x, free.y - from.z).length()
		spot["why"] = "%s, écarté de %.1f m : %s" % [spot["why"], here.distance_to(free), why]
		spots[who] = spot
		moved.append("%s (%s)" % [who, spot["why"]])
	if not moved.is_empty():
		print("Npcs3D : %s" % ", ".join(moved))
	is_settled = true
	settled.emit()


## What keeps anyone from standing at `p` with a body of radius `r`, `tall` m high: "" if nothing.
func _what_stops(space: PhysicsDirectSpaceState3D, skip: RID, p: Vector2, r: float, tall: float) -> String:
	var size := _source.size_m()
	if p.x < EDGE_M or p.y < EDGE_M or p.x > size.x - EDGE_M or p.y > size.y - EDGE_M:
		return "hors de la zone"
	if _ground.water_depth_at(p.x, p.y) > 0.0:
		return "dans l'eau"
	var slope := _slope_deg(p)
	if slope > STEEP_DEG:
		return "sur une pente de %.0f°" % slope
	var params := PhysicsShapeQueryParameters3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = r
	cylinder.height = tall - KNEE_M
	params.shape = cylinder
	params.collision_mask = SOLID
	if skip.is_valid():
		params.exclude = [skip]
	params.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, _ground.height_at(p.x, p.y) + (KNEE_M + tall) * 0.5, p.y))
	var hits := space.intersect_shape(params, 1)
	if hits.is_empty():
		return ""
	var what: Object = hits[0].get("collider")
	return "dans %s" % (String(what.name) if what is Node else "un obstacle")


## The nearest point within SPOT_REACH_M of `p` where nothing stops anyone (rings of SPOT_STEP_M);
## Vector2.INF if there is none.
func _nearest_free(space: PhysicsDirectSpaceState3D, skip: RID, p: Vector2, r: float, tall: float) -> Vector2:
	var ring := SPOT_STEP_M
	while ring <= SPOT_REACH_M + 0.001:
		var around := maxi(8, ceili(TAU * ring / SPOT_STEP_M))
		for k in around:
			var q := p + Vector2.from_angle(TAU * k / around) * ring
			if _what_stops(space, skip, q, r, tall) == "":
				return q
		ring += SPOT_STEP_M
	return Vector2.INF


func _slope_deg(p: Vector2) -> float:
	var e := 0.5
	var gx := (_ground.height_at(p.x + e, p.y) - _ground.height_at(p.x - e, p.y)) / (2.0 * e)
	var gz := (_ground.height_at(p.x, p.y + e) - _ground.height_at(p.x, p.y - e)) / (2.0 * e)
	return rad_to_deg(atan(Vector2(gx, gz).length()))


## The ground's own collision, left out of the queries (its slopes are looked at on the relief).
func _ground_rid() -> RID:
	if _ground.body:
		return _ground.body.get_rid()
	var holder: Node = _ground.ground3d
	var t3d: Object = holder.get("terrain") if holder else null
	var collision: Object = t3d.get("collision") if t3d else null
	if collision and collision.has_method("get_rid"):
		return collision.call("get_rid")
	return RID()
