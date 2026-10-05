class_name StoryObstacles3D
extends Node3D
## The story's obstacles of a remodelled 3D zone (its plan's blockers of kinds trunk, boulder, door
## and moon_ford: Blockers3D.plan_of), each where the plan puts it on the new ground, solid and seen,
## until the 2.5D's own rule opens it — the rule is read off the 2.5D node the plan names (`node`):
## - an Obstacle (the tronc Tranche cuts, the rocher Charge breaks, the porte d'ambre Résonance
##   melts): open once its cleared_flag is set;
## - a monument (a door with a `model`: the Grand Crâne, a StoryProp): its model stands for good, its
##   bone solid (a trimesh of its `solid_meshes`; the bones round it are walked through), its mouth the
##   way to the antre; the amber `seal` across the mouth, seen and solid until its hide_flag (crane_ouvert);
## - the gué de lune (a MoonFord): open on full-moon nights (Game.is_full_moon), its amber stones lit;
##   it never closes while Chloé is on it or on its islet.
## They follow the game as it goes (Game.flag_changed; the moon every MOON_CHECK_S).
## Until their own models come (docs/zones-3d/<zone>-plan.md § 11), the tronc, the rocher and the porte
## are stand-ins at the plan's sizes: a log, the nature kit's boulders, a slab of amber.
##
## RÈGLE PROVISOIRE (05/10, Greg : passages ouverts en 3D sans attendre l'étape 2 de l'histoire) —
## PROVISIONAL, à retirer quand l'étape 2 met en scène les capacités en 3D (le compagnon qui agit, les
## débris, la sortie de l'Alpha) : Chloé utilise un obstacle fermé (« E : … ») et
## - la règle du 2,5D d'abord, telle quelle : un dino de l'équipe a la capacité (Game.ability_user) →
##   « X utilise Tranche ! », son drapeau (cleared_flag), l'expérience, la sauvegarde (Obstacle.interact) ;
##   le Crâne avec les trois écailles → ses lignes, crane_ouvert (StoryProp grand_crane, sans l'Alpha) ;
## - sinon, les lignes du 2,5D (ce qui manque), puis le passage s'ouvre quand même, sous un drapeau à
##   lui (PROVISIONAL_FLAG % id), jamais celui de l'histoire : l'histoire ne le croit pas franchi.
## Le gué de lune garde sa règle (la pleine lune). The story finds each obstacle in `obstacles`
## (id → {kind, node, ability, flag, blocked, at, open, body, view, use}).

const ROCK_SCENE := "res://assets/models3d/nature/rocher.glb"
const TOON := preload("res://world3d/render/toon_style.gd")
const MOON_FORD := preload("res://world/moon_ford.gd")
## A monument's locks keep their own glowing amber: left out of the cartoon look (Greg, 05/10).
const UNLIT_PREFIX := "Serrure"
const SEAL_THICK_M := 0.6        # the seal's collision, thicker than its slab (no slipping through)
const MOON_CHECK_S := 0.5
const SOLID_EXTRA_M := 0.5       # a stand-in's collision rises this far over what it shows
const DOOR_SLAB_M := 0.4         # the porte d'ambre's slab (its collision: 1 m, the gorge's walls 1 m in)
const DOOR_SOLID_M := 1.0
const DOOR_GLOW := 0.25         # the slab glows a little (the plan: it lights up when it opens)
const FORD_STONES := 6
const BARK := Color(0.42, 0.29, 0.17)
const AMBER := Color(1.0, 0.66, 0.2, 0.62)
## RÈGLE PROVISOIRE (see above): false puts the 2.5D's rule alone back.
static var provisional := true
const PROVISIONAL_FLAG := "passage_provisoire_3d_%s"
## What Chloé is shown over each obstacle she can use, and how far she can use it from (m: its size).
const VERBS := {"trunk": "trancher", "boulder": "enfoncer", "door": "réveiller l'ambre", "monument": "examiner"}
const USE_REACH_M := 1.2          # beyond the obstacle's half-width
const CRANE_SCALES := 3

var source: ZoneSource
var terrain: ZoneTerrain
## id → {kind, node (the 2.5D's), ability, flag, rule ("flag" | "moon"), at (Vector3), open, body, view}
var obstacles := {}

var _since_moon := 0.0


