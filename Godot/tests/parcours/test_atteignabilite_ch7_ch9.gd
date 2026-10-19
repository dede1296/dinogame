extends GdUnitTestSuite
## Le parcours de sécurité, l'atteignabilité des zones des chapitres 7 à 9 (sans fenêtre : les scènes
## construites, ouvertes sans être affichées). Le calcul est celui des plans des zones
## (tools/zone_builder.gd _reachable, tools/zones/volcan_verif.gd reach, apex_verif.gd, cieux_canvas.gd
## check), refait sur les scènes telles qu'elles sont aujourd'hui (tests/parcours/outils_parcours.gd) :
## - les lieux nommés de chaque plan (VolcanPlaces, ApexPlaces, CieuxPlaces) : à pied depuis l'arrivée ;
##   au-delà d'une coulée, seulement sur le dos d'un dino de pierre ou de feu ; le chemin du cratère,
##   seulement une fois la lave retirée ; les lieux « hors d'atteinte » (le fond du trou, le perchoir du Roi)
##   pas atteints ; les lieux « en vol » des Cieux pas atteints à pied mais où se poser ;
## - depuis CHAQUE arrivée de la zone, chaque sortie (la suivante de l'histoire, celle d'où l'on vient),
##   l'histoire finie (tout est débloqué : la barricade tombée, la lave retirée, un dino de pierre en
##   tête), avec les décors de l'histoire pour murs (un portail, une barricade ne ferment rien) ;
## - chaque nœud de l'histoire (un PNJ, un dino, un décor à événement, une page, une trouvaille, un
##   déclencheur) : Chloé peut aller lui parler (ou y entrer), sauf ceux faits pour être hors
##   d'atteinte (le Roi perché, le bloc vu d'en haut) et ceux des îlots des Cieux, en vol.
## Un écart est un résultat : rien n'est corrigé ici.

const U := preload("res://tests/parcours/outils_parcours.gd")
const CP := preload("res://story/cieux_places.gd")
const AP := preload("res://story/apex_places.gd")
const VPL := preload("res://story/volcan_places.gd")
const ZB := preload("res://tools/zone_builder.gd")
const SAVE_PATH := "user://test_gdunit_parcours_atteignabilite.json"
## Chaque zone : son arrivée depuis la zone d'avant dans l'histoire, son plan (tools/zones/*.gd : ses
## listes _on_foot / _mounted, ses « out » et « after_retreat »).
const ZONES := {
	&"cieux": {"entree": &"DepuisMonts"},
	&"nids_geants": {"entree": &"DepuisCieux"},
	&"arche_du_vent": {"entree": &"DepuisNids"},
	&"champs_cendres": {"entree": &"DepuisArche", "plan": "res://tools/zones/volcan_champs.gd"},
	&"forges_ombre": {"entree": &"DepuisChamps", "plan": "res://tools/zones/volcan_forges.gd"},
	&"coulees_lave": {"entree": &"DepuisForges", "plan": "res://tools/zones/volcan_coulees.gd"},
	&"sanctuaire_magma": {"entree": &"DepuisCoulees", "plan": "res://tools/zones/volcan_sanctuaire.gd"},
	&"porte_cratere": {"entree": &"DepuisCoulees", "plan": "res://tools/zones/volcan_porte.gd"},
	&"terre_apex": {"entree": &"DepuisPorte", "plan": "res://tools/zones/apex_terre.gd"},
	&"coeur_apex": {"entree": &"DepuisTerre", "plan": "res://tools/zones/apex_coeur.gd"},
}
## Les nœuds faits pour être hors d'atteinte à pied (tools/zones/apex_terre.gd « unreached_ok ») : zone/nœud.
const OUT_OF_REACH := ["terre_apex/RoiApex", "terre_apex/BlocLoin", "terre_apex/BlocLoinEclate", "terre_apex/SouverainLoin"]
## Tout ce que l'histoire pose jusqu'à la fin du chapitre 9 dans ces zones (pour « l'histoire finie »).
const END_FLAGS := [&"prologue_done", &"vol_obtenu", &"volcan_ouvert", &"masque_tombe", &"premier_corrompu_volcan",
	&"forge_1_eteinte", &"forge_2_eteinte", &"forge_3_eteinte", &"barricade_tombee", &"brac_volcan_vu", &"brac_parti",
	&"grande_forge_eteinte", &"suie_partie", &"lave_franchie", &"trex_magma_battu", &"lave_retiree", &"apex_ouvert",
	&"apex_arrivee", &"coeur_apex_arrivee", &"souverain_eveille", &"helene_reveillee", &"souverain_apaise", &"apex_fini"]

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	Save.path = _saved_path
	Game.new_game()
	U.free_all()


