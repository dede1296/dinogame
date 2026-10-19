extends GdUnitTestSuite
## La carte du chapitre 9 (agent CARTE), sans fenêtre : les deux zones nouvelles (`terre_apex`, `coeur_apex`,
## regions/apex/), le raccord de la Porte du Cratère (`porte_cratere`), et les ajouts de l'épilogue au
## Cabinet et à Port-Ambre. Les scènes construites sont ouvertes sans être affichées
## (Region.open_for_preview) : les nœuds que l'histoire attend, leurs drapeaux (show_flag / hide_flag), les
## sorties et leurs arrivées (chaque sortie arrive sur un point qui existe dans la zone visée), et chaque
## lieu de story/apex_places.gd (ApexPlaces) dans sa zone, atteignable à pied depuis l'entrée (le relief
## seul : tools/zones/volcan_verif.gd reach), le fond du trou et les crêtes hors d'atteinte.
## Rien n'est joué, aucune touche : les vérifications de rendu restent aux captures de l'agent.

const P := preload("res://story/apex_places.gd")
const V := preload("res://tools/zones/volcan_verif.gd")
const TILE := 48.0
const SCENES := {
	&"terre_apex": "res://regions/apex/terre_apex.tscn",
	&"coeur_apex": "res://regions/apex/coeur_apex.tscn",
	&"porte_cratere": "res://regions/volcan/porte_cratere.tscn",
	&"cabinet": "res://regions/port/cabinet.tscn",
	&"port_ambre": "res://regions/port/port_ambre.tscn",
}

var _open := {}


func after_test() -> void:
	for r: Node in _open.values():
		r.free()
	_open.clear()


func _zone(id: StringName) -> Region:
	if not _open.has(id):
		_open[id] = Region.open_for_preview(SCENES[id])
	return _open[id]


func _node(id: StringName, path: String) -> Node:
	return _zone(id).get_node_or_null(path)


## The node at `path` of zone `id`: present, its show/hide flags, its event (&"" = not checked).
func _assert_flags(id: StringName, path: String, show: StringName, hide: StringName, event: StringName = &"") -> void:
	var n := _node(id, path)
	assert_object(n).override_failure_message("%s : %s manque" % [id, path]).is_not_null()
	if n == null:
		return
	assert_str(String(n.get("show_flag"))).override_failure_message("%s/%s show_flag" % [id, path]).is_equal(String(show))
	assert_str(String(n.get("hide_flag"))).override_failure_message("%s/%s hide_flag" % [id, path]).is_equal(String(hide))
	if event != &"":
		assert_str(String(n.get("event"))).override_failure_message("%s/%s event" % [id, path]).is_equal(String(event))


func _tile(t: Vector2) -> Vector2i:
	return Vector2i(t.floor())


# ------------------------------------------------------------------ les deux zones

func test_zones_aux_tailles_du_plan() -> void:
	for id: StringName in P.TAILLES:
		var r := _zone(id)
		assert_that(r.map_size()).override_failure_message("taille de %s" % id).is_equal(P.TAILLES[id])
		assert_str(String(r.region_id)).is_equal(String(id))
		assert_bool(r.indoor).override_failure_message("%s à ciel ouvert" % id).is_false()
		assert_bool(bool(r.get_meta(&"vol_interdit", false))).override_failure_message("%s : pas de Vol" % id).is_true()
		assert_object(r.battle_backdrop).override_failure_message("%s : fond de combat" % id).is_not_null()


func test_terre_apex_noeuds_et_drapeaux() -> void:
	_assert_flags(&"terre_apex", "Entities/IsaureApex", &"", &"apex_arrivee", &"isaure_apex")
	_assert_flags(&"terre_apex", "Entities/MaiaApex", &"", &"apex_arrivee", &"maia_apex")
	_assert_flags(&"terre_apex", "Entities/CaillouApex", &"", &"apex_arrivee", &"caillou_apex")
	_assert_flags(&"terre_apex", "Entities/RoiApex", &"", &"apex_fini")
	_assert_flags(&"terre_apex", "Entities/BlocLoin", &"", &"souverain_eveille")
	_assert_flags(&"terre_apex", "Entities/BlocLoinEclate", &"souverain_eveille", &"")
	_assert_flags(&"terre_apex", "Entities/SouverainLoin", &"souverain_apaise", &"")
	for i in 4:
		_assert_flags(&"terre_apex", "Entities/BlocGeant%d" % (i + 1), &"", &"", StringName("bloc_geant_%d" % (i + 1)))
	var page := _node(&"terre_apex", "Entities/Page39")
	assert_object(page).is_not_null()
	assert_str(String(page.get("taken_flag"))).is_equal("found_journal_39")
	assert_str(String(page.get("dialogue_id"))).is_equal("page_39")
	assert_that(_tile(page.position / TILE)).is_equal(_tile(P.PAGE_39))