## Builds the obstacles of `plan` (the plan's story blockers); `gap_axes`: for an obstacle closing a
## hedge's gap, the way the hedge runs there (Blockers3D), else it lies across the nearest path.
func build(src: ZoneSource, ground: ZoneTerrain, plan: Array, gap_axes := {}) -> void:
	source = src
	terrain = ground
	for b: Dictionary in plan:
		var o := _rule_of(b)
		match String(b["kind"]):
			"trunk": _trunk(b, o, gap_axes.get(String(b["id"]), Vector2.ZERO))
			"boulder": _boulder(b, o)
			"door":
				if b.has("model"):
					_monument(b, o)
				else:
					_door(b, o)
			"moon_ford": _ford(b, o)
		obstacles[String(b["id"])] = o
		if o["rule"] == "flag":
			_add_use(String(b["id"]), b, o)
	Game.flag_changed.connect(_on_flag_changed)
	refresh(true)


func _on_flag_changed(_id: StringName, _value: Variant) -> void:
	refresh()


## Opens or closes each obstacle as its rule says now.
func refresh(force := false) -> void:
	for id: String in obstacles:
		var o: Dictionary = obstacles[id]
		var now := _is_open(o)
		if force or now != bool(o["open"]):
			_set_open(o, now)


## Whether the obstacle `id` lets Chloé by now.
func is_open(id: String) -> bool:
	return bool(obstacles.get(id, {}).get("open", true))


func _process(delta: float) -> void:
	_since_moon += delta
	if _since_moon >= MOON_CHECK_S:
		_since_moon = 0.0
		refresh()


# --- the rules -------------------------------------------------------------------------------------

## What opens the obstacle `b`: the flag of the 2.5D node it stands for (Obstacle.cleared_flag,
## StoryProp.hide_flag), or the full moon (MoonFord).
func _rule_of(b: Dictionary) -> Dictionary:
	var o := {"kind": String(b["kind"]), "node": String(b.get("node", "")), "ability": StringName(String(b.get("ability", ""))),
		"flag": &"", "rule": "flag", "open": false, "body": null, "view": null, "at": Vector3.ZERO, "blocked": &"", "use": null,
		"provisional": StringName(PROVISIONAL_FLAG % b["id"]), "monument": b.has("model")}
	var node: Node = source.region.find_child(o["node"], true, false) if o["node"] != "" else null
	if node == null:
		push_error("StoryObstacles3D : nœud du 2,5D introuvable « %s » (obstacle %s) : il reste fermé" % [o["node"], b["id"]])
		return o
	if node.get_script() == MOON_FORD:
		o["rule"] = "moon"
	elif node.get("cleared_flag") != null:
		o["flag"] = node.get("cleared_flag")
		o["ability"] = node.get("ability")
		o["blocked"] = node.get("blocked_dialogue")
	elif node.get("hide_flag") != null:
		o["flag"] = node.get("hide_flag")
	return o


func _is_open(o: Dictionary) -> bool:
	if o["rule"] == "moon":
		return Game.is_full_moon() or (bool(o["open"]) and _out_there(o))
	if provisional and bool(Game.flag(o["provisional"])):
		return true
	return o["flag"] != &"" and bool(Game.flag(o["flag"]))


## Chloé on the ford or on its islet (the 2.5D's MoonFord: it never closes under her).
func _out_there(o: Dictionary) -> bool:
	var chloe := get_tree().get_first_node_in_group(&"player3d") as Node3D
	if chloe == null:
		return false
	var at := to_local(chloe.global_position)
	var p := Vector2(at.x, at.z)
	return (o["rect"] as Rect2).grow(0.4).has_point(p) or p.distance_to(o["islet_at"]) < float(o["islet_r"])


func _set_open(o: Dictionary, open: bool) -> void:
	o["open"] = open
	var body: StaticBody3D = o["body"]
	if body:
		for shape in body.get_children():
			if shape is CollisionShape3D:
				(shape as CollisionShape3D).set_deferred(&"disabled", open)
	var view: Node3D = o["view"]
	if view:
		view.visible = open if o["rule"] == "moon" else not open   # (the ford's stones light up when it opens)
	var use: Interactable3D = o["use"]
	if use:   # (an open passage is not used any more)
		if open:
			use.remove_from_group(&"interactable3d")
			use.set_hinted(false)
		elif use.is_inside_tree():
			use.add_to_group(&"interactable3d")


# --- the provisional rule (RÈGLE PROVISOIRE, see the top) -------------------------------------------