## Chloé with Vif (on foot over the lava: no), or a grown Saichania in the lead (« le cuir pour »).
static func team(on_back: bool) -> void:
	Game.new_game()
	Game.give_starter(&"velociraptor")
	Game.party[0] = Dino.create(&"velociraptor", 40, "Vif")
	Game.set_flag(&"prologue_done")
	if on_back:
		Game.party.insert(0, Dino.create(&"saichania", 44, "Caillasse"))


static func entry(z: StringName) -> Vector2i:
	return U.tile_of(U.spawn_px(U.zone(z), ZONES[z]["entree"]))


## The places of a zone's plan: {on_foot, mounted, after, out, by_air} (name -> tile point).
static func places(z: StringName) -> Dictionary:
	var out := {"on_foot": {}, "mounted": {}, "after": {}, "out": {}, "by_air": {}}
	match z:
		&"cieux":
			out["on_foot"] = {"arrivée": CP.ENTREE_MONTS, "sortie vers les Monts": CP.SORTIE_MONTS - Vector2(0, 1), "premier pont": CP.PREMIER_PONT,
				"le Guet": CP.GUET, "la Mer de nuages (le creux)": CP.MER_DE_NUAGES, "les Vents": CP.VENTS, "le Haut": CP.HAUT,
				"le Fendu": CP.FENDU, "les rhamphorhynques": CP.RHAMPHOS, "le Belvédère": CP.BELVEDERE, "page 31": CP.PAGE_31,
				"sortie vers les nids": CP.SORTIE_NIDS}
			out["by_air"] = {"îlot de la page 33": CP.ILOT_NUAGES, "aiguille au nid": CP.AIGUILLE_AU_NID, "balcon des brumes": CP.BALCON_BRUMES}
		&"nids_geants":
			out["on_foot"] = {"entrée": CP.NIDS_ENTREE, "sortie vers les Cieux": CP.SORTIE_CIEUX - Vector2(0, 1), "les nids": CP.NIDS,
				"page 32": CP.PAGE_32, "le Grand Nid": CP.GRAND_NID, "le Roi": CP.ROI, "l'aiguille": CP.AIGUILLE, "sortie vers l'Arche": CP.SORTIE_ARCHE}
			out["by_air"] = {"nid oublié": CP.NID_OUBLIE}
		&"arche_du_vent":
			out["on_foot"] = {"plateforme d'arrivée": CP.ARCHE_ENTREE, "sortie vers les nids": CP.SORTIE_NIDS_ARCHE - Vector2(0, 1),
				"l'arche (centre)": CP.ARCHE, "le Masque": CP.MASQUE, "bord du Roi": CP.BORD_ROI, "le cairn": CP.CAIRN,
				"la descente de cendre": CP.DESCENTE_CENDRE, "sortie vers le volcan": CP.SORTIE_VOLCAN, "le feu": CP.FEU_ARCHE + Vector2(1, 0)}
		_:
			var plan: Script = load(ZONES[z]["plan"])
			out["on_foot"] = plan.call(&"_on_foot")
			if plan.get_script_method_list().any(func(m: Dictionary) -> bool: return m["name"] == "_mounted"):
				out["mounted"] = plan.call(&"_mounted")
	# The plans' own extra lists (written in their check calls).
	if z == &"coulees_lave":
		out["after"] = {"le chemin du cratère": VPL.LAVE_CRATERE, "sortie vers la porte": VPL.SORTIE_PORTE}
	if z == &"terre_apex":
		out["out"] = {"le fond (sol du trou)": AP.FOND + Vector2(-6.0, 2.0), "le bloc vu d'en haut": AP.BLOC_LOIN,
			"le perchoir du Roi": AP.ROI_PERCHE, "la crête au nord-ouest": Vector2(20.0, 3.0), "le rebord sud": Vector2(40.0, 68.5)}
	if z == &"coeur_apex":
		out["out"] = {"sur le mur nord": Vector2(24.0, 5.0), "sur le mur sud": Vector2(24.0, 36.5), "derrière le couloir": Vector2(46.5, 10.0)}
	return out


