extends SceneTree
## Les espèces de la Plaine Volcanique (chapitre 8) : (a) chaque fiche se charge (famille, type, cri,
## description, rareté), ses planches (les siennes, ou le repli tant que l'agent images ne les a pas
## livrées : dit), leur grille, sa taille suit la règle du gabarit (et, sinon, le world_scale / battle_scale
## à poser) ; (b) le Dinodex : la fiche (taille, régime, époque, lieu, signe, anecdote), le T-Rex de Magma
## parmi les Uniques ; (c) capacités (Charge et Monture du Styracosaurus, Cuir de feu du Saichania, du
## Daspletosaurus et du T-Rex) et attaques du volcan (Séisme à 45, Coulée de lave à 46, rien avant) ;
## (d) les objets du chapitre (clés, jamais vendus, icônes signalées) ; (e) les ambiances des cinq zones ;
## (f) les zones si l'agent carte les a construites (ambiance, lave, vol interdit, habitats 42-48, le T-Rex
## jamais sauvage). Puis une planche de contact (profil, face, dos ; corrompu si dessiné).
##   godot --path Godot --script res://tools/test_especes_volcan.gd --resolution 1600x900 -- out=<dossier> [titre=…]
## (Script compilé avant les autoloads : les données sont chargées par leur chemin.)

const CAPTION := "Espèces du Volcan : fiches, planches (ou repli), tailles, Dinodex, Cuir de feu, Séisme/Coulée de lave, objets, ambiances, zones"
const IDS: Array[StringName] = [&"styracosaurus", &"saichania", &"daspletosaurus", &"trex_magma"]
const FAMILY := {&"styracosaurus": [&"ceratopsian", "terre", "ceratopsien"], &"saichania": [&"armored", "pierre", "cuirasse"],
	&"daspletosaurus": [&"tyrant", "feu", "tyran"], &"trex_magma": [&"tyrant", "feu", "tyran"]}
## Gabarit vu (m) visé : √(hauteur × longueur) de l'animal, compressé au-delà de 1,5 m (direction-artistique.md).
const GABARIT := {&"styracosaurus": 2.34, &"saichania": 2.0, &"daspletosaurus": 3.3, &"trex_magma": 3.8}
## Combat : gabarit à l'écran ∝ √ gabarit du monde (battle = world × BATTLE_K / √T, mesuré sur les autres).
const BATTLE_K := 1.99
## Les corrompus des scènes : leur planche « _corrompu » (sinon le shader du combat montre l'ambre noir).
const CORRUPTED: Array[StringName] = [&"styracosaurus", &"saichania", &"allosaurus", &"majungasaurus", &"daspletosaurus"]
const ITEMS := ["antidote_ambre", "sceau_volcan", "coeur_5", "lettre_isaure"]
const ZONES := {&"champs_cendres": "res://regions/volcan/champs_cendres.tscn", &"forges_ombre": "res://regions/volcan/forges_ombre.tscn",
	&"coulees_lave": "res://regions/volcan/coulees_lave.tscn", &"sanctuaire_magma": "res://regions/volcan/sanctuaire_magma.tscn",
	&"porte_cratere": "res://regions/volcan/porte_cratere.tscn"}
const LEVELS := Vector2i(42, 48)
## Où chaque espèce sauvage vit d'abord (bestiaire) : vérifié une fois la zone construite.
const HOME := {&"styracosaurus": &"champs_cendres", &"saichania": &"champs_cendres", &"daspletosaurus": &"coulees_lave"}
const STRETCH := 1.15
const PX := 48.0