## Something to use at the obstacle's middle, reached from its side.
func _add_use(id: String, b: Dictionary, o: Dictionary) -> void:
	var kind := "monument" if o["monument"] else String(b["kind"])
	var half := float(o.get("use_half", float(b.get("length_m", b.get("width_m", b.get("diameter_m", 2.0)))) * 0.5))
	if kind == "boulder":
		half += float(b.get("eboulis_m", 0.0))
	var use := Use.new()
	use.name = "Utiliser_%s" % id
	use.verb = VERBS.get(kind, "examiner")
	use.reach = half + USE_REACH_M
	use.hint_height = float(b.get("height_m", b.get("diameter_m", 1.5))) + 0.4 if kind != "monument" else 4.6
	use.on_use = func() -> void: await _use(id)
	use.position = o.get("use_at", o["at"])
	add_child(use)
	o["use"] = use


## Chloé uses the obstacle `id`: the 2.5D's rule, else (provisional) it opens all the same.
func _use(id: String) -> void:
	var o: Dictionary = obstacles[id]
	if bool(o["open"]):
		return
	if o["monument"]:   # the Grand Crâne (a StoryProp: its scales, not an ability)
		await _use_monument(o)
		return
	var user := Game.ability_user(o["ability"])
	if user:
		await Dialogue.run([{"text": "%s utilise %s !" % [user.nickname, Abilities.display_name(o["ability"])]}])
		Audio.play_sfx(Obstacle.SFX.get(o["ability"], Obstacle.CHOP), 0.0, 0.05)
		Game.set_flag(o["flag"])
		Game.award_team_xp(Obstacle.XP_CLEARED)
		Save.save_game()
		return
	var lines: Array = DialogueDB.lines(o["blocked"]) if o["blocked"] != &"" else []
	await _open_provisionally(o, lines)


## The Grand Crâne (story/plaines.gd grand_crane, its lines): three scales, it opens; else what is missing.
func _use_monument(o: Dictionary) -> void:
	var n := DialogueDB.ecailles()
	if n >= CRANE_SCALES:
		await Dialogue.run([
			{"text": "Chloé pose les trois écailles d'ambre dans leurs creux. Elles s'y emboîtent parfaitement…"},
			{"text": "L'ambre s'illumine, tiédit… et la porte fond lentement, comme du miel au soleil."}])
		Game.set_flag(o["flag"])
		Save.save_game()
		return
	var left := CRANE_SCALES - n
	await _open_provisionally(o, [
		{"text": "La bouche du crâne est fermée par une porte d'ambre. Trois creux en forme d'écaille y sont gravés."},
		{"text": "Il manque encore %d écaille%s d'ambre." % [left, "s" if left > 1 else ""]}])


## The 2.5D's lines (what is missing), then, under the provisional rule, it opens all the same (its own
## flag, not the story's). One dialogue for it all.
func _open_provisionally(o: Dictionary, lines: Array) -> void:
	var all := lines.duplicate()
	if provisional:
		all.append({"text": "(Version 3D en chantier : le passage s'ouvre pour l'essai, en attendant l'histoire.)"})
	if not all.is_empty():
		await Dialogue.run(all)
	if provisional:
		Game.set_flag(o["provisional"])
		Save.save_game()


## An obstacle Chloé can use (the provisional rule): its `interact` waits for the whole use.
class Use extends Interactable3D:
	var on_use: Callable

	func interact(_player: Node3D) -> void:
		await on_use.call()


# --- the obstacles ----------------------------------------------------------------------------------

func _ground(p: Vector2) -> Vector3:
	return Vector3(p.x, terrain.height_at(p.x, p.y), p.y)


func _xz(value: Variant) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


## The way across: given, or square to the nearest path (+X if there is none).
func _across(at: Vector2, given: Vector2) -> Vector2:
	if given != Vector2.ZERO:
		return given.normalized()
	var way := terrain.path_way_at(at.x, at.y)
	return Vector2(-way.y, way.x) if way != Vector2.ZERO else Vector2.RIGHT


func _story_body(body_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.collision_layer = Layers3D.WORLD
	body.collision_mask = 0
	add_child(body)   # (not in the navigation's sources: it opens while the game runs)
	return body


func _shape(body: StaticBody3D, shape: Shape3D, at: Transform3D) -> void:
	var holder := CollisionShape3D.new()
	holder.shape = shape
	holder.transform = at
	body.add_child(holder)


## The tronc: a log `length_m` long across the gap, `diameter_m` thick, lying on the ground.
func _trunk(b: Dictionary, o: Dictionary, way: Vector2) -> void:
	var at := _xz(b["at"])
	var across := _across(at, way)
	var length := float(b["length_m"])
	var d := float(b["diameter_m"])
	var foot := _ground(at)
	var yaw := atan2(-across.y, across.x)   # (local X along `across`)
	o["at"] = foot
	var body := _story_body("Tronc_%s" % b["id"])
	var box := BoxShape3D.new()
	box.size = Vector3(length, d + SOLID_EXTRA_M, d)
	_shape(body, box, Transform3D(Basis(Vector3.UP, yaw), foot + Vector3(0, (d + SOLID_EXTRA_M) * 0.5 - 0.15, 0)))
	o["body"] = body
	var wood := MeshInstance3D.new()
	wood.name = "Tronc"
	var mesh := CylinderMesh.new()
	mesh.top_radius = d * 0.5
	mesh.bottom_radius = d * 0.5
	mesh.height = length
	mesh.radial_segments = 14
	wood.mesh = mesh
	wood.material_override = _plain(BARK)
	# the cylinder stands along Y: laid down along X, then turned across the way
	wood.transform = Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, PI * 0.5), foot + Vector3(0, d * 0.5 - 0.12, 0))
	add_child(wood)
	TOON.apply(wood, {"fade": false})
	o["view"] = wood


