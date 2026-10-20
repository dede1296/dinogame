extends GdUnitTestSuite
## Les trois espèces légendaires (docs/post-game-plan.md § 2), sans fenêtre : chaque fiche se charge
## (nom, famille, type, cri, rareté légendaire, planches 3 × 2 et face/dos 4 × 2 aux mêmes cases),
## sa taille suit la règle du gabarit (Titanosaure d'Or 3,6 m, Kronosaurus 3,5 m, Gigantoraptor 3,1 m) ;
## le Kronosaurus nage (Nage, famille marine) et ne porte ni ne marche (pas de Monture) ; le
## Gigantoraptor a le Flair de sa famille ; SpeciesDB, le Dinodex (fiche, liste) les connaissent
## (patch_B.md) ; la planche du squelette et les icônes sont là.

const F := preload("res://story/fossiles.gd")
const GABARIT := {&"saltasaurus": 3.6, &"kronosaurus": 3.5, &"gigantoraptor": 3.1}
const FAMILY := {&"saltasaurus": [&"sauropod", "terre"], &"kronosaurus": [&"marine", "eau"], &"gigantoraptor": [&"raptor", "vent"]}
const NAMES := {&"saltasaurus": "Titanosaure d'Or", &"kronosaurus": "Kronosaurus", &"gigantoraptor": "Gigantoraptor"}
const STRETCH := 1.15
const PX := 48.0
const BATTLE_K := 1.99


static func _sp(id: StringName) -> DinoSpecies:
	return load("res://data/species/%s.tres" % id) as DinoSpecies


func before() -> void:
	for id: StringName in GABARIT:
		if not SpeciesDB.PATHS.has(id):
			SpeciesDB._cache[id] = _sp(id)


func test_les_fiches_se_chargent() -> void:
	for id: StringName in GABARIT:
		var sp := _sp(id)
		assert_object(sp).override_failure_message("%s.tres ne se charge pas" % id).is_not_null()
		if sp == null:
			continue
		assert_str(String(sp.id)).is_equal(String(id))
		assert_str(sp.display_name).is_equal(NAMES[id])
		assert_str(String(sp.family)).is_equal(String(FAMILY[id][0]))
		assert_str(String(MovesDB.FAMILY_TYPES[sp.family])).is_equal(FAMILY[id][1])
		assert_str(sp.rarity).is_equal("legendary")
		assert_object(sp.cry("neutre")).override_failure_message("%s : pas de cri" % id).is_not_null()
		assert_str(sp.description).is_not_empty()


func test_les_planches_et_la_taille() -> void:
	for id: StringName in GABARIT:
		var sp := _sp(id)
		var sheet := sp.sheet
		var fb := sp.face_back_sheet
		assert_object(sheet).is_not_null()
		assert_object(fb).is_not_null()
		assert_int(fb.get_width() * 3).override_failure_message("%s : cases face/dos" % id).is_equal(sheet.get_width() * 4)
		assert_int(fb.get_height()).is_equal(sheet.get_height())
		var r := DinoSize.drawn(sp)
		var g := sqrt(r.size.y * STRETCH * r.size.x) * sp.world_scale / PX
		var want: float = GABARIT[id]
		var scale := sp.world_scale * want / maxf(g, 0.01)
		assert_float(g).override_failure_message("%s : gabarit %.2f m, visé %.2f m (poser world_scale = %.3f)" % [id, g, want, scale]).is_equal_approx(want, want * 0.06)
		var battle := scale * BATTLE_K / sqrt(want)
		assert_float(sp.battle_scale).override_failure_message("%s : battle_scale %.3f, visé %.3f" % [id, sp.battle_scale, battle]).is_equal_approx(battle, battle * 0.08)


func test_le_kronosaurus_nage_et_ne_marche_pas() -> void:
	var k := Dino.create(&"kronosaurus", 45)
	assert_bool(Abilities.has(k, &"nage")).is_true()
	assert_bool(Abilities.has(k, &"monture")).is_false()
	var s := Dino.create(&"saltasaurus", 45)
	assert_bool(Abilities.has(s, &"monture")).override_failure_message("un sauropode géant : hors de portée").is_false()


func test_le_gigantoraptor_a_le_flair() -> void:
	var g := Dino.create(&"gigantoraptor", 45)
	assert_bool(Abilities.has(g, &"flair")).override_failure_message("patch_B.md : Flair au Gigantoraptor (abilities.gd)").is_true()
	assert_bool(Abilities.has(g, &"tranche")).is_true()


func test_species_db_et_le_dinodex_les_connaissent() -> void:
	for id: StringName in GABARIT:
		assert_bool(SpeciesDB.PATHS.has(id)).override_failure_message("patch_B.md : %s dans SpeciesDB.PATHS" % id).is_true()
		var f: Dictionary = DexFacts.INFO.get(id, {})
		assert_bool(["size", "diet", "era", "from", "trait", "fact"].all(func(k: String) -> bool: return String(f.get(k, "")) != "")) \
			.override_failure_message("patch_B.md : fiche du Dinodex de %s" % id).is_true()
		assert_bool(DexDB.is_unique(id)).override_failure_message("%s n'est pas un Unique" % id).is_false()
	var order := DexDB.order()
	assert_bool(GABARIT.keys().all(func(id: StringName) -> bool: return id in order)).override_failure_message("dans la liste du Dinodex").is_true()


func test_images_du_squelette_et_icones() -> void:
	for id: StringName in GABARIT:
		assert_bool(ResourceLoader.exists("res://assets/art/ui/squelette_%s.png" % id)).override_failure_message("squelette_%s.png" % id).is_true()
	for b in F.BEASTS:
		assert_bool(ResourceLoader.exists("res://assets/art/ui/os_%s.png" % b)).override_failure_message("os_%s.png" % b).is_true()
	assert_bool(ResourceLoader.exists("res://assets/art/ui/carnet_os.png")).is_true()
	for k: StringName in F.SKULLS:
		assert_bool(ResourceLoader.exists("res://assets/art/props/%s.png" % F.SKULLS[k][1])).is_true()
