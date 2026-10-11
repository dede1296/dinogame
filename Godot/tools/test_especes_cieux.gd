extends SceneTree
## Les espèces des Cieux Éternels (chapitre 7) : (a) chaque fiche se charge (famille ptérosaure, type
## Vent, description, rareté), ses planches sont là et à la bonne grille (profil 3 × 2, face/dos 4 × 2
## de mêmes cases ; vol `_vol` et `_vol_face_dos` signalées si absentes), sa taille suit la règle du
## gabarit (direction-artistique.md) ; (b) le Dinodex : la fiche (taille, régime, époque, anecdote),
## le Roi parmi les Uniques ; (c) capacités (Vol pour Tapejara, Tupandactylus, Hatzegopteryx et le
## Quetzalcoatlus ; rien pour le Rhamphorhynchus) et attaques de vent au niveau des Cieux ; (d) les
## habitats des trois zones des Cieux (espèces, niveaux 38-44, le Roi jamais sauvage), le froid,
## l'ambiance, le fond de combat, le vide refusé à l'atterrissage ; (e) le harnais et le Sceau.
## Puis une planche de contact : chaque espèce de profil, de face, de dos, et en vol.
##   godot --path Godot --script res://tools/test_especes_cieux.gd --resolution 1600x900 -- out=<dossier>
## (Script compilé avant les autoloads : les données sont chargées par leur chemin.)

const CAPTION := "Espèces des Cieux : fiches, planches (grilles), tailles, Dinodex, capacités, attaques de vent, habitats des 3 zones, froid, vide, objets"
const IDS: Array[StringName] = [&"rhamphorhynchus", &"tapejara", &"tupandactylus", &"hatzegopteryx", &"quetzalcoatlus"]
## Le Pteranodon de la Côte porte aussi Chloé : ses planches de vol sont vérifiées avec les autres.
const ALSO_FLIES: Array[StringName] = [&"pteranodon"]
## Gabarit vu (m) visé pour chacune (√(hauteur × longueur) de l'animal, compressé au-delà de 1,5 m).
const GABARIT := {&"rhamphorhynchus": 0.55, &"tapejara": 0.7, &"tupandactylus": 1.0, &"hatzegopteryx": 2.7, &"quetzalcoatlus": 3.2}
const FLYERS: Array[StringName] = [&"tapejara", &"tupandactylus", &"hatzegopteryx", &"quetzalcoatlus"]
const ZONES := {&"cieux": "res://regions/cieux/cieux.tscn", &"nids_geants": "res://regions/cieux/nids_geants.tscn",
	&"arche_du_vent": "res://regions/cieux/arche_du_vent.tscn"}
const LEVELS := Vector2i(38, 44)
const STRETCH := 1.15
const PX := 48.0