# ------------------------------------------------------------------ les lieux des plans

func test_lieux_des_plans_atteints() -> void:
	var gaps: Array[String] = []
	var total := 0
	for z: StringName in ZONES:
		var r := U.zone(z)
		if r == null:
			gaps.append("%s : zone introuvable" % z)
			continue
		var from := entry(z)
		team(false)
		var foot := U.reach(z, from, false)
		team(true)
		var ride := U.reach(z, from, false)
		Game.set_flag(Lava.RETREAT_FLAG)
		var retired := U.reach(z, from, false)
		var p := places(z)
		for place: String in p["on_foot"]:
			total += 1
			if not foot.has(_c(p["on_foot"][place])):
				gaps.append("%s : « %s » %s injoignable à pied depuis %s" % [z, place, _c(p["on_foot"][place]), ZONES[z]["entree"]])
		for place: String in p["mounted"]:
			total += 1
			var c := _c(p["mounted"][place])
			if not ride.has(c):
				gaps.append("%s : « %s » %s injoignable même sur le dos d'un dino de pierre" % [z, place, c])
			elif foot.has(c):
				gaps.append("%s : « %s » %s atteint à pied (la lave ne l'entoure pas)" % [z, place, c])
		for place: String in p["after"]:
			total += 1
			var c := _c(p["after"][place])
			if not retired.has(c):
				gaps.append("%s : « %s » %s injoignable, la lave retirée" % [z, place, c])
			elif ride.has(c):
				gaps.append("%s : « %s » %s atteint avant que la lave se retire" % [z, place, c])
		for place: String in p["out"]:
			total += 1
			if retired.has(_c(p["out"][place])):
				gaps.append("%s : « %s » %s atteint (il devrait être hors d'atteinte)" % [z, place, _c(p["out"][place])])
		for place: String in p["by_air"]:
			total += 1
			var c := _c(p["by_air"][place])
			if foot.has(c):
				gaps.append("%s : « %s » %s atteint à pied (en vol seulement)" % [z, place, c])
			elif not _landing(r, c):
				gaps.append("%s : « %s » %s : pas où se poser (3 x 3 de niveau au-dessus du vide)" % [z, place, c])
	prints("   %d lieux des plans vérifiés dans %d zones" % [total, ZONES.size()])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


# ------------------------------------------------------------------ les sorties, depuis chaque arrivée

func test_chaque_sortie_depuis_chaque_arrivee() -> void:
	var gaps: Array[String] = []
	team(true)
	for f: StringName in END_FLAGS:
		Game.set_flag(f)
	for z: StringName in ZONES:
		var r := U.zone(z)
		for s in r.get_node("Spawns").get_children():
			var reached := U.reach(z, U.tile_of((s as Node2D).position))
			for e in r.exits():
				if not U.at_exit(r, reached, e):
					gaps.append("%s : depuis l'arrivée %s, la sortie %s (vers %s) n'est pas atteinte, l'histoire finie" % [z, s.name, e.name, e.target_zone])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


## On foot with Vif, from the entry, the way back is always there (no trap on arriving), and what is
## reached without the lava dino is printed (the lava zones).
func test_a_l_arrivee_le_chemin_du_retour() -> void:
	var gaps: Array[String] = []
	team(false)
	Game.set_flag(&"vol_obtenu")
	Game.set_flag(&"volcan_ouvert")
	for z: StringName in ZONES:
		var r := U.zone(z)
		var reached := U.reach(z, entry(z))
		var exits: Array[String] = []
		for e in r.exits():
			exits.append("%s:%s" % [e.name, "oui" if U.at_exit(r, reached, e) else "non"])
		prints("   %s, à pied depuis %s : %s" % [z, ZONES[z]["entree"], ", ".join(exits)])
		var spawn_name: String = ZONES[z]["entree"]
		var back := r.exits().filter(func(e: ZoneExit) -> bool: return spawn_name == "Depuis" + _short(e.target_zone))
		for e: ZoneExit in back:
			if not U.at_exit(r, reached, e):
				gaps.append("%s : arrivée %s, la sortie de retour %s pas atteinte à pied" % [z, spawn_name, e.name])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