func test_coeur_apex_noeuds_et_drapeaux() -> void:
	_assert_flags(&"coeur_apex", "Entities/BlocSouverain", &"", &"souverain_eveille", &"bloc_souverain")
	_assert_flags(&"coeur_apex", "Entities/BlocEclate", &"souverain_eveille", &"", &"bloc_eclate")
	_assert_flags(&"coeur_apex", "Entities/Souverain", &"souverain_eveille", &"souverain_apaise", &"souverain")
	_assert_flags(&"coeur_apex", "Entities/SouverainCouche", &"souverain_apaise", &"", &"souverain_couche")
	assert_bool(bool(_node(&"coeur_apex", "Entities/Souverain").get("corrupted"))).is_true()
	assert_bool(bool(_node(&"coeur_apex", "Entities/SouverainCouche").get("corrupted"))).is_false()
	for who: Array in [["IsaureCoeur", &"isaure_coeur"], ["MaiaCoeur", &"maia_coeur"], ["CaillouCoeur", &"caillou_coeur"]]:
		_assert_flags(&"coeur_apex", "Entities/" + who[0], &"", &"souverain_eveille", who[1])
	_assert_flags(&"coeur_apex", "Entities/MaiaAbri", &"souverain_eveille", &"apex_fini", &"maia_abri")
	_assert_flags(&"coeur_apex", "Entities/CaillouRempart", &"souverain_eveille", &"apex_fini", &"caillou_rempart")
	_assert_flags(&"coeur_apex", "Entities/IsaureAbri", &"helene_reveillee", &"apex_fini", &"isaure_abri")
	_assert_flags(&"coeur_apex", "Entities/HeleneAbri", &"helene_reveillee", &"apex_fini", &"helene_abri")
	# (the Souverain stands where the plan says, the bloc too)
	assert_that(_tile(_node(&"coeur_apex", "Entities/BlocSouverain").position / TILE)).is_equal(_tile(P.BLOC))
	assert_that(_tile(_node(&"coeur_apex", "Entities/Souverain").position / TILE)).is_equal(_tile(P.SOUVERAIN_PAROI))


## Before the waking, after it, once calm, after the end: never two of the same person in the hall.
func test_coeur_apex_un_seul_de_chacun_par_etat() -> void:
	var states := [[], [&"souverain_eveille", &"helene_sortie"], [&"souverain_eveille", &"helene_reveillee", &"souverain_apaise"],
		[&"souverain_eveille", &"helene_reveillee", &"souverain_apaise", &"apex_fini"]]
	var people := {"Isaure": ["IsaureCoeur", "IsaureAbri"], "Maïa": ["MaiaCoeur", "MaiaAbri"], "Caillou": ["CaillouCoeur", "CaillouRempart"],
		"le Souverain": ["Souverain", "SouverainCouche"], "le bloc": ["BlocSouverain", "BlocEclate"]}
	for flags: Array in states:
		for who: String in people:
			var here := 0
			for n: String in people[who]:
				here += 1 if _present(_node(&"coeur_apex", "Entities/" + n), flags) else 0
			assert_int(here).override_failure_message("%s, drapeaux %s : %d fois" % [who, flags, here]).is_less_equal(1)
	# (the Souverain and the broken bloc stay after the end)
	var last: Array = states[-1]
	assert_bool(_present(_node(&"coeur_apex", "Entities/SouverainCouche"), last)).is_true()
	assert_bool(_present(_node(&"coeur_apex", "Entities/BlocEclate"), last)).is_true()


func _present(n: Node, flags: Array) -> bool:
	var show := StringName(n.get("show_flag"))
	var hide := StringName(n.get("hide_flag"))
	return (show == &"" or show in flags) and (hide == &"" or not hide in flags)


# ------------------------------------------------------------------ the ways in and out

