extends RefCounted
## La mini-carte (Minimap) et la direction de l'objectif (QuestTracker), dans le jeu, en trois zones :
## la Prairie (l'objectif — Joss, à Havre-Doré — est deux zones plus loin : « sortie : Port-Ambre », la
## sortie en pointe sur le bord), Port-Ambre (« sortie : Havre-Doré »), Havre-Doré (l'objectif dans la
## zone : loin, en pointe sur le bord ; puis proche, numéroté et entouré). Tab : grande, zoom, masquée,
## petite. La grande carte, inchangée. Masquée pendant un dialogue et au Cabinet (zone fermée). La page Affichage de Paramètres,
## la page du tutoriel. Ce que coûte la mini-carte (µs par image, dessins de la texture). Voir tools/capture.gd :
##   godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##       scenario_file=res://tools/scenarios/minimap_test.gd "titre=Mini-carte et direction de l'objectif…"
## À lire dans la sortie : « static state » (mode, zoom, visible, chevauchements), « static perf ».

const SELF := "res://tools/scenarios/minimap_test.gd"

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "ferreol_rencontre"]],
	[0.82, "calm", 900.0],
	[0.84, "weather", &"clear"],
	[0.86, "clock", 11.0],
	[0.88, "talk", true],
	[0.90, "static", [SELF, "reset"]],
	# 1. La Prairie : l'objectif est à Havre-Doré, deux zones plus loin.
	[1.00, "tp", Vector2(60.0, 47.0)],
	[1.10, "calm", 900.0],
	[3.40, "static", [SELF, "state"]],
	[3.50, "shot", "m1_prairie_petite_hors_zone"],
	[3.60, "press", "minimap"],
	[4.40, "static", [SELF, "state"]],
	[4.50, "shot", "m2_prairie_grande"],
	[4.60, "press", "minimap_zoom_in"],
	[5.40, "shot", "m3_prairie_grande_zoom"],
	[5.50, "press", "minimap"],
	[6.20, "static", [SELF, "state"]],
	[6.30, "press", "minimap"],
	[6.40, "press", "minimap_zoom_out"],
	# 2. Port-Ambre : Havre-Doré est la zone voisine.
	[6.60, "zone", &"port_ambre"],
	[8.40, "calm", 900.0],
	[9.80, "static", [SELF, "state"]],
	[9.90, "shot", "m4_port_sortie_havre"],
	# 3. Havre-Doré : l'objectif dans la zone, loin puis proche.
	[10.0, "zone", &"havre_dore"],
	[11.8, "calm", 900.0],
	[13.2, "static", [SELF, "state"]],
	[13.3, "shot", "m5_havre_objectif_loin"],
	[13.4, "tp", Vector2(36.0, 13.0)],
	[13.5, "calm", 900.0],
	[15.0, "static", [SELF, "state"]],
	[15.1, "shot", "m6_havre_objectif_proche"],
	# 4. La grande carte (la même ZoneMap, en entier : noms, pulsations) n'a pas changé.
	[15.2, "call", ["_open_map", []]],
	[16.2, "shot", "m7_grande_carte"],
	[16.3, "press", "cancel"],
	# 5. Un dialogue : la mini-carte s'efface.
	[16.5, "talk", false],
	[16.6, "static", [SELF, "talk"]],
	[17.3, "static", [SELF, "state"]],
	[17.4, "shot", "m8_dialogue_masquee"],
	[17.5, "talk", true],
	# 6. Une zone fermée (le Cabinet) : pas de mini-carte, la direction reste.
	[18.0, "zone", &"cabinet"],
	[20.6, "static", [SELF, "state"]],
	[20.7, "shot", "m9_cabinet_sans_minicarte"],
	# 7. Paramètres → Affichage, puis le tutoriel des commandes (page 2).
	[20.8, "settings", null],
	[21.2, "static", [SELF, "display_page"]],
	[21.7, "shot", "m10_parametres_affichage"],
	[21.8, "press", "cancel"],
	[22.0, "press", "cancel"],
	[22.4, "static", [SELF, "tutorial"]],
	[23.0, "shot", "m11_tutoriel_page2"],
	[23.1, "static", [SELF, "close_tutorial"]],
	[23.5, "static", [SELF, "perf"]],
]


