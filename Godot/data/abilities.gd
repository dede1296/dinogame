class_name Abilities
## What a dino can do out in the world (like Pokémon HMs), from what it is: its family (a
## raptor slices, a ceratopsian charges) or its species (only the small hunters have Flair,
## only the big ones carry Chloé). `soon`: planned, not playable yet (shown on its sheet).
## `adult`: only a grown dino can (a hatchling does not carry anyone): from ADULT_LEVEL.
## `icon`: how its sheet draws it (see draw_icon).
## Who can carry, fly, swim is chosen species by species, for what they really were:
##   Monture: big walkers with a back to sit on — horned faces (behind the frill), duck-bills,
##     Iguanodon, the ostrich-like Gallimimus, the low and wide Ankylosaurus. Not the raptors
##     (too small), not the Stegosaurus (plates), not the giant sauropods (out of reach).
##   Vol: only the great pterosaurs (the Dimorphodon is far too small).
##   Nage: the spinosaurids, at home in rivers; the sea reptiles too.   Plongée: the sea reptiles.

const ADULT_LEVEL := 15

const DEFS := {
	&"tranche": {"name": "Tranche", "icon": "claw", "part": &"front_legs", "families": [&"raptor"],
		"desc": "Griffes acérées : tranche les troncs et les ronces."},
	&"charge": {"name": "Charge", "icon": "horn", "part": &"head", "families": [&"ceratopsian", &"armored"],
		"desc": "Fonce tête baissée : brise les gros rochers."},
	&"resonance": {"name": "Résonance", "icon": "notes", "part": &"head", "families": [&"hadrosaur"],
		"desc": "Sa crête chante : l'ambre endormi s'éveille et les portes d'ambre s'ouvrent."},
	&"flair": {"name": "Flair", "icon": "paw", "part": &"head", "species": [&"compsognathus", &"troodon", &"oviraptor"],
		"desc": "Un nez infaillible : sent ce qui est enfoui et le déterre."},
	&"monture": {"name": "Monture", "icon": "saddle", "part": &"back_legs", "soon": true, "adult": true,
		"species": [&"triceratops", &"styracosaurus", &"parasaurolophus", &"corythosaurus", &"edmontosaurus", &"maiasaura",
			&"iguanodon", &"gallimimus", &"ankylosaurus"],
		"desc": "Assez grand pour porter Chloé : on voyage bien plus vite."},
	&"vol": {"name": "Vol", "icon": "wing", "part": &"back", "soon": true, "adult": true, "species": [&"pteranodon", &"quetzalcoatlus"],
		"desc": "Emporte Chloé dans les airs : falaises, îlots, et d'une région visitée à l'autre."},
	&"nage": {"name": "Nage", "icon": "wave", "part": &"tail", "soon": true, "adult": true,
		"species": [&"baryonyx", &"suchomimus", &"spinosaurus"], "families": [&"marine"],
		"desc": "Traverse l'eau profonde et les rivières, Chloé sur le dos."},
	&"plongee": {"name": "Plongée", "icon": "bubbles", "part": &"tail", "soon": true, "adult": true, "families": [&"marine"],
		"desc": "Descend sous l'eau : grottes marines, épaves, récifs."},
}


static func has(dino: Dino, ability: StringName) -> bool:
	var def: Dictionary = DEFS.get(ability, {})
	if def.is_empty():
		push_error("Capacité inconnue : %s" % ability)
		return false
	var species := dino.part_species(def["part"])
	return species.family in def.get("families", []) or species.id in def.get("species", [])


## It has the ability and is grown enough to use it.
static func usable(dino: Dino, ability: StringName) -> bool:
	return has(dino, ability) and (not DEFS[ability].get("adult", false) or dino.level >= ADULT_LEVEL)


static func display_name(ability: StringName) -> String:
	return DEFS.get(ability, {}).get("name", String(ability))