## The rocher: a boulder `diameter_m` wide and its rubble either side (`eboulis_m`), across the way;
## all of it solid, all of it gone once broken.
func _boulder(b: Dictionary, o: Dictionary) -> void:
	var at := _xz(b["at"])
	var across := _across(at, Vector2.ZERO)
	var d := float(b["diameter_m"])
	var rubble := float(b.get("eboulis_m", 2.0))
	o["at"] = _ground(at)
	var body := _story_body("Rocher_%s" % b["id"])
	var view := Node3D.new()
	view.name = "Rocher"
	add_child(view)
	var spots := [[at, d * 0.5]]
	for side in [-1.0, 1.0]:
		spots.append([at + across * side * (d * 0.5 + rubble * 0.5), rubble * 0.5 + 0.1])
	var k := 0
	for spot: Array in spots:
		var p: Vector2 = spot[0]
		var r: float = spot[1]
		var foot := _ground(p)
		var cyl := CylinderShape3D.new()
		cyl.radius = r
		cyl.height = r * 2.0 + SOLID_EXTRA_M
		_shape(body, cyl, Transform3D(Basis.IDENTITY, foot + Vector3(0, cyl.height * 0.5 - 0.3, 0)))
		var rock := _rock(r * 2.0, k)
		if rock:
			rock.position = foot + Vector3(0, -0.15, 0)
			view.add_child(rock)
		k += 1
	o["body"] = body
	o["view"] = view


## A boulder of the nature kit, `width` m across, turned its own way.
func _rock(width: float, k: int) -> Node3D:
	if not ResourceLoader.exists(ROCK_SCENE):
		return null
	var rock: Node3D = (load(ROCK_SCENE) as PackedScene).instantiate()
	var size := _bounds(rock).size
	var s := width / maxf(maxf(size.x, size.z), 0.01)
	rock.scale = Vector3(s, s * (0.85 if k == 0 else 0.7), s)
	rock.rotation.y = k * 2.1 + 0.4
	TOON.apply(rock, {"fade": false})
	return rock


## The porte d'ambre: a slab of amber `width_m` × `height_m` across the gorge, its collision a little
## wider (into the gorge's walls) and thicker.
func _door(b: Dictionary, o: Dictionary) -> void:
	var at := _xz(b["at"])
	var across := _across(at, Vector2.ZERO)
	var w := float(b["width_m"])
	var h := float(b["height_m"])
	var foot := _ground(at)
	var yaw := atan2(-across.y, across.x)
	o["at"] = foot
	var body := _story_body("Porte_%s" % b["id"])
	var box := BoxShape3D.new()
	box.size = Vector3(w + 2.0, h + SOLID_EXTRA_M, DOOR_SOLID_M)
	_shape(body, box, Transform3D(Basis(Vector3.UP, yaw), foot + Vector3(0, (h + SOLID_EXTRA_M) * 0.5 - 0.3, 0)))
	o["body"] = body
	var slab := MeshInstance3D.new()
	slab.name = "PorteAmbre"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, h, DOOR_SLAB_M)
	slab.mesh = mesh
	slab.material_override = _amber(DOOR_GLOW)
	slab.transform = Transform3D(Basis(Vector3.UP, yaw), foot + Vector3(0, h * 0.5 - 0.3, 0))
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(slab)
	o["view"] = slab