func test_sorties_et_arrivees() -> void:
	var ways := [
		[&"porte_cratere", "Exits/VersTerreApex", &"terre_apex", P.SPAWN_PORTE, &"apex_ouvert", &"apex_bloque"],
		[&"terre_apex", "Exits/VersPorteCratere", &"porte_cratere", P.SPAWN_APEX, &"", &""],
		[&"terre_apex", "Exits/VersCoeurApex", &"coeur_apex", P.SPAWN_TERRE, &"", &""],
		[&"coeur_apex", "Exits/VersTerreApex", &"terre_apex", P.SPAWN_COEUR, &"", &""],
	]
	for w: Array in ways:
		var e := _node(w[0], w[1]) as ZoneExit
		assert_object(e).override_failure_message("%s : %s manque" % [w[0], w[1]]).is_not_null()
		assert_str(String(e.target_zone)).is_equal(String(w[2]))
		assert_str(String(e.target_spawn)).is_equal(String(w[3]))
		assert_str(String(e.required_flag)).is_equal(String(w[4]))
		assert_str(String(e.blocked_dialogue)).is_equal(String(w[5]))
		# The arrival exists in the zone it leads to, and does not stand in one of its exits.
		var there := _zone(w[2])
		var spawn := there.get_node_or_null("Spawns/" + String(w[3])) as Node2D
		assert_object(spawn).override_failure_message("%s : arrivée %s manque" % [w[2], w[3]]).is_not_null()
		for x in there.exits():
			assert_bool(there.exit_rect(x).has_point(spawn.position)).override_failure_message("%s dans %s" % [w[3], x.name]).is_false()
	assert_object(_node(&"porte_cratere", "Spawns/" + String(P.LOSE_AUBE))).is_not_null()


func test_porte_ouverte_isaure_maia_caillou_partis() -> void:
	_assert_flags(&"porte_cratere", "Entities/IsaurePorte", &"", &"apex_ouvert", &"isaure_porte")
	_assert_flags(&"porte_cratere", "Entities/MaiaPorte", &"", &"apex_ouvert", &"maia_porte")
	_assert_flags(&"porte_cratere", "Entities/CaillouPorte", &"", &"apex_ouvert", &"caillou_porte")
	_assert_flags(&"porte_cratere", "Entities/PortailApex", &"", &"", &"portail_apex")


# ------------------------------------------------------------------ the places, on foot

func test_lieux_de_terre_apex_a_pied() -> void:
	var r := _zone(&"terre_apex")
	var foot := V.reach(r, _tile(P.TERRE_ENTREE), {}, {}, false)
	var places := [P.TERRE_ENTREE, P.LE_BORD, P.PAGE_39, P.PIED_PAROI, P.RAMPE_HAUT, P.RAMPE_BAS, P.SORTIE_COEUR, P.DEPUIS_COEUR,
		P.ISAURE_ARRIVEE + Vector2(0, 1), P.MAIA_ARRIVEE + Vector2(0, 1)]
	places.append_array(P.DEVANT_BLOCS)
	places.append_array(P.SPIRALE.slice(1))
	for t: Vector2 in places:
		assert_bool(foot.has(_tile(t))).override_failure_message("terre_apex : %s injoignable" % t).is_true()
	for t: Vector2 in [P.FOND, P.BLOC_LOIN, P.SOUVERAIN_LOIN, P.ROI_PERCHE]:
		assert_bool(foot.has(_tile(t))).override_failure_message("terre_apex : %s ne devrait pas être atteint" % t).is_false()


func test_lieux_du_coeur_a_pied() -> void:
	var r := _zone(&"coeur_apex")
	var foot := V.reach(r, _tile(P.COEUR_ENTREE), {}, {}, false)
	for t: Vector2 in [P.COEUR_ENTREE, P.COULOIR_BAS, P.SALLE, P.MAIN_HELENE, P.ISAURE, P.MAIA, P.CAILLOU, P.CHLOE_BLOC, P.ESSAIS,
			P.ABRI, P.ISAURE_ABRI, P.HELENE_ABRI, P.MAIA_ABRI, P.CAILLOU_REMPART, P.SOUVERAIN_PAROI, P.AIRE_COMBAT, P.COMBAT_CHLOE,
			P.COMBAT_DINO, P.SOUVERAIN_COUCHE, P.ROI_POSE]:
		assert_bool(foot.has(_tile(t))).override_failure_message("coeur_apex : %s injoignable" % t).is_true()
	# The walls: the north half's high (they face the camera), the south half's low but out of reach.
	assert_float(r.tile_height(Vector2i(24, 4))).is_greater(r.tile_height(_tile(P.SALLE)) + 5.0)
	assert_float(r.tile_height(Vector2i(24, 37))).is_less(r.tile_height(_tile(P.SALLE)) + 2.5)
	assert_bool(foot.has(Vector2i(24, 37))).is_false()


