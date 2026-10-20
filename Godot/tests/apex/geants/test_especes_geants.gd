extends GdUnitTestSuite
## Les quatre géants du cratère (docs/post-game-plan.md § 1), sans fenêtre : leurs fiches `.tres` (lues comme du
## texte tant que les planches du lot A' ne sont pas là : famille, type, cri, rareté, planches attendues), puis
## chargées (planches 3 × 2 et 4 × 2, gabarit vu, l'Argentinosaurus le plus grand : 5,2 m de haut) ; leurs Uniques et leurs fiches du Dinodex
## (role, rumour, where ; taille, régime, époque, lieu, trait, anecdote) ; leurs remplaçants (STAND_INS) ; les
## fichiers attendus du lot A'. Les tests qui demandent les planches ou le correctif de SpeciesDB sont SAUTÉS
## (avec la raison) tant qu'ils manquent.

const AG := preload("res://story/apex_geants.gd")
const TRES := "res://data/species/%s.tres"
const FAMILIES := {&"deinocheirus": "raptor", &"argentinosaurus": "sauropod", &"therizinosaurus_geant": "raptor", &"dacentrurus": "armored"}
const CRIES := {&"deinocheirus": "raptor", &"argentinosaurus": "sauropode", &"therizinosaurus_geant": "sauropode", &"dacentrurus": "sauropode"}
const DIETS := {&"deinocheirus": "omnivore", &"argentinosaurus": "herbivore", &"therizinosaurus_geant": "herbivore", &"dacentrurus": "herbivore"}
## Gabarit vu visé (m) : √(hauteur × longueur) compressé (direction-artistique.md ; post-game-plan.md § 1) ; réglé
## sur les planches du lot A' pour que l'Argentinosaurus, le plus grand du jeu, ait 5,2 m de HAUT (chef d'équipe, 20/10)
## et reste le plus haut et le plus long des quatre (le Therizinosaurus géant à 4,4 m de gabarit le dépassait : 4,0).
const GABARITS := {&"deinocheirus": 4.4, &"argentinosaurus": 5.68, &"therizinosaurus_geant": 4.0, &"dacentrurus": 3.2}
const HEIGHT_MAX := 5.2
const BATTLE_K := 1.99
const STRETCH := 1.15
const PX := 48.0


static func _ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for n: int in AG.ORDER:
		out.append(AG.SPECIES[n])
	return out


## Les huit planches du lot A' sont là (importées).
static func _sheets_ready() -> bool:
	for id: StringName in _ids():
		for suffix in ["", "_face_dos"]:
			if not ResourceLoader.exists("res://assets/art/dinos/%s%s.png" % [id, suffix]):
				return false
	return true


## Le correctif de SpeciesDB (patch_A.md) est appliqué.
static func _registered() -> bool:
	return _ids().all(func(id: StringName) -> bool: return SpeciesDB.PATHS.has(id))


static func _field(text: String, key: String) -> String:
	var m := RegEx.create_from_string("(?m)^%s = (.+)$" % key).search(text)
	return m.get_string(1).strip_edges() if m else ""


# ------------------------------------------------------------------ les fiches, lues comme du texte

func test_les_quatre_fiches_bien_formees() -> void:
	assert_int(_ids().size()).is_equal(4)
	for id: StringName in _ids():
		var path := TRES % id
		assert_bool(FileAccess.file_exists(path)).override_failure_message("%s absente" % path).is_true()
		var text := FileAccess.get_file_as_string(path)
		assert_str(_field(text, "id")).is_equal("&\"%s\"" % id)
		assert_str(_field(text, "family")).override_failure_message("%s : famille" % id).is_equal("&\"%s\"" % FAMILIES[id])
		assert_bool(MovesDB.FAMILY_TYPES.has(StringName(FAMILIES[id]))).is_true()
		assert_str(_field(text, "rarity")).is_equal("\"legendary\"")
		assert_str(_field(text, "cry_prefix")).is_equal("\"%s\"" % CRIES[id])
		assert_bool(ResourceLoader.exists("res://assets/audio/cries/%s-neutre.mp3" % CRIES[id])).is_true()
		assert_str(text).override_failure_message("%s : planche de profil attendue" % id).contains("res://assets/art/dinos/%s.png" % id)
		assert_str(text).override_failure_message("%s : planche face/dos attendue" % id).contains("res://assets/art/dinos/%s_face_dos.png" % id)
		assert_int(_field(text, "description").length()).override_failure_message("%s : description" % id).is_greater(80)
		assert_float(float(_field(text, "world_scale"))).is_greater(0.3)
		assert_float(float(_field(text, "battle_scale"))).is_greater(0.3)


# ------------------------------------------------------------------ les fiches chargées (planches du lot A')