var _out := "user://test_especes_cieux"
var _failed := 0
var _db
var _size
var _vol


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	_db = load("res://data/species_db.gd")
	_size = load("res://actors/dino_size.gd")
	_vol = load("res://story/vol.gd")
	for id in IDS:
		_sheet(id)
	for id in ALSO_FLIES:
		print("— (a) %s (vol)" % id)
		_flight_sheets(id, _db.get_species(id))
	_dex()
	_abilities_and_moves()
	_zones()
	_items()
	await _contact_sheet()
	banner.queue_free()
	print("TEST espèces des Cieux : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


# ------------------------------------------------------------------ (a) les fiches et les planches

func _sheet(id: StringName) -> void:
	print("— (a) %s" % id)
	_check("%s : dans SpeciesDB" % id, _db.PATHS.has(id))
	var sp = _db.get_species(id)
	if sp == null:
		_check("%s : la fiche se charge" % id, false)
		return
	_check("%s : famille ptérosaure (flyer), cri de ptérosaure, description" % id,
		sp.family == &"flyer" and sp.cry_prefix == "pterosaure" and sp.description.length() > 40)
	var sheet: Texture2D = sp.sheet
	_check("%s : planche de profil 3 × 2 (cases égales)" % id, sheet != null and sheet.get_width() % 3 == 0 and sheet.get_height() % 2 == 0,
		"%s" % (sheet.get_size() if sheet else "absente"))
	var fb: Texture2D = sp.face_back_sheet
	var same_cell: bool = fb != null and sheet != null and fb.get_width() / 4 == sheet.get_width() / 3 and fb.get_height() == sheet.get_height()
	_check("%s : planche face/dos 4 × 2, mêmes cases que le profil" % id, same_cell, "%s" % (fb.get_size() if fb else "absente"))
	var g: float = _gabarit(sp)
	_check("%s : taille vue (gabarit %.2f m, visé %.2f m)" % [id, g, GABARIT[id]], absf(g - GABARIT[id]) < GABARIT[id] * 0.06)
	_flight_sheets(id, sp)


## Ses planches de vol (le format de scratchpad ch7/specs_planches.md) : signalées si absentes.
func _flight_sheets(id: StringName, sp) -> void:
	var vol := "res://assets/art/dinos/%s_vol.png" % id
	var fb := "res://assets/art/dinos/%s_vol_face_dos.png" % id
	if not ResourceLoader.exists(vol):
		print("   %s_vol.png : ABSENTE (en attente de l'agent images ; il vole avec sa marche)" % id)
		return
	var side: Texture2D = load(vol)
	_check("%s : planche de vol 4 × 1 (cases égales)" % id, side.get_width() % 4 == 0, str(side.get_size()))
	if not ResourceLoader.exists(fb):
		print("   %s_vol_face_dos.png : ABSENTE (de face et de dos, il vole avec sa marche)" % id)
		return
	var front: Texture2D = load(fb)
	_check("%s : planche de vol face/dos 4 × 2 (cases égales)" % id, front.get_width() % 4 == 0 and front.get_height() % 2 == 0, str(front.get_size()))
	var k: float = load("res://actors/wings.gd").face_back_scale(sp)
	print("   %s : de face, ailes à plat %s que de profil → montrée ×%.2f" % [id, "plus étroites" if k > 1.0 else "au moins aussi larges", k])


## √(hauteur × longueur) vu de son image debout, à l'échelle du monde (m).
func _gabarit(sp) -> float:
	var r: Rect2 = _size.drawn(sp)
	return sqrt(r.size.y * STRETCH * r.size.x) * sp.world_scale / PX


# ------------------------------------------------------------------ (b) le Dinodex

func _dex() -> void:
	print("— (b) le Dinodex")
	var facts = load("res://data/dex_facts.gd")
	for id in IDS:
		var f: Dictionary = facts.INFO.get(id, {})
		_check("%s : fiche du Dinodex (taille, régime, époque, lieu, signe, anecdote)" % id,
			["size", "diet", "era", "from", "trait", "fact"].all(func(k: String) -> bool: return String(f.get(k, "")) != ""))
	var unique: Array = facts.UNIQUES.filter(func(u: Dictionary) -> bool: return u["id"] == &"quetzalcoatlus")
	_check("le Quetzalcoatlus Roi est parmi les Uniques (Alpha des Cieux)", unique.size() == 1 and unique[0]["region"] == &"cieux")
	var order: Array = load("res://data/dex_db.gd").order()
	_check("les 4 espèces sauvages sont dans la liste du Dinodex, pas le Roi",
		IDS.slice(0, 4).all(func(id: StringName) -> bool: return id in order) and not &"quetzalcoatlus" in order)


# ------------------------------------------------------------------ (c) capacités, attaques

func _abilities_and_moves() -> void:
	print("— (c) capacités et attaques")
	var dino = load("res://game/dino.gd")
	var abilities = load("res://data/abilities.gd")
	var moves = load("res://data/moves_db.gd")
	for id in IDS:
		var d = dino.create(id, 40)
		var vol: bool = &"vol" in abilities.of(d)
		_check("%s : Vol %s" % [id, "oui" if id in FLYERS else "non (trop petit)"], vol == (id in FLYERS))
		var wind: Array = d.moves.filter(func(m: Dictionary) -> bool:
			var mv: Dictionary = moves.move(m["id"])
			return mv["type"] == "vent" and mv["power"] >= 80)
		_check("%s niv. 40 : une forte attaque de vent (Piqué, Cyclone…)" % id, not wind.is_empty(),
			", ".join(d.moves.map(func(m: Dictionary) -> String: return moves.move(m["id"])["name"])))
	var roi = dino.create(&"quetzalcoatlus", 44, "Quetzalcoatlus Roi")
	_check("le Roi niv. 44 connaît Cyclone", roi.moves.any(func(m: Dictionary) -> bool: return m["id"] == &"cyclone"))
	var ptero = dino.create(&"pteranodon", 35)
	_check("un Pteranodon de la Côte (niv. 35) n'a pas changé (rien de nouveau avant 36)",
		not ptero.moves.any(func(m: Dictionary) -> bool: return m["id"] in [&"ventArriere", &"piqueAerien", &"cyclone"]))


# ------------------------------------------------------------------ (d) les zones

func _zones() -> void:
	print("— (d) les zones des Cieux")
	var seen := {}
	var ambience = load("res://data/ambience_db.gd")
	for zone: StringName in ZONES:
		if not ResourceLoader.exists(ZONES[zone]):
			print("   %s : zone pas encore construite (agent carte)" % zone)
			continue
		var region = load("res://world/region.gd").open_for_preview(ZONES[zone])
		_check("%s : zone froide (manteau)" % zone, region.cold)
		_check("%s : son ambiance existe (%s)" % [zone, region.ambience_id], ambience.has(region.ambience_id) and region.ambience_id == zone)
		_check("%s : un fond de combat" % zone, region.battle_backdrop != null)
		for h in region.find_children("*", "Habitat", true, false):
			for e in h.encounters:
				var ok: bool = e.levels.x >= LEVELS.x - 1 and e.levels.y <= LEVELS.y
				seen[e.species] = seen.get(e.species, []) + ["%s %d-%d" % [zone, e.levels.x, e.levels.y]]
				if not ok:
					_check("%s : %s aux niveaux des Cieux" % [zone, e.species], false, str(e.levels))
		_void(zone, region)
		region.free()
	for id in IDS.slice(0, 4):
		_check("%s vit dans les Cieux" % id, seen.has(id), str(seen.get(id, "")))
	_check("le Quetzalcoatlus n'est jamais sauvage (le Roi est une rencontre de l'histoire)", not seen.has(&"quetzalcoatlus"))


## Le vide : une case de la mer de nuages refusée, une case d'un piton (loin du bord) acceptée.
func _void(zone: StringName, region) -> void:
	var size: Vector2i = region.map_size()
	var void_cell := Vector2i(-1, -1)
	var solid_cell := Vector2i(-1, -1)
	for y in range(2, size.y - 2):
		for x in range(2, size.x - 2):
			var c := Vector2i(x, y)
			if void_cell.x < 0 and _vol.is_void(region, c):
				void_cell = c
			if solid_cell.x < 0 and _vol.landing_problem(region, (Vector2(c) + Vector2(0.5, 0.5)) * PX) == "":
				solid_cell = c
	_check("%s : le vide est marqué (méta)" % zone, void_cell.x >= 0)
	if void_cell.x >= 0:
		var why: String = _vol.landing_problem(region, (Vector2(void_cell) + Vector2(0.5, 0.5)) * PX)
		_check("%s : se poser dans le vide est refusé (« %s »)" % [zone, why], why == _vol.LAND_VOID or why == _vol.LAND_NARROW)
	_check("%s : il y a des pitons où se poser" % zone, solid_cell.x >= 0)


# ------------------------------------------------------------------ (e) les objets

func _items() -> void:
	print("— (e) le harnais et le Sceau")
	var items = load("res://data/items_db.gd")
	for id in ["harnais_vol", "sceau_cieux"]:
		var it: Dictionary = items.item(id)
		_check("%s : objet clé, jamais vendu" % id, it["kind"] == "cle" and it["sell"] == 0 and it["desc"] != "")
		var icon := "res://assets/art/ui/%s.png" % id
		print("   %s.png : %s" % [id, "présente" if ResourceLoader.exists(icon) else "ABSENTE (l'ambre la remplace ; agent images)"])


# ------------------------------------------------------------------ la planche de contact

func _contact_sheet() -> void:
	var layer := CanvasLayer.new()
	var bg := ColorRect.new()
	bg.color = Color(0.86, 0.9, 0.95)
	bg.size = Vector2(1600, 900)
	layer.add_child(bg)
	root.add_child(layer)
	for i in IDS.size():
		var sp = _db.get_species(IDS[i])
		var y := 70.0 + i * 165.0
		_label(layer, sp.display_name, Vector2(20, y + 60))
		_frame(layer, sp.sheet, 3, 2, 3, Vector2(230, y), 150.0)
		if sp.face_back_sheet:
			_frame(layer, sp.face_back_sheet, 4, 2, 1, Vector2(420, y), 150.0)
			_frame(layer, sp.face_back_sheet, 4, 2, 5, Vector2(590, y), 150.0)
		var fly := "res://assets/art/dinos/%s_vol.png" % IDS[i]
		if ResourceLoader.exists(fly):
			_frame(layer, load(fly), 4, 1, 1, Vector2(780, y), 150.0)
		else:
			_label(layer, "(vol : pas encore dessiné)", Vector2(800, y + 60))
		var flyfb := "res://assets/art/dinos/%s_vol_face_dos.png" % IDS[i]
		if ResourceLoader.exists(flyfb):
			_frame(layer, load(flyfb), 4, 2, 1, Vector2(1080, y), 150.0)
			_frame(layer, load(flyfb), 4, 2, 5, Vector2(1300, y), 150.0)
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/especes_cieux.png" % _out)
	layer.queue_free()


func _frame(layer: CanvasLayer, sheet: Texture2D, cols: int, rows: int, index: int, at: Vector2, height: float) -> void:
	var cell := Vector2(sheet.get_width() / float(cols), sheet.get_height() / float(rows))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(index % cols, index / cols) * cell, cell)
	var pic := TextureRect.new()
	pic.texture = atlas
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.position = at
	pic.size = Vector2(height * cell.x / cell.y, height)
	layer.add_child(pic)


func _label(layer: CanvasLayer, text: String, at: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_font_size_override(&"font_size", 22)
	l.add_theme_color_override(&"font_color", Color(0.1, 0.12, 0.18))
	layer.add_child(l)


# ------------------------------------------------------------------ outils

func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])