var _out := "user://test_especes_volcan"
var _caption := CAPTION
var _failed := 0
var _db
var _size


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("titre="):
			_caption = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	var banner := ShotCaption.show_on(self, _caption)
	_db = load("res://data/species_db.gd")
	_size = load("res://actors/dino_size.gd")
	for id in IDS:
		_sheet(id)
	for id in CORRUPTED:
		var path := "res://assets/art/dinos/%s_corrompu.png" % id
		print("   %s_corrompu.png : %s" % [id, "présente" if ResourceLoader.exists(path) else "ABSENTE (le combat montre l'ambre noir par le shader ; agent images)"])
	_dex()
	_abilities_and_moves()
	_items()
	_ambiences()
	_zones()
	await _contact_sheet()
	banner.queue_free()
	print("TEST espèces du Volcan : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


# ------------------------------------------------------------------ (a) les fiches et les planches

func _sheet(id: StringName) -> void:
	print("— (a) %s" % id)
	_check("%s : dans SpeciesDB" % id, _db.PATHS.has(id))
	var sp = _db.get_species(id)
	if sp == null:
		_check("%s : la fiche se charge" % id, false)
		return
	var fam: Array = FAMILY[id]
	_check("%s : famille %s (type %s), cri « %s », description" % [id, fam[0], fam[1], fam[2]],
		sp.family == fam[0] and load("res://data/moves_db.gd").FAMILY_TYPES[sp.family] == fam[1] and sp.cry_prefix == fam[2]
		and sp.description.length() > 60)
	var sheet: Texture2D = sp.sheet
	var own: bool = sheet != null and sheet.resource_path.get_file().begins_with(String(id))
	print("   planche : %s" % (sheet.resource_path if own else "REPLI %s (en attente de l'agent images)" % (sheet.resource_path if sheet else "?")))
	_check("%s : planche de profil 3 × 2 (cases égales)" % id, sheet != null and sheet.get_width() % 3 == 0 and sheet.get_height() % 2 == 0,
		"%s" % (sheet.get_size() if sheet else "absente"))
	var fb: Texture2D = sp.face_back_sheet
	var same_cell: bool = fb != null and sheet != null and fb.get_width() / 4 == sheet.get_width() / 3 and fb.get_height() == sheet.get_height()
	_check("%s : planche face/dos 4 × 2, mêmes cases que le profil" % id, same_cell, "%s" % (fb.get_size() if fb else "absente"))
	var g: float = _gabarit(sp, sp.world_scale)
	var want: float = GABARIT[id]
	var scale: float = sp.world_scale * want / maxf(g, 0.01)
	var battle: float = scale * BATTLE_K / sqrt(want)
	_check("%s : taille vue (gabarit %.2f m, visé %.2f m)" % [id, g, want], absf(g - want) < want * 0.06,
		"poser world_scale = %.3f, battle_scale = %.3f" % [scale, battle])
	_check("%s : combat, écarts adoucis (battle_scale %.3f, visé %.3f)" % [id, sp.battle_scale, battle], absf(sp.battle_scale - battle) < battle * 0.08)


## √(hauteur × longueur) vu de son image debout, à l'échelle `scale` (m).
func _gabarit(sp, scale: float) -> float:
	var r: Rect2 = _size.drawn(sp)
	return sqrt(r.size.y * STRETCH * r.size.x) * scale / PX


# ------------------------------------------------------------------ (b) le Dinodex

func _dex() -> void:
	print("— (b) le Dinodex")
	var facts = load("res://data/dex_facts.gd")
	for id in IDS:
		var f: Dictionary = facts.INFO.get(id, {})
		_check("%s : fiche du Dinodex (taille, régime, époque, lieu, signe, anecdote)" % id,
			["size", "diet", "era", "from", "trait", "fact"].all(func(k: String) -> bool: return String(f.get(k, "")) != ""))
	var unique: Array = facts.UNIQUES.filter(func(u: Dictionary) -> bool: return u["id"] == &"trex_magma")
	_check("le T-Rex de Magma est parmi les Uniques (Alpha du Volcan)", unique.size() == 1 and unique[0]["region"] == &"volcan")
	var order: Array = load("res://data/dex_db.gd").order()
	_check("les 3 espèces sauvages sont dans la liste du Dinodex, pas le T-Rex de Magma",
		IDS.slice(0, 3).all(func(id: StringName) -> bool: return id in order) and not &"trex_magma" in order)


# ------------------------------------------------------------------ (c) capacités, attaques

func _abilities_and_moves() -> void:
	print("— (c) capacités et attaques")
	var dino = load("res://game/dino.gd")
	var abilities = load("res://data/abilities.gd")
	var moves = load("res://data/moves_db.gd")
	var want := {&"styracosaurus": [&"charge", &"monture"], &"saichania": [&"charge", &"cuir_de_feu"],
		&"daspletosaurus": [&"cuir_de_feu"], &"trex_magma": [&"cuir_de_feu"]}
	for id in IDS:
		var d = dino.create(id, 46)
		_check("%s : capacités %s" % [id, want[id]], abilities.of(d) == want[id], str(abilities.of(d)))
	var names := func(d) -> String: return ", ".join(d.moves.map(func(m: Dictionary) -> String: return moves.move(m["id"])["name"]))
	var s44 = dino.create(&"styracosaurus", 44)
	var s45 = dino.create(&"styracosaurus", 45)
	_check("Styracosaurus sauvage (42-44) : pas encore Séisme", not s44.moves.any(func(m: Dictionary) -> bool: return m["id"] == &"seisme"), names.call(s44))
	_check("Styracosaurus niv. 45 : Séisme (la Terre touche fort le T-Rex)", s45.moves.any(func(m: Dictionary) -> bool: return m["id"] == &"seisme"), names.call(s45))
	var allo = dino.create(&"allosaurus", 45)
	var das = dino.create(&"daspletosaurus", 46)
	var trex = dino.create(&"trex_magma", 48)
	_check("un Allosaurus niv. 45 (Mastoc, 44) n'a pas Coulée de lave", not allo.moves.any(func(m: Dictionary) -> bool: return m["id"] == &"couleeLave"), names.call(allo))
	_check("Daspletosaurus niv. 46 et T-Rex 48 : Coulée de lave", das.moves.any(func(m: Dictionary) -> bool: return m["id"] == &"couleeLave")
		and trex.moves.any(func(m: Dictionary) -> bool: return m["id"] == &"couleeLave"), names.call(trex))
	var protos = dino.create(&"protoceratops", 30)
	_check("rien ne change avant le volcan (Protoceratops niv. 30)", not protos.moves.any(func(m: Dictionary) -> bool: return m["id"] == &"seisme"))


# ------------------------------------------------------------------ (d) les objets

func _items() -> void:
	print("— (d) les objets")
	var items = load("res://data/items_db.gd")
	for id: String in ITEMS:
		var it: Dictionary = items.item(id)
		_check("%s « %s » : objet clé, jamais vendu, décrit" % [id, it["name"]], items.ITEMS.has(id) and it["kind"] == "cle" and it["sell"] == 0 and it["desc"] != "")
		var icon := "res://assets/art/ui/%s.png" % it["icon"]
		print("   %s.png : %s" % [it["icon"], "présente" if ResourceLoader.exists(icon) else "ABSENTE (l'ambre la remplace ; agent images)"])


# ------------------------------------------------------------------ (e) les ambiances

func _ambiences() -> void:
	print("— (e) les ambiances")
	var ambience = load("res://data/ambience_db.gd")
	for zone: StringName in ZONES:
		var def: Dictionary = ambience.get_ambience(zone)
		var sounds_ok: bool = (def.get("beds", []) as Array).all(func(b: Array) -> bool: return ResourceLoader.exists(ambience.PATH % b[0]))
		_check("ambiance %s : des sons qui existent" % zone, ambience.has(zone) and not def["beds"].is_empty() and sounds_ok)


# ------------------------------------------------------------------ (f) les zones (agent carte)

func _zones() -> void:
	print("— (f) les zones du Volcan")
	var seen := {}
	for zone: StringName in ZONES:
		if not ResourceLoader.exists(ZONES[zone]):
			print("   %s : zone pas encore construite (agent carte)" % zone)
			continue
		var region = load("res://world/region.gd").open_for_preview(ZONES[zone])
		_check("%s : son ambiance (%s)" % [zone, region.ambience_id], region.ambience_id == zone)
		if zone == &"coulees_lave":
			_check("coulees_lave : la lave est posée (méta « lave » ou « lave_cases »)", region.has_meta(&"lave") or region.has_meta(&"lave_cases"))
			_check("coulees_lave : le vol y est interdit (sinon on survole la lave)", region.get_meta(&"vol_interdit", false))
		for h in region.find_children("*", "Habitat", true, false):
			for e in h.encounters:
				seen[e.species] = seen.get(e.species, []) + ["%s %d-%d" % [zone, e.levels.x, e.levels.y]]
				if e.levels.x < LEVELS.x or e.levels.y > LEVELS.y:
					_check("%s : %s aux niveaux du Volcan" % [zone, e.species], false, str(e.levels))
		region.free()
	if seen.is_empty():
		print("   (aucun habitat encore)")
		return
	for id in IDS.slice(0, 3):
		var home: StringName = HOME[id]
		if not ResourceLoader.exists(ZONES[home]):
			print("   %s : sa zone (%s) n'est pas encore construite" % [id, home])
			continue
		_check("%s vit au Volcan" % id, seen.has(id), str(seen.get(id, "")))
	_check("le T-Rex de Magma n'est jamais sauvage", not seen.has(&"trex_magma"))


# ------------------------------------------------------------------ la planche de contact

func _contact_sheet() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var layer := CanvasLayer.new()
	var bg := ColorRect.new()
	bg.color = Color(0.9, 0.86, 0.82)
	bg.size = Vector2(1600, 900)
	layer.add_child(bg)
	root.add_child(layer)
	for i in IDS.size():
		var sp = _db.get_species(IDS[i])
		var y := 80.0 + i * 200.0
		_label(layer, sp.display_name, Vector2(20, y + 70))
		_frame(layer, sp.sheet, 3, 2, 3, Vector2(260, y), 170.0)
		if sp.face_back_sheet:
			_frame(layer, sp.face_back_sheet, 4, 2, 1, Vector2(500, y), 170.0)
			_frame(layer, sp.face_back_sheet, 4, 2, 5, Vector2(720, y), 170.0)
		var corrupted := "res://assets/art/dinos/%s_corrompu.png" % IDS[i]
		if ResourceLoader.exists(corrupted):
			_frame(layer, load(corrupted), 3, 2, 3, Vector2(960, y), 170.0)
		var own: bool = sp.sheet.resource_path.get_file().begins_with(String(IDS[i]))
		_label(layer, "" if own else "(repli : %s)" % sp.sheet.resource_path.get_file(), Vector2(1220, y + 70))
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/especes_volcan.png" % _out)
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
	l.add_theme_color_override(&"font_color", Color(0.15, 0.1, 0.08))
	layer.add_child(l)


# ------------------------------------------------------------------ outils

func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])
