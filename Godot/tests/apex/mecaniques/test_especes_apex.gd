extends GdUnitTestSuite
## Les espèces, les objets et les ambiances du chapitre 9 (la Terre des Apex), sans fenêtre : la fiche du Souverain
## (famille, type, cri, planches, tailles, ses quatre coups, jamais sauvage, Unique du Dinodex), l'équipe d'Isaure
## (espèces existantes, niveaux 47-49, pas un corrompu), l'insigne de gardienne, les ambiances des deux zones.

const SOUVERAIN := &"souverain"
## Gabarit vu (m) visé : √(hauteur × longueur), compressé au-delà de 1,5 m (direction-artistique.md) ; ~12 m de long.
const GABARIT := 3.8
const BATTLE_K := 1.99
const STRETCH := 1.15
const PX := 48.0
const MOVES: Array[StringName] = [&"queueSouveraine", &"tremblement", &"criSouverain", &"immobile"]
const ZONES: Array[StringName] = [&"terre_apex", &"coeur_apex"]
const ISAURE := {"Hauban": [&"pteranodon", 47], "Bouline": [&"baryonyx", 47], "Étrave": [&"suchomimus", 48], "Carène": [&"archelon", 49]}


func test_fiche_du_souverain() -> void:
	assert_bool(SpeciesDB.PATHS.has(SOUVERAIN)).override_failure_message("souverain absent de SpeciesDB.PATHS").is_true()
	var sp := SpeciesDB.get_species(SOUVERAIN)
	assert_object(sp).is_not_null()
	assert_str(sp.display_name).is_equal("Souverain")
	assert_str(String(sp.family)).is_equal("archosaure")
	assert_str(String(MovesDB.FAMILY_TYPES.get(sp.family, ""))).override_failure_message("le Souverain n'a pas de type").is_equal("terre")
	assert_str(sp.cry_prefix).is_equal("sauropode")
	assert_object(sp.cry("neutre")).override_failure_message("pas de cri « sauropode-neutre »").is_not_null()
	assert_int(sp.description.length()).is_greater(60)
	assert_str(sp.rarity).is_equal("legendary")


func test_planches_et_tailles_du_souverain() -> void:
	var sp := SpeciesDB.get_species(SOUVERAIN)
	assert_object(sp.sheet).is_not_null()
	if sp.sheet == null:
		return
	if not sp.sheet.resource_path.get_file().begins_with("souverain"):
		prints("   souverain : planche de REPLI %s (en attente de l'agent images)" % sp.sheet.resource_path)
	assert_bool(sp.sheet.get_width() % 3 == 0 and sp.sheet.get_height() % 2 == 0) \
		.override_failure_message("planche de profil pas en 3 × 2 (%s)" % sp.sheet.get_size()).is_true()
	var fb: Texture2D = sp.face_back_sheet
	assert_object(fb).override_failure_message("pas de planche face/dos").is_not_null()
	if fb:
		assert_bool(floori(fb.get_width() / 4.0) == floori(sp.sheet.get_width() / 3.0) and fb.get_height() == sp.sheet.get_height()) \
			.override_failure_message("planche face/dos %s, pas en 4 × 2 aux cases du profil" % fb.get_size()).is_true()
	assert_bool(SheetFrames.has_corrupted(sp)).override_failure_message("pas de planche corrompue (le shader la remplace)").is_true()
	var r: Rect2 = DinoSize.drawn(sp)
	var g := sqrt(r.size.y * STRETCH * r.size.x) * sp.world_scale / PX
	var scale := sp.world_scale * GABARIT / maxf(g, 0.01)
	var battle := scale * BATTLE_K / sqrt(GABARIT)
	assert_float(absf(g - GABARIT)).override_failure_message("gabarit vu %.2f m, visé %.2f m (poser world_scale = %.3f, battle_scale = %.3f)" % [
		g, GABARIT, scale, battle]).is_less(GABARIT * 0.06)
	assert_float(absf(sp.battle_scale - battle)).override_failure_message("battle_scale %.3f, visé %.3f" % [sp.battle_scale, battle]).is_less(battle * 0.08)


func test_ses_quatre_coups_neutres_il_recule() -> void:
	var d := ApexBattles.souverain()
	assert_int(d.level).is_equal(50)
	assert_bool(d.corrupted).is_true()
	var ids: Array = d.moves.map(func(m: Dictionary) -> StringName: return m["id"])
	assert_array(ids).override_failure_message("ses coups : %s" % [ids]).contains_exactly_in_any_order(MOVES)
	for id in MOVES:
		var m := MovesDB.move(id)
		assert_str(String(m["type"])).override_failure_message("%s : pas neutre" % id).is_equal("neutre")
		assert_str(String(m.get("say", ""))).override_failure_message("%s : rien à dire à la place de « utilise »" % id).contains("%s")
	assert_str(String(MovesDB.move(&"queueSouveraine")["name"])).is_equal("Coup de queue")
	assert_str(String(MovesDB.move(&"immobile")["name"])).is_equal("Il ne bouge pas")
	assert_str(String(MovesDB.move(&"criSouverain")["effect"]["status"])).is_equal("peur")
	for id in [&"queueSouveraine", &"tremblement", &"immobile"]:
		assert_str(String(MovesDB.move(id)["fx"])).override_failure_message("%s : il avance (il frappe en reculant)" % id).is_equal("recul")
	# Personne d'autre n'apprend ses coups.
	for other: StringName in SpeciesDB.all_ids():
		if other == SOUVERAIN:
			continue
		var learnt: Array = MovesDB.learnset(Dino.create(other, 50)).map(func(e: Array) -> StringName: return e[1])
		assert_bool(learnt.any(func(m: StringName) -> bool: return m in MOVES)) \
			.override_failure_message("%s apprend un coup du Souverain : %s" % [other, learnt]).is_false()