## A monument (the Grand Crâne) at the plan's place, its model's origin on the ground there, unturned
## (it faces south); its bone solid; the seal across its mouth, seen and solid until it opens.
func _monument(b: Dictionary, o: Dictionary) -> void:
	var at := _xz(b["at"])
	var foot := _ground(at)
	o["at"] = foot
	var model := String(b["model"])
	if not ResourceLoader.exists(model):
		push_error("StoryObstacles3D : modèle absent (%s) : %s reste ouvert" % [model, b["id"]])
		return
	var crane: Node3D = (load(model) as PackedScene).instantiate()
	crane.name = String(b["id"]).to_pascal_case()
	crane.position = foot
	add_child(crane)
	var bone := StaticBody3D.new()
	bone.name = "Os"
	bone.collision_layer = Layers3D.WORLD
	bone.collision_mask = 0
	bone.add_to_group(&"nav_source")   # (it stands for good)
	crane.add_child(bone)
	for mi: MeshInstance3D in crane.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name) in b.get("solid_meshes", []):
			_shape(bone, mi.mesh.create_trimesh_shape(), _to(mi, crane))
		if not mi.name.begins_with(UNLIT_PREFIX):
			TOON.apply(mi, {"fade": false})
	if not ResourceLoader.exists(String(b.get("seal", ""))):
		return
	var seal: Node3D = (load(String(b["seal"])) as PackedScene).instantiate()
	seal.name = "Sceau"
	seal.position = foot
	add_child(seal)
	var slab := _bounds(seal)
	var body := _story_body("Sceau_%s" % b["id"])
	var box := BoxShape3D.new()
	box.size = Vector3(slab.size.x, slab.size.y, maxf(slab.size.z, SEAL_THICK_M))
	_shape(body, box, Transform3D(Basis.IDENTITY, foot + slab.get_center()))
	o["body"] = body
	o["view"] = seal
	o["use_at"] = foot + Vector3(slab.get_center().x, 0.0, slab.end.z)   # (used from in front of the seal)
	o["use_half"] = slab.size.x * 0.5


## The gué de lune: its shoal (`rect`) closed by a box up over the water; at the full moon it opens and
## its amber stones light up, from the shore to the islet.
func _ford(b: Dictionary, o: Dictionary) -> void:
	var rc: Array = b["rect"]
	var rect := Rect2(float(rc[0]), float(rc[1]), float(rc[2]), float(rc[3]))
	var islet: Dictionary = b.get("islet", {})
	o["rect"] = rect
	o["islet_at"] = _xz(islet.get("center", [rect.get_center().x, rect.end.y]))
	o["islet_r"] = maxf(float(islet.get("radii", [2.0, 2.0])[0]), float(islet.get("radii", [2.0, 2.0])[1])) + float(islet.get("edge_m", 1.0))
	var c := rect.get_center()
	o["at"] = _ground(c)
	var lo := INF
	for p in [rect.position, rect.end, Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.position.y), c]:
		lo = minf(lo, terrain.height_at(p.x, p.y))
	var level := terrain.water_level_at(c.x, c.y)
	var top := (level if level > -INF else terrain.height_at(c.x, c.y)) + 1.4
	var body := _story_body("Gue_%s" % b["id"])
	var box := BoxShape3D.new()
	box.size = Vector3(rect.size.x, top - (lo - 1.0), rect.size.y)
	_shape(body, box, Transform3D(Basis.IDENTITY, Vector3(c.x, (top + lo - 1.0) * 0.5, c.y)))
	o["body"] = body
	var stones := Node3D.new()
	stones.name = "PierresDeLune"
	add_child(stones)
	var islet_at: Vector2 = o["islet_at"]
	var from := Vector2(c.x, rect.position.y)
	for k in FORD_STONES:
		var p := from.lerp(islet_at, (k + 0.5) / FORD_STONES) + Vector2(0.35 * sin(k * 2.3), 0.0)
		var stone := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.38
		disc.bottom_radius = 0.45
		disc.height = 0.18
		stone.mesh = disc
		stone.material_override = _amber(1.6)
		stone.position = Vector3(p.x, maxf(terrain.height_at(p.x, p.y), level - 0.06) + 0.05, p.y)
		stones.add_child(stone)
	o["view"] = stones


# --- looks ------------------------------------------------------------------------------------------

func _plain(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 1.0
	return mat


## Translucent, glowing amber (the 2.5D's porte d'ambre, the locks of the Crâne).
func _amber(glow := 0.6) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = AMBER
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(AMBER.r, AMBER.g * 0.8, AMBER.b * 0.5)
	mat.emission_energy_multiplier = glow
	mat.roughness = 0.25
	mat.rim_enabled = true
	return mat


## A model's meshes' bounds, in its own space (its root's).
static func _bounds(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var box := _to(mi, root) * mi.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out


## `node`'s transform in `root`'s space (out of the tree too).
static func _to(node: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t
