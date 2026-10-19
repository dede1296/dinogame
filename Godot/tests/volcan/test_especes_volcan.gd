extends GdUnitTestSuite
## Les espèces de la Plaine Volcanique (chapitre 8), sans fenêtre : la logique de
## tools/test_especes_volcan.gd (fiches, planches, tailles, Dinodex, capacités, attaques, objets,
## ambiances, zones), sans la planche de contact ni le bandeau. Les zones sont ouvertes
## (Region.open_for_preview) sans être affichées. Une boucle par vérification (chaque cas de test
## coûte ~90 ms à GdUnit4) ; le message d'échec nomme l'espèce ou la zone.

const IDS: Array[StringName] = [&"styracosaurus", &"saichania", &"daspletosaurus", &"trex_magma"]
## espèce -> [famille, type, préfixe du cri]
const FAMILY := {
	&"styracosaurus": [&"ceratopsian", "terre", "ceratopsien"],
	&"saichania": [&"armored", "pierre", "cuirasse"],
	&"daspletosaurus": [&"tyrant", "feu", "tyran"],
	&"trex_magma": [&"tyrant", "feu", "tyran"],
}
## Gabarit vu (m) visé : √(hauteur × longueur), compressé au-delà de 1,5 m (direction-artistique.md).
const GABARIT := {&"styracosaurus": 2.34, &"saichania": 2.0, &"daspletosaurus": 3.3, &"trex_magma": 3.8}
## Combat : battle = world × BATTLE_K / √gabarit (mesuré sur les autres espèces).
const BATTLE_K := 1.99
const STRETCH := 1.15
const PX := 48.0
const ABILITIES := {
	&"styracosaurus": [&"charge", &"monture"],
	&"saichania": [&"charge", &"cuir_de_feu"],
	&"daspletosaurus": [&"cuir_de_feu"],
	&"trex_magma": [&"cuir_de_feu"],
}
const ITEMS := ["antidote_ambre", "sceau_volcan", "coeur_5", "lettre_isaure"]
const ZONES := {
	&"champs_cendres": "res://regions/volcan/champs_cendres.tscn",
	&"forges_ombre": "res://regions/volcan/forges_ombre.tscn",
	&"coulees_lave": "res://regions/volcan/coulees_lave.tscn",
	&"sanctuaire_magma": "res://regions/volcan/sanctuaire_magma.tscn",
	&"porte_cratere": "res://regions/volcan/porte_cratere.tscn",
}
const LEVELS := Vector2i(42, 48)
## Où chaque espèce sauvage vit d'abord (bestiaire).
const HOME := {&"styracosaurus": &"champs_cendres", &"saichania": &"champs_cendres", &"daspletosaurus": &"coulees_lave"}


# ------------------------------------------------------------------ (a) les fiches

func test_fiches_famille_type_cri_description() -> void:
	for id in IDS:
		assert_bool(SpeciesDB.PATHS.has(id)).override_failure_message("%s absent de SpeciesDB.PATHS" % id).is_true()
		var sp := SpeciesDB.get_species(id)
		assert_object(sp).override_failure_message("la fiche de %s ne se charge pas" % id).is_not_null()
		if sp == null:
			continue
		var want: Array = FAMILY[id]
		assert_str(String(sp.family)).override_failure_message("%s : famille %s, attendu %s" % [id, sp.family, want[0]]).is_equal(String(want[0]))
		assert_str(String(MovesDB.FAMILY_TYPES.get(sp.family, ""))).override_failure_message("%s : type de la famille %s" % [id, sp.family]).is_equal(want[1])
		assert_str(sp.cry_prefix).override_failure_message("%s : cri « %s », attendu « %s »" % [id, sp.cry_prefix, want[2]]).is_equal(want[2])
		assert_int(sp.description.length()).override_failure_message("%s : description trop courte (%d)" % [id, sp.description.length()]).is_greater(60)


func test_planches_profil_3x2_face_dos_4x2() -> void:
	for id in IDS:
		var sp := SpeciesDB.get_species(id)
		var sheet: Texture2D = sp.sheet
		assert_object(sheet).override_failure_message("%s : pas de planche de profil" % id).is_not_null()
		if sheet == null:
			continue
		if not sheet.resource_path.get_file().begins_with(String(id)):
			prints("   %s : planche de REPLI %s (en attente de l'agent images)" % [id, sheet.resource_path])
		assert_bool(sheet.get_width() % 3 == 0 and sheet.get_height() % 2 == 0) \
			.override_failure_message("%s : planche de profil pas en 3 × 2 cases égales (%s)" % [id, sheet.get_size()]).is_true()
		var fb: Texture2D = sp.face_back_sheet
		assert_object(fb).override_failure_message("%s : pas de planche face/dos" % id).is_not_null()
		if fb == null:
			continue
		var same_cell := floori(fb.get_width() / 4.0) == floori(sheet.get_width() / 3.0) and fb.get_height() == sheet.get_height()
		assert_bool(same_cell).override_failure_message("%s : planche face/dos %s, pas en 4 × 2 aux cases du profil %s" % [id, fb.get_size(), sheet.get_size()]).is_true()