## The exploration abilities `dino` can use (ids of DEFS), in their order there.
static func of(dino: Dino) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in DEFS:
		if has(dino, id):
			out.append(id)
	return out


## One line per ability of `dino`: « Capacité Flair — Un nez infaillible… ».
static func describe(dino: Dino) -> Array[String]:
	var out: Array[String] = []
	for id in of(dino):
		out.append("Capacité %s — %s" % [DEFS[id]["name"], DEFS[id]["desc"]])
	return out


## Draws an ability's little picture, centred on `c`, about `s` px wide.
static func draw_icon(ci: CanvasItem, icon: String, c: Vector2, s: float, colour: Color) -> void:
	var k := s / 32.0
	var w := 2.6 * k
	match icon:
		"claw":   # three slashes
			for i in 3:
				var o := Vector2((i - 1) * 7.0, 0) * k
				ci.draw_polyline(PackedVector2Array([c + o + Vector2(-5, 11) * k, c + o + Vector2(0, 0) * k, c + o + Vector2(6, -12) * k]), colour, w, true)
		"horn":   # a horn and the shock
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-12, 10) * k, c + Vector2(8, -2) * k, c + Vector2(-6, -2) * k]), colour)
			for a in [-0.6, 0.0, 0.6]:
				var d := Vector2.from_angle(a - 0.4)
				ci.draw_line(c + Vector2(9, -4) * k + d * 4.0 * k, c + Vector2(9, -4) * k + d * 11.0 * k, colour, w)
		"notes":   # two notes
			for n: Array in [[Vector2(-7, 8), 1.0], [Vector2(6, 5), 0.85]]:
				var p: Vector2 = c + (n[0] as Vector2) * k
				ci.draw_circle(p, 4.0 * k * n[1], colour)
				ci.draw_line(p + Vector2(3.5, 0) * k, p + Vector2(3.5, -15) * k, colour, w)
			ci.draw_line(c + Vector2(-3.5, -7) * k, c + Vector2(9.5, -10) * k, colour, w * 1.4)
		"paw":   # a paw print (digging)
			ci.draw_circle(c + Vector2(0, 5) * k, 6.5 * k, colour)
			for p: Vector2 in [Vector2(-8, -3), Vector2(-3, -9), Vector2(3, -9), Vector2(8, -3)]:
				ci.draw_circle(c + p * k, 3.0 * k, colour)
		"saddle":   # a saddle and its stirrup
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -2) * k, c + Vector2(-8, -9) * k, c + Vector2(-2, -4) * k,
				c + Vector2(6, -5) * k, c + Vector2(12, -11) * k, c + Vector2(13, -1) * k, c + Vector2(0, 3) * k]), colour)
			ci.draw_line(c + Vector2(0, 2) * k, c + Vector2(0, 9) * k, colour, w)
			ci.draw_arc(c + Vector2(0, 11) * k, 3.5 * k, 0.0, TAU, 12, colour, w)
		"wing":   # a wing
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-13, 6) * k, c + Vector2(-2, -12) * k, c + Vector2(13, -6) * k,
				c + Vector2(6, -2) * k, c + Vector2(9, 3) * k, c + Vector2(1, 1) * k, c + Vector2(2, 7) * k]), colour)
		"wave":   # two waves
			for row in 2:
				var pts := PackedVector2Array()
				for i in 13:
					pts.append(c + Vector2(-13 + i * 2.2, -3 + row * 8 + sin(i * 0.9) * 3.0) * k)
				ci.draw_polyline(pts, colour, w, true)
		"bubbles":   # bubbles rising
			for b: Array in [[Vector2(-6, 7), 5.0], [Vector2(5, 0), 3.8], [Vector2(-2, -8), 2.8], [Vector2(8, -11), 2.0]]:
				ci.draw_arc(c + (b[0] as Vector2) * k, b[1] * k, 0.0, TAU, 16, colour, w * 0.8)
		_:
			ci.draw_circle(c, 6.0 * k, colour)