func test_dinodex_unique_des_apex() -> void:
	var u := DexDB.unique_info(SOUVERAIN)
	assert_bool(u.is_empty()).override_failure_message("le Souverain n'est pas parmi les Uniques").is_false()
	assert_str(String(u.get("region", ""))).is_equal("apex")
	assert_bool(SOUVERAIN in DexDB.order()).override_failure_message("le Souverain est dans la liste du Dinodex (c'est un Unique)").is_false()
	var f: Dictionary = DexFacts.INFO.get(SOUVERAIN, {})
	var missing := ["size", "diet", "era", "from", "trait", "fact"].filter(func(k: String) -> bool: return String(f.get(k, "")) == "")
	assert_array(missing).override_failure_message("fiche du Dinodex incomplète, manque %s" % [missing]).is_empty()
	assert_bool(DexFacts.DIETS.has(f.get("diet", ""))).is_true()
	assert_dict(DexDB.matchups(DexDB.type_of(SOUVERAIN))).contains_keys(["strong", "weak", "resists"])
	assert_bool(AtlasDB.REGIONS.any(func(r: Dictionary) -> bool: return r["id"] == &"apex")).override_failure_message("pas de région « apex » à l'atlas").is_true()


func test_equipe_d_isaure_pas_un_corrompu() -> void:
	var team := ApexBattles.isaure_team()
	assert_int(team.size()).is_equal(4)
	for m: Array in team:
		var want: Array = ISAURE.get(m[2], [])
		assert_bool(want.is_empty()).override_failure_message("dino inconnu dans l'équipe d'Isaure : %s" % m[2]).is_false()
		if want.is_empty():
			continue
		assert_str(String(m[0])).override_failure_message("%s : espèce %s" % [m[2], m[0]]).is_equal(String(want[0]))
		assert_int(m[1]).override_failure_message("%s : niv. %d" % [m[2], m[1]]).is_equal(want[1])
		var options: Dictionary = m[3]
		assert_bool(options.get("corrupted", false)).override_failure_message("%s est corrompu (« plus jamais »)" % m[2]).is_false()
		assert_bool(options.has("intro")).override_failure_message("%s entre sans sa ligne" % m[2]).is_true()
		assert_object(SpeciesDB.get_species(m[0]).sheet).is_not_null()
	for i in 3:
		assert_bool((team[i][3] as Dictionary).has("before")).override_failure_message("%s sans la réplique d'Isaure" % team[i][2]).is_true()
	assert_bool((team[3][3] as Dictionary).has("before")).override_failure_message("Carène : la scène pose le choix, pas une réplique").is_false()


func test_insigne_de_gardienne_objet_cle() -> void:
	var it := ItemsDB.item("insigne_gardienne")
	assert_bool(ItemsDB.ITEMS.has("insigne_gardienne")).is_true()
	assert_str(String(it["kind"])).is_equal("cle")
	assert_int(int(it["sell"])).is_equal(0)
	assert_str(String(it["desc"])).contains("reconnaissent déjà")
	if not ResourceLoader.exists("res://assets/art/ui/insigne_gardienne.png"):
		prints("   insigne_gardienne : icône de REPLI (l'ambre)")
	assert_object(ItemsDB.icon("insigne_gardienne")).is_not_null()


func test_ambiances_des_deux_zones() -> void:
	for zone in ZONES:
		assert_bool(AmbienceDB.has(zone)).override_failure_message("pas d'ambiance %s" % zone).is_true()
		var amb := AmbienceDB.get_ambience(zone)
		var beds: Array = amb.get("beds", [])
		assert_array(beds).is_not_empty()
		var sounds: Array = beds.map(func(b: Array) -> String: return b[0])
		for c: Dictionary in amb.get("calls", []):
			sounds.append_array(c["ids"])
		var missing := sounds.filter(func(s: String) -> bool: return not ResourceLoader.exists(AmbienceDB.PATH % s))
		assert_array(missing).override_failure_message("ambiance %s : sons introuvables %s" % [zone, missing]).is_empty()
		# Pas un oiseau au cratère ; son souffle (la rafale grave) presque régulier.
		assert_bool(sounds.any(func(s: String) -> bool: return s.begins_with("oiseau") or s == "mouettes")).is_false()
		var breath: Array = amb["calls"].filter(func(c: Dictionary) -> bool: return "rafale-grave" in c["ids"])
		assert_int(breath.size()).override_failure_message("%s : pas de souffle" % zone).is_equal(1)
		if breath.size() == 1:
			assert_float(float(breath[0]["every"][1]) - float(breath[0]["every"][0])).is_less_equal(4.0)