func test_planches_et_gabarit_vu(_do_skip := not _sheets_ready(), _skip_reason := "planches du lot A' pas encore livrées (assets/art/dinos/<espèce>*.png)") -> void:
	var seen := {}   # id -> Vector2(longueur, hauteur) vues (m)
	for id: StringName in _ids():
		var sp := load(TRES % id) as DinoSpecies
		assert_object(sp).override_failure_message("%s ne se charge pas" % id).is_not_null()
		if sp == null:
			continue
		assert_bool(sp.sheet.get_width() % 3 == 0 and sp.sheet.get_height() % 2 == 0) \
			.override_failure_message("%s : profil pas en 3 × 2 (%s)" % [id, sp.sheet.get_size()]).is_true()
		var fb: Texture2D = sp.face_back_sheet
		assert_bool(fb != null and floori(fb.get_width() / 4.0) == floori(sp.sheet.get_width() / 3.0) and fb.get_height() == sp.sheet.get_height()) \
			.override_failure_message("%s : face/dos pas en 4 × 2 aux cases du profil" % id).is_true()
		var r: Rect2 = DinoSize.drawn(sp)
		var g := sqrt(r.size.y * STRETCH * r.size.x) * sp.world_scale / PX
		seen[id] = Vector2(r.size.x, r.size.y * STRETCH) * sp.world_scale / PX
		prints("   %s : gabarit vu %.2f m, hauteur vue %.2f m, longueur vue %.2f m" % [id, g, seen[id].y, seen[id].x])
		var target: float = GABARITS[id]
		var scale := sp.world_scale * target / maxf(g, 0.01)
		var battle := scale * BATTLE_K / sqrt(target)
		assert_float(absf(g - target)).override_failure_message("%s : gabarit vu %.2f m, visé %.2f m (poser world_scale = %.3f, battle_scale = %.3f)" % [
			id, g, target, scale, battle]).is_less(target * 0.06)
		assert_float(seen[id].y).override_failure_message("%s : %.2f m de haut" % [id, seen[id].y]).is_less_equal(HEIGHT_MAX * 1.03)
		assert_float(absf(sp.battle_scale - battle)).override_failure_message("%s : battle_scale %.3f, visé %.3f" % [id, sp.battle_scale, battle]).is_less(battle * 0.08)
	var arg: Vector2 = seen.get(&"argentinosaurus", Vector2.ZERO)
	assert_float(arg.y).override_failure_message("l'Argentinosaurus : %.2f m de haut, visé 5,2" % arg.y).is_between(HEIGHT_MAX * 0.97, HEIGHT_MAX * 1.03)
	for id: StringName in seen:
		if id != &"argentinosaurus":
			assert_bool(seen[id].x < arg.x and seen[id].y < arg.y).override_failure_message("%s plus grand que l'Argentinosaurus" % id).is_true()


func test_species_db_les_connait(_do_skip := not _registered(), _skip_reason := "correctif SpeciesDB de patch_A.md pas encore appliqué (à appliquer avec les planches)") -> void:
	for id: StringName in _ids():
		var sp := SpeciesDB.get_species(id)
		assert_object(sp).is_not_null()
		assert_str(String(sp.family)).is_equal(FAMILIES[id])
		assert_bool(DexDB.is_unique(id)).override_failure_message("%s : pas un Unique" % id).is_true()
		assert_bool(DexDB.uniques().has(id)).is_true()
		assert_str(String(AG.species_or(id))).override_failure_message("%s : encore remplacé" % id).is_equal(String(id) if _sheets_ready() else String(AG.STAND_INS[id]))


# ------------------------------------------------------------------ le Dinodex

func test_uniques_et_fiches_du_dinodex() -> void:
	for id: StringName in _ids():
		var u := DexDB.unique_info(id)
		assert_bool(u.is_empty()).override_failure_message("%s n'est pas parmi les Uniques" % id).is_false()
		if u.is_empty():
			continue
		assert_str(String(u["region"])).is_equal("apex")
		for key in ["role", "rumour", "where"]:
			assert_int(String(u.get(key, "")).length()).override_failure_message("%s : %s vide" % [id, key]).is_greater(10)
		var info: Dictionary = DexFacts.INFO.get(id, {})
		for key in ["size", "diet", "era", "from", "trait", "fact"]:
			assert_bool(String(info.get(key, "")) != "").override_failure_message("%s : %s manque" % [id, key]).is_true()
		assert_str(String(info.get("diet", ""))).is_equal(DIETS[id])
		assert_bool(DexFacts.DIETS.has(info.get("diet", ""))).is_true()
	# Les géants viennent après le Souverain, dans l'ordre de leur réveil.
	var order: Array = DexFacts.UNIQUES.map(func(u: Dictionary) -> StringName: return u["id"])
	var at := order.find(&"souverain")
	assert_array(order.slice(at + 1, at + 5)).contains_exactly(_ids())


# ------------------------------------------------------------------ en attendant les planches

func test_remplacants_existants() -> void:
	for id: StringName in _ids():
		var stand_in: StringName = AG.STAND_INS.get(id, &"")
		assert_bool(SpeciesDB.PATHS.has(stand_in)).override_failure_message("%s : remplaçant %s inconnu" % [id, stand_in]).is_true()
		assert_bool(SpeciesDB.PATHS.has(AG.species_or(id))).override_failure_message("%s : rien à montrer" % id).is_true()


func test_fichiers_attendus_du_lot_a_prime() -> void:
	var expected: Array = AG.expected_art()
	for id: StringName in _ids():
		assert_array(expected).contains(["res://assets/art/dinos/%s.png" % id, "res://assets/art/dinos/%s_face_dos.png" % id])
	for n in [1, 2, 3, 4]:
		assert_array(expected).contains(["res://assets/art/props/bloc_geant_%d_oeil.png" % n, "res://assets/art/props/bloc_geant_%d_vide.png" % n])
	var missing: Array = expected.filter(func(p: String) -> bool: return not ResourceLoader.exists(p))
	if not missing.is_empty():
		prints("   lot A' : %d fichier(s) attendu(s) pas encore là : %s" % [missing.size(), ", ".join(missing.map(func(p: String) -> String: return p.get_file()))])