# ------------------------------------------------------------------ les nœuds de l'histoire

func test_noeuds_de_l_histoire_atteints() -> void:
	var gaps: Array[String] = []
	var by_air: Array[String] = []
	var total := 0
	team(true)
	for f: StringName in END_FLAGS:
		Game.set_flag(f)
	for z: StringName in ZONES:
		var r := U.zone(z)
		var from := entry(z)
		for n: Node in _story_nodes(r):
			total += 1
			if "%s/%s" % [z, n.name] in OUT_OF_REACH:
				continue
			var blocked := VV_tiles(r)
			blocked.merge(U.story_walls(r, n))
			blocked.erase(from)
			var reached := U.walk(r, from, U.VV.tiles_of(r, Lava.META), blocked, true, false)
			if U.can_use(reached, n):
				continue
			var c := U.tile_of((n as Node2D).position)
			if r.has_meta(&"vol_vide_sous") and _landing_near(r, c):
				by_air.append("%s/%s" % [z, n.name])
				continue
			gaps.append("%s : %s [%s] %s injoignable (event=%s)" % [z, n.name, U.kind_of(n), c,
				n.get("event") if "event" in n else n.get("dialogue_id") if "dialogue_id" in n else ""])
	prints("   %d nœuds de l'histoire ; en vol seulement (îlots des Cieux) : %s" % [total, ", ".join(by_air)])
	assert_array(gaps).override_failure_message("\n".join(gaps)).is_empty()


# ------------------------------------------------------------------ outils

## The nodes the story needs to be reached: an event, a page (Pickup with lines), a find (NookFind), a
## trigger; not the amber pebbles (Pickup without lines: a bonus).
static func _story_nodes(r: Region) -> Array[Node]:
	var out: Array[Node] = []
	for n in r.entities.find_children("*", "", true, false):
		if not n is Node2D:
			continue
		var has_event: bool = "event" in n and String(n.get("event")) != ""
		var page: bool = n is Pickup and (String(n.get("dialogue_id")) != "" or n is NookFind)
		if has_event or page:
			out.append(n)
	return out


## The lava that goes back, still there (the walls while « lave_retiree » is not set).
static func VV_tiles(r: Region) -> Dictionary:
	if r.has_meta(Lava.META_RETREAT) and not Game.flag(StringName(r.get_meta(Lava.META_RETREAT_FLAG, Lava.RETREAT_FLAG))):
		return U.VV.tiles_of(r, Lava.META_RETREAT)
	return {}


static func _c(t: Vector2) -> Vector2i:
	return Vector2i(t.floor())


## Room to land (tools/zones/cieux_canvas.gd check): 3 x 3 level tiles, above the void.
static func _landing(r: Region, c: Vector2i) -> bool:
	return ZB.is_flat(r, c, 1) and r.tile_height(c) >= float(r.get_meta(&"vol_vide_sous", 0.0))


static func _landing_near(r: Region, c: Vector2i) -> bool:
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if _landing(r, c + Vector2i(dx, dy)):
				return true
	return false


## « porte_cratere » → « Porte » … the way the arrivals are named (DepuisPorte, DepuisCoulees…).
static func _short(zone_id: StringName) -> String:
	return {&"monts": "Monts", &"cieux": "Cieux", &"nids_geants": "Nids", &"arche_du_vent": "Arche", &"champs_cendres": "Champs",
		&"forges_ombre": "Forges", &"coulees_lave": "Coulees", &"sanctuaire_magma": "Sanctuaire", &"porte_cratere": "Porte",
		&"terre_apex": "Terre", &"coeur_apex": "Coeur"}.get(zone_id, String(zone_id))