func test_tailles_vues_et_combat() -> void:
	for id in IDS:
		var sp := SpeciesDB.get_species(id)
		var r: Rect2 = DinoSize.drawn(sp)
		var g := sqrt(r.size.y * STRETCH * r.size.x) * sp.world_scale / PX
		var want: float = GABARIT[id]
		var scale := sp.world_scale * want / maxf(g, 0.01)
		var battle := scale * BATTLE_K / sqrt(want)
		assert_float(absf(g - want)).override_failure_message(
			"%s : gabarit vu %.2f m, visé %.2f m (poser world_scale = %.3f, battle_scale = %.3f)" % [id, g, want, scale, battle]) \
			.is_less(want * 0.06)
		assert_float(absf(sp.battle_scale - battle)).override_failure_message(
			"%s : battle_scale %.3f, visé %.3f" % [id, sp.battle_scale, battle]).is_less(battle * 0.08)


# ------------------------------------------------------------------ (b) le Dinodex

func test_dinodex_fiches_completes() -> void:
	for id in IDS:
		var f: Dictionary = DexFacts.INFO.get(id, {})
		var missing := ["size", "diet", "era", "from", "trait", "fact"].filter(func(k: String) -> bool: return String(f.get(k, "")) == "")
		assert_array(missing).override_failure_message("%s : fiche du Dinodex incomplète, manque %s" % [id, missing]).is_empty()


func test_dinodex_trex_unique_du_volcan_hors_liste() -> void:
	var unique: Array = DexFacts.UNIQUES.filter(func(u: Dictionary) -> bool: return u["id"] == &"trex_magma")
	assert_int(unique.size()).override_failure_message("le T-Rex de Magma n'est pas (une seule fois) parmi les Uniques").is_equal(1)
	if unique.size() == 1:
		assert_str(String(unique[0]["region"])).override_failure_message("le T-Rex de Magma n'est pas l'Alpha du Volcan").is_equal("volcan")
	var order: Array = DexDB.order()
	for id in IDS.slice(0, 3):
		assert_bool(id in order).override_failure_message("%s absent de la liste du Dinodex" % id).is_true()
	assert_bool(&"trex_magma" in order).override_failure_message("le T-Rex de Magma est dans la liste du Dinodex (c'est un Unique)").is_false()


# ------------------------------------------------------------------ (c) capacités, attaques

func test_capacites_charge_monture_cuir_de_feu() -> void:
	for id in IDS:
		var d := Dino.create(id, 46)
		assert_array(Abilities.of(d)).override_failure_message("%s : capacités %s, attendu %s" % [id, Abilities.of(d), ABILITIES[id]]) \
			.contains_exactly(ABILITIES[id])


func test_seisme_a_45_pas_avant() -> void:
	var s44 := Dino.create(&"styracosaurus", 44)
	var s45 := Dino.create(&"styracosaurus", 45)
	var protos := Dino.create(&"protoceratops", 30)
	assert_bool(_knows(s44, &"seisme")).override_failure_message("Styracosaurus niv. 44 (sauvage) a déjà Séisme : %s" % _names(s44)).is_false()
	assert_bool(_knows(s45, &"seisme")).override_failure_message("Styracosaurus niv. 45 n'a pas Séisme : %s" % _names(s45)).is_true()
	assert_bool(_knows(protos, &"seisme")).override_failure_message("rien ne change avant le volcan : un Protoceratops niv. 30 a Séisme (%s)" % _names(protos)).is_false()


func test_coulee_de_lave_a_46() -> void:
	var allo := Dino.create(&"allosaurus", 45)
	var das := Dino.create(&"daspletosaurus", 46)
	var trex := Dino.create(&"trex_magma", 48)
	assert_bool(_knows(allo, &"couleeLave")).override_failure_message("un Allosaurus niv. 45 (Mastoc, 44) a Coulée de lave : %s" % _names(allo)).is_false()
	assert_bool(_knows(das, &"couleeLave")).override_failure_message("Daspletosaurus niv. 46 sans Coulée de lave : %s" % _names(das)).is_true()
	assert_bool(_knows(trex, &"couleeLave")).override_failure_message("T-Rex de Magma niv. 48 sans Coulée de lave : %s" % _names(trex)).is_true()