static func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func _minimap() -> Minimap:
	var found := _tree().current_scene.find_children("Minimap", "Minimap", true, false)
	return found[0] if not found.is_empty() else null


## The test starts from the default: small, default zoom (in memory: the player's settings stay).
static func reset() -> String:
	Minimap.set_pref_mode(MinimapMath.Mode.SMALL, false)
	Minimap.set_pref_zoom(MinimapMath.ZOOM_DEFAULT, false)
	QuestTracker.set_direction_shown(true, false)
	var m := _minimap()
	if m:
		m.set_mode(MinimapMath.Mode.SMALL)
		m.zoom_by(MinimapMath.ZOOM_DEFAULT - m.current_zoom())
	Minimap.cost_us = 0
	Minimap.draw_us = 0
	Minimap.render_us = 0
	Minimap.frames = 0
	Minimap.renders = 0
	return "réglages remis"


## Mode, zoom, shown or not, where; the tracker's line; and what it would overlap (nothing, hopefully).
static func state() -> String:
	var world := _tree().current_scene
	var m := _minimap()
	var tracker: QuestTracker = world.get("_tracker")
	var line := "zone %s · mini-carte mode %d zoom %d visible %s alpha %.2f rect %s" % [
		world.get("region").region_id, m.current_mode(), m.current_zoom(), m.visible, m.modulate.a,
		HudHint.shown_rect(m)]
	line += " · suivi « %s » : « %s »" % [tracker.get("_title").text, tracker.get("_distance").text if tracker.get("_way").visible else "(pas de ligne)"]
	var hits: Array[String] = []
	if m.visible:
		for other in _hud_parts(world.get("hud")):
			if HudHint.shown_rect(other).intersects(HudHint.shown_rect(m)):
				hits.append(String(other.name))
	line += " · %s" % ("PASS aucun chevauchement" if hits.is_empty() else "FAIL chevauche %s" % ", ".join(hits))
	return line


## What the minimap must never cover: the party's portraits, the tracker, the clock, the purse, the round
## buttons and the keys written under them.
static func _hud_parts(hud: CanvasLayer) -> Array[Control]:
	var out: Array[Control] = []
	for node in hud.find_children("*", "Control", true, false):
		var c := node as Control
		if c is Minimap or not c.is_visible_in_tree() or c.size == Vector2.ZERO:
			continue
		if c is QuestTracker or c is ClockBadge or c is PurseBadge or c is Button or c.name == "KeyTag" \
				or (c.get("dino") != null and c.get("lead") != null):
			out.append(c)
	return out


static func talk() -> String:
	Dialogue.run([{"text": "Une réplique pour voir : la mini-carte s'efface pendant les dialogues."}])
	return "dialogue lancé"


static func display_page() -> String:
	for n in _tree().root.get_children():
		if n is SettingsMenu:
			n.call("_show", "affichage")
			var row: Node = n.find_child("HudRow", true, false)
			return "page Affichage, rangée des aides : %s" % ("présente" if row else "ABSENTE")
	return "FAIL menu introuvable"


static func tutorial() -> String:
	var t := ControlsTutorial.open(_tree().root)
	t.call("_turn", 1)
	return "tutoriel page 2"


static func close_tutorial() -> String:
	for n in _tree().root.get_children():
		if n is ControlsTutorial:
			n.call("_finish")
	return "tutoriel fermé"


static func perf() -> String:
	var frames := maxi(Minimap.frames, 1)
	return "coût mini-carte : %.1f µs par image en moyenne (%d images ; dont textures %.1f, dessins %.1f), %d dessins de la texture, mise en place d'une zone %.1f ms, %d i/s" % [
		float(Minimap.cost_us + Minimap.draw_us) / frames, Minimap.frames, float(Minimap.render_us) / frames,
		float(Minimap.draw_us) / frames, Minimap.renders, Minimap.setup_us / 1000.0, Engine.get_frames_per_second()]
