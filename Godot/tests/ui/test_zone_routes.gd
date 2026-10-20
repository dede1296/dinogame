extends GdUnitTestSuite
## Les chemins entre zones (ZoneRoutes), sans fenêtre : la table des liens dit la même chose que les
## scènes des zones (leurs sorties et leurs plongées : `target_zone` dans chaque .tscn), le plus court
## chemin donne la prochaine zone, et l'aide de quête pointe la bonne sortie quand l'objectif est
## ailleurs (Port-Ambre → Prairie : la sortie du nord ; → Cabinet : la porte, une entrée).

const WORLD := "res://world/world.gd"
const TARGET := "target_zone = &\"(\\w+)\""

var _open: Array[Node] = []


func after_test() -> void:
	for r in _open:
		r.free()
	_open.clear()


func _zone(path: String) -> Region:
	var r := Region.open_for_preview(path)
	_open.append(r)
	return r


## zone -> the zones its scene leads to (its exits and dive spots), read from the scene files.
func _links_in_scenes() -> Dictionary:
	var zones: Dictionary = (load(WORLD) as GDScript).get_script_constant_map()["ZONES"]
	var regex := RegEx.create_from_string(TARGET)
	var out := {}
	for id: StringName in zones:
		var text := FileAccess.get_file_as_string(zones[id])
		var found: Array[StringName] = []
		for hit in regex.search_all(text):
			var to := StringName(hit.get_string(1))
			if to != id and not to in found:
				found.append(to)
		found.sort()
		out[id] = found
	return out


func test_la_table_dit_ce_que_disent_les_scenes() -> void:
	var scenes := _links_in_scenes()
	for id: StringName in scenes:
		var table: Array = ZoneRoutes.LINKS.get(id, [])
		var sorted := table.duplicate()
		sorted.sort()
		assert_array(sorted).override_failure_message("%s : la table dit %s, la scène %s" % [id, sorted, scenes[id]]) \
			.is_equal(scenes[id])
	for id: StringName in ZoneRoutes.LINKS:
		assert_bool(scenes.has(id)).override_failure_message("%s : dans la table, pas dans world.gd" % id).is_true()


func test_prochaine_zone_par_le_plus_court_chemin() -> void:
	assert_str(String(ZoneRoutes.next_hop(&"port_ambre", &"plaines"))).is_equal("plaines")
	assert_str(String(ZoneRoutes.next_hop(&"port_ambre", &"foret"))).is_equal("plaines")
	assert_str(String(ZoneRoutes.next_hop(&"havre_dore", &"grotte_echos"))).is_equal("port_ambre")
	assert_str(String(ZoneRoutes.next_hop(&"cote", &"plaines"))).is_equal("desert")
	assert_str(String(ZoneRoutes.next_hop(&"cabinet", &"havre_dore"))).is_equal("port_ambre")


func test_pas_de_prochaine_zone_sur_place_ou_sans_chemin() -> void:
	assert_str(String(ZoneRoutes.next_hop(&"plaines", &"plaines"))).is_equal("")
	assert_str(String(ZoneRoutes.next_hop(&"plaines", &"nulle_part"))).is_equal("")
	assert_str(String(ZoneRoutes.next_hop(&"clos_blanc", &"plaines"))).is_equal("")


func test_objectif_dans_la_zone_son_lieu() -> void:
	var goal := {"id": "x", "zone": &"plaines", "tile": Vector2(20, 41), "main": true}
	var h := ZoneRoutes.heading(goal, &"plaines", null, Vector2(60, 47))
	assert_vector(h["tile"]).is_equal(Vector2(20, 41))
	assert_str(String(h["via"])).is_equal("")


func test_objectif_sans_lieu_ni_zone() -> void:
	assert_dict(ZoneRoutes.heading({}, &"plaines", null, Vector2.ZERO)).is_empty()
	var goal := {"id": "x", "zone": &"plaines", "tile": Vector2.INF, "main": false}
	var h := ZoneRoutes.heading(goal, &"plaines", null, Vector2.ZERO)
	assert_bool(h["tile"] == Vector2.INF).is_true()


func test_objectif_ailleurs_la_sortie_vers_la_prochaine_zone() -> void:
	var port := _zone("res://regions/port/port_ambre.tscn")
	var goal := {"id": "bosquet", "zone": &"plaines", "tile": Vector2(20, 41), "main": true}
	var here := port.spawn_point(&"Depart") / ZoneRoutes.TILE
	var h := ZoneRoutes.heading(goal, &"port_ambre", port, here)
	assert_str(String(h["via"])).is_equal("plaines")
	assert_str(h["kind"]).is_equal("sortie")
	var exit: ZoneExit = null
	for e in port.exits():
		if e.target_zone == &"plaines":
			exit = e
	assert_object(exit).is_not_null()
	var expected := port.exit_rect(exit).get_center() / ZoneRoutes.TILE
	assert_float((h["tile"] as Vector2).distance_to(expected)).is_less(0.01)


func test_une_porte_dans_la_zone_est_une_entree() -> void:
	var port := _zone("res://regions/port/port_ambre.tscn")
	var goal := {"id": "tiroir", "zone": &"cabinet", "tile": Vector2(4, 3), "main": true}
	var h := ZoneRoutes.heading(goal, &"port_ambre", port, Vector2(30, 20))
	assert_str(String(h["via"])).is_equal("cabinet")
	assert_str(h["kind"]).is_equal("entrée")
	assert_bool(h["tile"] != Vector2.INF).is_true()


func test_plusieurs_zones_plus_loin_la_premiere_sortie() -> void:
	var port := _zone("res://regions/port/port_ambre.tscn")
	var goal := {"id": "ravin", "zone": &"foret", "tile": Vector2(22, 80), "main": true}
	var h := ZoneRoutes.heading(goal, &"port_ambre", port, Vector2(30, 20))
	assert_str(String(h["via"])).is_equal("plaines")
	assert_str(String(h["dest"])).is_equal("foret")