# ------------------------------------------------------------------ (d) les objets

func test_objets_du_chapitre_cles_non_vendables() -> void:
	for id: String in ITEMS:
		assert_bool(ItemsDB.ITEMS.has(id)).override_failure_message("%s absent d'ItemsDB" % id).is_true()
		var it := ItemsDB.item(id)
		assert_str(String(it.get("kind", ""))).override_failure_message("%s : pas un objet clé (%s)" % [id, it.get("kind")]).is_equal("cle")
		assert_int(int(it.get("sell", -1))).override_failure_message("%s : se vend (%s)" % [id, it.get("sell")]).is_equal(0)
		assert_str(String(it.get("desc", ""))).override_failure_message("%s : sans description" % id).is_not_empty()


# ------------------------------------------------------------------ (e) les ambiances

func test_ambiances_des_cinq_zones() -> void:
	for zone: StringName in ZONES:
		assert_bool(AmbienceDB.has(zone)).override_failure_message("pas d'ambiance %s" % zone).is_true()
		var beds: Array = AmbienceDB.get_ambience(zone).get("beds", [])
		assert_array(beds).override_failure_message("ambiance %s : aucun son de fond" % zone).is_not_empty()
		var missing := beds.filter(func(b: Array) -> bool: return not ResourceLoader.exists(AmbienceDB.PATH % b[0]))
		assert_array(missing).override_failure_message("ambiance %s : sons introuvables %s" % [zone, missing]).is_empty()


# ------------------------------------------------------------------ (f) les zones (ouvertes, pas affichées)

func test_zones_ambiance_et_rencontres_42_48() -> void:
	for zone: StringName in ZONES:
		var path: String = ZONES[zone]
		assert_bool(ResourceLoader.exists(path)).override_failure_message("%s : zone pas construite (%s)" % [zone, path]).is_true()
		if not ResourceLoader.exists(path):
			continue
		var region := Region.open_for_preview(path)
		assert_str(String(region.ambience_id)).override_failure_message("%s : ambiance %s" % [zone, region.ambience_id]).is_equal(String(zone))
		var outside: Array[String] = []
		for e in _encounters(region):
			if e.levels.x < LEVELS.x or e.levels.y > LEVELS.y:
				outside.append("%s %s" % [e.species, e.levels])
		assert_array(outside).override_failure_message("%s : rencontres hors des niveaux 42-48 : %s" % [zone, outside]).is_empty()
		region.free()


func test_coulees_lave_posee_et_vol_interdit() -> void:
	var region := Region.open_for_preview(ZONES[&"coulees_lave"])
	assert_bool(region.has_meta(Lava.META) or region.has_meta(Lava.META_CELLS)) \
		.override_failure_message("coulees_lave : pas de lave posée (méta « lave » ou « lave_cases »)").is_true()
	assert_bool(bool(region.get_meta(Vol.NO_FLIGHT_META, false))).override_failure_message("coulees_lave : le vol n'y est pas interdit").is_true()
	region.free()


func test_especes_sauvages_au_volcan_trex_jamais() -> void:
	var seen := {}
	for zone: StringName in ZONES:
		if not ResourceLoader.exists(ZONES[zone]):
			continue
		var region := Region.open_for_preview(ZONES[zone])
		for e in _encounters(region):
			seen[e.species] = seen.get(e.species, []) + ["%s %d-%d" % [zone, e.levels.x, e.levels.y]]
		region.free()
	for id in IDS.slice(0, 3):
		assert_bool(seen.has(id)).override_failure_message("%s ne vit nulle part au Volcan (attendu d'abord : %s)" % [id, HOME[id]]).is_true()
	assert_bool(seen.has(&"trex_magma")).override_failure_message("le T-Rex de Magma est sauvage : %s" % seen.get(&"trex_magma", "")).is_false()


# ------------------------------------------------------------------ outils

func _encounters(region: Node) -> Array:
	var out := []
	for h in region.find_children("*", "Habitat", true, false):
		out.append_array(h.encounters)
	return out


func _knows(d: Dino, move_id: StringName) -> bool:
	return d.moves.any(func(m: Dictionary) -> bool: return m["id"] == move_id)


func _names(d: Dino) -> String:
	return ", ".join(d.moves.map(func(m: Dictionary) -> String: return MovesDB.move(m["id"])["name"]))