## Every place of ApexPlaces lies inside its zone's map (the porte's in porte_cratere's 50 x 40).
func test_lieux_dans_leur_zone() -> void:
	var sizes := {"terre": P.TAILLES[&"terre_apex"], "coeur": P.TAILLES[&"coeur_apex"]}
	for t: Vector2 in [P.TERRE_ENTREE, P.CAIRN, P.ROI_PERCHE, P.FOND, P.BLOC_LOIN, P.RAMPE_BAS]:
		assert_bool(Rect2(Vector2.ZERO, Vector2(sizes["terre"])).has_point(t)).is_true()
	for t: Vector2 in [P.COEUR_ENTREE, P.BLOC, P.ROCHER_ABRI, P.SOUVERAIN_PAROI, P.ROI_POSE]:
		assert_bool(Rect2(Vector2.ZERO, Vector2(sizes["coeur"])).has_point(t)).is_true()
	for t: Vector2 in [P.AUBE_CHLOE, P.DEVANT_PORTAIL, P.DEPUIS_APEX, P.DEVANT_CAMP] + P.DINOS_ISAURE_CACHES + P.DINOS_ISAURE_RANG:
		assert_bool(Rect2(0, 0, 50, 40).has_point(t)).is_true()


# ------------------------------------------------------------------ the epilogue

func test_cabinet_epilogue() -> void:
	_assert_flags(&"cabinet", "Entities/HeleneAssise", &"apex_fini", &"", &"helene_cabinet")
	_assert_flags(&"cabinet", "Entities/TableThe", &"apex_fini", &"")
	_assert_flags(&"cabinet", "Entities/IsaureCabinet", &"tasse_bleue", &"epilogue_port", &"isaure_cabinet")
	assert_that(_tile(_node(&"cabinet", "Entities/HeleneAssise").position / TILE)).is_equal(_tile(P.CABINET_HELENE))
	assert_str(String(_node(&"cabinet", "Entities/HeleneAssise").get_meta(Outfits.HELD_META, &""))).is_equal("assis")


func test_jetee_epilogue() -> void:
	for n: String in ["HeleneJetee", "RocJetee", "MaiaJetee", "HamonJetee", "JossJetee", "GustaveJetee", "FirminJetee", "RosalieJetee",
			"PervencheJetee", "CaillouJetee", "MastocJetee"]:
		_assert_flags(&"port_ambre", "Entities/" + n, &"epilogue_cabinet", &"epilogue_fini")
	for n: String in ["IsaureJetee", "SuieJetee", "CabosseJetee", "GrognonJetee"]:   # (they stay: the post-game)
		_assert_flags(&"port_ambre", "Entities/" + n, &"epilogue_cabinet", &"")
	_assert_flags(&"port_ambre", "Entities/MaiaMarche", &"tasse_bleue", &"epilogue_cabinet", &"maia_marche")
	_assert_flags(&"port_ambre", "Entities/CaillouRuelle", &"tasse_bleue", &"epilogue_cabinet", &"caillou_ruelle")
	# Brac at the end of the pier is chapter 8's, unchanged.
	_assert_flags(&"port_ambre", "Entities/BracJetee", &"brac_parti", &"", &"brac_jetee")
	# Nobody of the post-game on the way to Maïa's boat (its landing, the end of the pier).
	var landing := (_node(&"port_ambre", "Spawns/Embarcadere") as Node2D).position
	for n: Node in _zone(&"port_ambre").get_node("Entities").get_children():
		if (n is Npc or n is DinoNpc) and String(n.get("show_flag")) == "epilogue_cabinet" and String(n.get("hide_flag")) == "":
			assert_float((n as Node2D).position.distance_to(landing)).override_failure_message("%s près de l'embarcadère" % n.name) \
				.is_greater(1.5 * TILE)
