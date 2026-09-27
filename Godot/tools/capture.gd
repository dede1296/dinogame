extends SceneTree
## Smoke test with screenshots: starts a new game, plays a scripted scenario, saves
## screenshots, prints checks, then quits. Needs a window (not --headless) to render.
##   godot --path Godot --script res://tools/capture.gd -- out=<folder> [scenario=monde|story|…]
## A step: [time (s), command, argument]. Commands:
##   hold <action>   keep an input action pressed ("" releases)
##   press <action>  one press event (like a key or the A button)
##   shot <name>     screenshot
##   tp <Vector2>    teleport Chloé (tile coordinates) and her dino
##   check           print flags and test save → load
##   quality <0-2>   graphics level (restored when the test ends)
##   settings        open Paramètres ("cancel" closes it)

const TILE := 48.0
const SCENARIOS := {
	"title": [[2.0, "shot", "00_titre"], [3.0, "audio", null]],
	"walk": [
		[1.5, "shot", "01_arrivee"], [1.6, "hold", "move_up"], [3.0, "hold", "move_left"],
		[4.2, "shot", "02_marche"], [4.3, "hold", ""], [5.0, "hold", "move_up"], [6.5, "hold", ""],
		[7.0, "shot", "03_carrefour"], [7.1, "audio", null],
	],
	"dirs": [
		[1.0, "tp", Vector2(47.0, 70.0)], [1.2, "hold", "move_down"], [2.6, "shot", "08_vers_le_bas"],
		[2.7, "hold", "move_up"], [4.4, "shot", "09_vers_le_haut"], [4.5, "hold", ""], [5.5, "shot", "10_repos_dos"],
	],
	"battle": [
		[1.0, "battle", [&"protoceratops", 3]], [2.6, "shot", "11_combat_intro"],
		[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"], [6.0, "shot", "12_menu"],
		[6.1, "act", {"type": "move", "index": 0}], [6.45, "shot", "13_attaque"],
		[7.5, "press", "interact"], [8.5, "press", "interact"], [9.5, "press", "interact"], [10.5, "press", "interact"],
		[11.5, "press", "interact"], [12.3, "shot", "14_apres_tour"],
		[12.4, "act", {"type": "catch"}], [13.4, "press", "interact"], [14.05, "shot", "15_collier"],
		[15.5, "press", "interact"], [16.5, "press", "interact"], [17.5, "press", "interact"], [18.5, "press", "interact"],
		[19.5, "press", "interact"], [20.5, "press", "interact"], [21.0, "shot", "16_fin"], [21.5, "press", "interact"],
		[22.5, "press", "interact"], [23.5, "shot", "17_retour"], [23.6, "party", null], [23.7, "audio", null],
	],
	"fight": [
		[1.0, "tp", Vector2(47.0, 70.0)], [4.0, "audio", null],
		[4.1, "battle", [&"protoceratops", 2]], [5.0, "auto", true], [30.0, "auto", false],
		[30.5, "shot", "18_apres_victoire"], [30.6, "party", null], [30.7, "audio", null],
	],
	"quality": [
		[1.5, "quality", 0], [2.5, "shot", "20_qualite_basse"], [2.6, "quality", 1], [3.6, "shot", "21_qualite_moyenne"],
		[3.7, "quality", 2], [4.7, "shot", "22_qualite_haute"], [4.8, "settings", null], [5.5, "shot", "23_parametres"],
		[5.6, "press", "cancel"], [6.2, "shot", "24_retour_jeu"],
	],
	"raccords": [
		[1.0, "tp", Vector2(60.0, 88.4)], [2.2, "shot", "b0_sortie_port"],
		[2.3, "zone", &"port_ambre"], [3.4, "tp", Vector2(17.0, 4.0)], [4.6, "shot", "b1_port_route_nord"],
	],
	"plaines2": [
		[0.9, "calm", 120.0], [1.0, "tp", Vector2(104.0, 63.3)], [2.4, "shot", "a0_crane"],
		[2.5, "flags", ["ecaille_bosquet", "ecaille_grotte", "ecaille_falaises"]], [2.6, "level", 16],
		[2.7, "hold", "move_up"], [2.8, "hold", ""], [3.0, "press", "interact"],
		[3.2, "auto", true], [6.0, "shot", "a0b_sortie"], [7.0, "shot", "a0c_sortie"], [8.0, "shot", "a0d_sortie"], [15.0, "auto", false], [15.2, "shot", "a1_alpha"], [15.3, "state", null],
		[15.5, "tp", Vector2(105.6, 63.8)], [15.6, "hold", "move_right"], [15.7, "hold", ""], [16.0, "press", "interact"], [16.1, "pick", 0],
		[17.0, "auto", true], [61.0, "auto", false], [61.2, "state", null], [61.3, "party", null],
		[61.35, "tp", Vector2(104.0, 65.0)], [62.4, "shot", "a1b_apres_alpha"], [62.6, "zone", &"grotte_echos"], [64.5, "shot", "a2_grotte"], [65.0, "tp", Vector2(12.0, 3.0)], [66.5, "shot", "a3_grotte_haut"],
		[67.0, "zone", &"plaines"], [68.5, "tp", Vector2(93.0, 33.0)], [70.0, "shot", "a4_falaises"],
		[70.1, "tp", Vector2(96.0, 14.0)], [71.5, "shot", "a5_falaises_haut"], [71.6, "state", null],
	],
	"antre": [
		[0.9, "calm", 120.0], [1.0, "flags", ["crane_ouvert", "sceau_plaines"]],
		[1.2, "tp", Vector2(104.0, 59.4)], [2.6, "shot", "d0_devant_antre"],
		[2.7, "hold", "move_up"], [3.6, "hold", ""], [5.0, "state", null], [5.1, "shot", "d1_antre"],
		[5.2, "hold", "move_up"], [7.6, "hold", ""], [8.4, "shot", "d2_tunnel_gardien"],
		[8.5, "press", "interact"], [8.9, "press", "interact"], [9.3, "press", "interact"], [9.8, "shot", "d3_apres_message"], [9.85, "press", "interact"],
		[10.3, "hold", "move_down"], [13.4, "hold", ""], [14.8, "state", null], [14.9, "shot", "d4_retour_plaines"],
	],
	"ambiance": [
		[3.0, "audio", null], [3.1, "tp", Vector2(26.0, 67.0)], [8.0, "audio", null],
		[8.1, "zone", &"port_ambre"], [12.0, "audio", null],
		[12.1, "zone", &"grotte_echos"], [16.0, "audio", null],
		[16.1, "zone", &"cabinet"], [20.0, "audio", null],
	],
	"fouille": [
		[0.9, "calm", 300.0],
		[1.0, "tp_secret", "arbre"], [2.4, "shot", "f0_arbre_indice"], [2.5, "hold", "move_up"], [2.6, "hold", ""],
		[2.8, "press", "interact"], [3.1, "shot", "f1_secoue"], [4.0, "shot", "f2_galet_arbre"],
		[4.4, "tp_secret", "cailloux"], [5.8, "hold", "move_up"], [5.9, "hold", ""], [6.1, "press", "interact"],
		[6.4, "shot", "f3_pierre"], [7.3, "shot", "f3b_galet_pierre"],
		[7.6, "give", "compsognathus"], [7.7, "tp_secret", "monticule"], [9.2, "shot", "f4_monticule"],
		[9.3, "hold", "move_up"], [9.4, "hold", ""], [9.6, "press", "interact"], [10.3, "shot", "f5_creuse"], [11.8, "shot", "f5b_galet_creuse"],
		[12.2, "tp_secret", "galet"], [13.6, "shot", "f6_galet_visible"], [13.7, "hold", "move_up"], [13.8, "hold", ""],
		[14.0, "press", "interact"], [15.0, "shot", "f7_galet_ramasse"],
		[15.4, "tp_secret", "arbre_vide"], [16.8, "hold", "move_up"], [16.9, "hold", ""], [17.1, "press", "interact"], [17.5, "shot", "f8_arbre_vide"],
		[18.6, "map", null], [19.3, "shot", "f9_carte"], [19.4, "press", "cancel"],
		[19.8, "check", null],
	],
	"repos": [
		[0.9, "calm", 300.0], [1.0, "clock", 21.5], [1.1, "tp_prop", ["feu_camp", Vector2(0, 150)]], [3.0, "shot", "r0_feu_nuit"], [3.1, "audio", null],
		[3.2, "hold", "move_up"], [4.1, "hold", ""], [4.3, "press", "interact"], [5.2, "shot", "r1_choix"], [5.3, "pick", 2],
		[9.5, "shot", "r2_reveil_au_feu"], [9.6, "state", null], [9.7, "audio", null], [11.0, "audio", null], [12.5, "audio", null],
		[16.0, "tp_prop", ["banc", Vector2(0, 56)]], [17.4, "hold", "move_up"], [17.5, "hold", ""], [17.7, "press", "interact"], [17.8, "pick", 0],
		[22.0, "shot", "r3_banc"], [22.1, "state", null], [30.0, "audio", null],
	],
	"vie": [
		[0.9, "calm", 300.0], [0.95, "weather", &"clear"], [1.0, "clock", 11.0], [1.1, "tp", Vector2(60.0, 62.0)], [3.5, "shot", "v0_papillons"],
		[3.6, "tp", Vector2(58.0, 27.5)], [4.6, "shot", "v1_grotte_reaction"],
		[4.7, "tp", Vector2(79.0, 51.9)], [5.7, "shot", "v2_eau_reaction"],
		[5.8, "clock", 22.5], [5.9, "weather", &"clear"], [6.0, "tp", Vector2(60.0, 62.0)], [9.0, "shot", "v3_lucioles"], [9.1, "perf", "nuit_lucioles"],
	],
	"orage": [
		[0.9, "calm", 300.0], [1.0, "clock", 15.0], [1.05, "tp", Vector2(60.0, 62.0)], [1.1, "weather", &"rain"], [7.0, "shot", "o0_pluie_fine"],
		[7.1, "weather", &"storm"], [13.0, "shot", "o1_orage"], [13.1, "flash", null], [13.17, "shot", "o2_eclair"], [13.3, "audio", null], [15.0, "audio", null],
		[15.2, "battle", [&"protoceratops", 3]], [18.2, "shot", "o3_combat_orage"],
		[17.1, "auto", true], [30.0, "auto", false],
		[30.5, "give", "compsognathus"], [30.6, "card", 1], [31.3, "shot", "o4_fiche_compso"], [31.4, "close", null], [31.5, "card", 0], [32.2, "shot", "o5_fiche_vif"],
	],
	"chapardeuse": [
		[0.9, "calm", 600.0], [0.95, "talk", true], [1.0, "tp", Vector2(61.6, 44.5)], [1.2, "hold", "move_right"], [1.3, "hold", ""],
		[1.6, "press", "interact"], [5.2, "shot", "g0_vol"], [12.0, "shot", "g1_apres_vol"], [12.1, "state", null],
		[12.3, "tp", Vector2(57.5, 44.2)], [13.2, "chipie", null], [14.0, "shot", "g2_fuite"],
		[14.4, "tp", Vector2(52.5, 42.0)], [16.2, "tp", Vector2(48.5, 39.0)], [18.0, "tp", Vector2(44.5, 37.2)],
		[19.6, "shot", "g3_presque"], [19.8, "tp", Vector2(41.6, 36.3)], [21.4, "chipie", null],
		[21.6, "tp", Vector2(40.6, 35.3)], [21.8, "hold", "move_up"], [21.9, "hold", ""], [22.2, "press", "interact"],
		[24.6, "shot", "g4_nid"], [30.0, "pick", 0], [31.0, "shot", "g5_chipie"], [36.0, "party", null],
		[36.5, "tp", Vector2(61.6, 44.5)], [36.7, "hold", "move_right"], [36.8, "hold", ""], [37.2, "press", "interact"],
		[39.8, "shot", "g6_fougere"], [48.0, "check", null],
	],
	"larmes": [
		[0.9, "talk", true], [1.0, "zone", &"cabinet"], [2.4, "tp", Vector2(6.5, 5.7)], [2.6, "hold", "move_up"], [2.7, "hold", ""],
		[2.9, "flags", ["lunettes_trouvees", "amber_protoceratops", "galet_plaines_01", "galet_plaines_02", "galet_plaines_03"]],
		[3.0, "press", "interact"], [5.2, "shot", "l0_fougere"], [9.0, "shot", "l1_larmes"],
		[18.0, "pebbles", 30], [18.2, "press", "interact"], [21.0, "shot", "l2_lanterne"], [29.0, "shot", "l3_lettre"],
		[40.0, "state", null], [40.1, "egg", null],
		[40.2, "egg_steps", 2], [40.4, "hold", "move_down"], [41.0, "hold", "move_left"], [41.6, "hold", ""],
		[42.4, "shot", "l4_eclosion"], [46.0, "party", null], [46.2, "check", null],
	],
	"lune": [
		[0.9, "calm", 600.0], [0.95, "talk", true], [1.0, "gset", ["day", 2]], [1.1, "clock", 22.0], [1.2, "weather", &"clear"],
		[1.3, "tp", Vector2(79.0, 43.8)], [4.0, "shot", "m0_etang_lune"], [4.1, "state", null],
		[4.3, "hold", "move_down"], [5.8, "hold", ""], [7.4, "shot", "m1_sur_le_gue"], [7.5, "state", null],
		[7.7, "tp", Vector2(78.6, 48.6)], [7.9, "hold", "move_up"], [8.0, "hold", ""], [8.3, "press", "interact"],
		[10.0, "shot", "m2_page2"], [16.0, "clock", 6.0], [17.0, "state", null], [17.2, "shot", "m3_aube_ilot"],
		[17.4, "hold", "move_up"], [20.0, "hold", ""], [21.0, "state", null], [22.5, "state", null], [22.6, "shot", "m4_gue_eteint"],
		[22.7, "map", null], [23.4, "shot", "m5_carte"], [23.5, "press", "cancel"],
	],
	"reactions": [
		[0.9, "calm", 600.0], [0.95, "talk", true], [1.0, "zone", &"port_ambre"], [2.4, "tp", Vector2(22.6, 16.7)], [2.6, "hold", "move_up"], [2.7, "hold", ""],
		[3.0, "press", "interact"], [3.5, "shot", "r0_isaure"], [5.0, "press", "interact"], [5.5, "shot", "r1_isaure_2"],
		[7.0, "tp", Vector2(24.0, 9.4)], [7.6, "hold", "move_up"], [7.7, "hold", ""], [8.0, "press", "interact"], [8.5, "shot", "r2_maison_kerval"],
		[10.0, "press", "interact"], [10.5, "shot", "r3_maison_kerval_2"],
		[12.0, "tp", Vector2(26.4, 9.7)], [12.2, "hold", "move_up"], [12.3, "hold", ""], [12.6, "press", "interact"], [13.1, "shot", "r4_caisses"],
		[15.0, "map", null], [16.0, "shot", "r5_carte_port"], [16.2, "map_island", null], [17.0, "shot", "r6_ile"],
		[17.2, "map_zone", &"plaines"], [18.6, "shot", "r7_carte_plaines"], [18.8, "map_zoom", 2.5], [19.4, "shot", "r8_zoom"],
		[19.6, "map_goal", 0], [20.2, "shot", "r9_objectif"], [20.4, "press", "cancel"],
	],
	"reactions2": [
		[0.9, "calm", 600.0], [0.95, "talk", true], [1.0, "flags", ["met_maia", "boussole_volee", "boussole_trouvee", "boussole_rendue", "found_journal_2", "maia_page1"]],
		[1.1, "tp", Vector2(61.6, 44.5)], [1.2, "hold", "move_right"], [1.3, "hold", ""], [1.6, "press", "interact"], [2.1, "shot", "q0_maia_1"],
		[3.6, "press", "interact"], [4.1, "shot", "q1_maia_2"], [5.6, "tp_prop", ["feu_camp", Vector2(0, 0)]], [7.0, "shot", "q2_feu_plat"],
		[7.2, "tp_prop", ["feu_camp", Vector2(0, 90), 1]], [8.8, "shot", "q3_feu_anse"], [9.0, "tp", Vector2(95.5, 13.0)], [10.6, "shot", "q4_feu_falaises"],
		[10.8, "map", null], [11.8, "shot", "q5_carte"], [12.0, "map_island", null], [12.8, "shot", "q6_ile"],
	],
	"feux": [
		[0.9, "calm", 600.0], [1.0, "clock", 22.0], [1.1, "tp_prop", ["feu_camp", Vector2(60, 40), 0]], [2.8, "shot", "x0"],
		[2.9, "tp_prop", ["feu_camp", Vector2(60, 40), 1]], [4.6, "shot", "x1"], [4.7, "tp_prop", ["feu_camp", Vector2(60, 40), 2]], [6.4, "shot", "x2"],
	],
	"cabinet_carte": [
		[0.9, "talk", true], [1.0, "zone", &"cabinet"], [2.4, "tp", Vector2(5.2, 4.3)], [2.6, "hold", "move_up"], [2.7, "hold", ""], [3.0, "press", "interact"], [3.5, "shot", "k0_bureau"],
		[5.0, "press", "interact"], [5.5, "shot", "k1_bureau_2"], [7.0, "map", null], [8.0, "shot", "k2_ile_depuis_cabinet"],
	],
	"suivi": [
		[0.9, "calm", 600.0], [1.0, "tp", Vector2(58.0, 50.0)], [2.6, "shot", "t0_suivi"], [2.7, "tp", Vector2(30.0, 45.0)], [4.2, "shot", "t1_suivi_ouest"],
		[4.3, "give", "triceratops"], [4.4, "give", "compsognathus"], [4.6, "card", 0], [5.3, "shot", "t2_fiche_vif"], [5.4, "close", null],
		[5.6, "card", 1], [6.3, "shot", "t3_fiche_trice"], [6.4, "close", null], [6.6, "card", 2], [7.3, "shot", "t4_fiche_compso"], [7.4, "close", null],
		[7.6, "map", null], [8.4, "map_island", null], [9.2, "shot", "t5_ile"],
	],
	"suivi2": [
		[0.9, "calm", 600.0], [1.0, "tp", Vector2(60.0, 47.0)], [2.6, "shot", "u0_titre"], [2.7, "tap_tracker", null], [3.2, "shot", "u1_detail"],
		[3.4, "give", "triceratops"], [3.6, "card", 1], [4.3, "shot", "u2_trice_jeune"], [4.4, "close", null],
		[4.6, "map", null], [5.4, "shot", "u3_liste"], [5.5, "map_goal", 1], [6.2, "shot", "u4_liste_choisi"], [6.3, "map_island", null], [7.1, "shot", "u5_ile_position"],
	],
	"havre": [
		[0.8, "flags", ["sceau_plaines", "met_maia", "found_journal_1"]], [0.85, "calm", 600.0],
		[0.9, "zone", &"port_ambre"], [2.3, "tp", Vector2(36.5, 10.3)], [3.6, "shot", "h0_route_port"],
		[3.7, "hold", "move_right"], [5.2, "hold", ""], [5.3, "talk", true], [8.0, "shot", "h1_arrivee"],
		[16.0, "state", null], [16.1, "shot", "h2_apres_maia"],
		[16.3, "tp", Vector2(33.0, 10.7)], [16.5, "hold", "move_up"], [16.6, "hold", ""], [16.9, "press", "interact"],
		[22.0, "shot", "h3_comptoir"], [22.1, "shop_buy", "boucle"], [22.6, "shot", "h4_boutique_achat"], [22.7, "shop_tab", true], [23.3, "shot", "h5_boutique_vente"],
		[23.4, "press", "cancel"], [24.0, "tp", Vector2(42.0, 10.7)], [24.2, "hold", "move_up"], [24.3, "hold", ""], [24.6, "press", "interact"],
		[30.0, "shot", "h6_joss"], [30.5, "tp", Vector2(26.0, 19.0)], [32.0, "shot", "h7_marche"], [32.1, "tp", Vector2(20.0, 21.2)], [33.6, "shot", "h8_quai"],
		[33.7, "map", null], [34.5, "shot", "h9_carte"], [34.6, "press", "cancel"], [35.0, "state", null], [35.1, "coins", null],
	],
	"havre2": [
		[0.8, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "ferreol_rencontre", "selle_demandee"]], [0.85, "calm", 600.0],
		[0.86, "item", ["cuir", 1]], [0.87, "item", ["boucle", 1]], [0.88, "level", 12],
		[0.9, "zone", &"havre_dore"], [2.3, "tp", Vector2(42.0, 10.7)], [2.5, "hold", "move_up"], [2.6, "hold", ""], [2.8, "talk", true], [2.9, "press", "interact"],
		[4.0, "shot", "j0_joss_selle"], [12.0, "state", null], [12.1, "coins", null], [12.2, "shot", "j1_apres_selle"],
		[12.3, "tp", Vector2(20.8, 11.2)], [12.5, "hold", "move_left"], [12.55, "hold", ""], [12.8, "press", "interact"],
		[15.0, "shot", "j2_gaspard"], [15.2, "press", "ui_accept"], [21.0, "shot", "j3_combat"],
	],
	"havre_nuit": [
		[0.8, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive"]], [0.85, "calm", 600.0], [0.86, "clock", 21.9],
		[0.9, "zone", &"havre_dore"], [2.3, "tp", Vector2(40.0, 19.5)], [2.4, "talk", true], [6.5, "shot", "n0_nuit_debut"],
		[9.0, "shot", "n1_nuit_entrepot"], [16.0, "shot", "n2_nuit_fin"], [24.0, "state", null],
	],
	"ride": [
		[0.8, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "selle"]], [0.85, "calm", 600.0],
		[0.9, "zone", &"havre_dore"], [2.3, "tp", Vector2(17.0, 19.0)], [2.5, "press", "ride"], [3.4, "shot", "r0_pas_de_monture"],
		[3.5, "give", "parasaurolophus"], [3.6, "level", 14], [3.8, "press", "ride"], [5.0, "shot", "r1_en_selle"],
		[5.1, "hold", "move_right"], [6.3, "shot", "r2_galop_droite"], [6.4, "hold", "move_left"], [7.4, "shot", "r3_galop_gauche"],
		[7.5, "hold", "move_down"], [8.1, "shot", "r4_vers_camera"], [8.4, "hold", "move_up"], [8.9, "shot", "r4b_dos"], [9.0, "hold", ""], [9.6, "shot", "r5_arret_dos"],
		[9.7, "state", null], [9.8, "press", "ride"], [10.8, "shot", "r6_pied_a_terre"],
	],
	"ride2": [
		[0.8, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "selle"]], [0.85, "calm", 600.0],
		[0.86, "give", "parasaurolophus"], [0.87, "level", 14],
		[0.9, "zone", &"plaines"], [2.3, "press", "ride"], [2.6, "riding", null],
		[2.7, "zone", &"antre_crane"], [4.2, "riding", null], [4.3, "shot", "s0_interieur"],
		[4.4, "zone", &"plaines"], [5.8, "press", "ride"], [6.0, "riding", null], [6.1, "fight", "protoceratops"], [8.5, "riding", null], [8.6, "shot", "s1_combat"],
	],
	"ride_trice": [
		[0.8, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "selle"]], [0.85, "calm", 600.0],
		[0.86, "give", "triceratops"], [0.87, "level", 14],
		[0.9, "zone", &"havre_dore"], [2.3, "tp", Vector2(17.0, 19.0)], [2.6, "press", "ride"], [3.6, "shot", "t1_en_selle"],
		[3.7, "hold", "move_right"], [4.6, "shot", "t2_droite"], [4.7, "hold", "move_left"], [5.6, "shot", "t3_gauche"],
		[5.7, "hold", "move_down"], [6.3, "shot", "t4_face"], [6.4, "hold", "move_up"], [7.2, "shot", "t5_dos"], [7.3, "hold", ""], [7.9, "shot", "t6_arret_dos"],
	],
	"prologue": [
		[1.6, "shot", "90_arrivee"], [1.7, "auto", true], [9.0, "shot", "91_maia_ponton"], [16.0, "auto", false],
		[16.5, "state", null], [16.6, "shot", "92_port"],
		[17.0, "tp", Vector2(31.5, 9.9)], [17.2, "hold", "move_up"], [17.8, "hold", ""], [19.0, "state", null],
		[19.5, "auto", true], [22.0, "shot", "93_roc"], [40.0, "auto", false], [40.2, "shot", "94_cabinet"],
		[40.5, "tp", Vector2(13.9, 7.4)], [40.6, "hold", "move_up"], [40.7, "hold", ""], [41.0, "press", "interact"],
		[44.0, "shot", "95_choix"], [44.1, "pick", 0], [46.0, "auto", true], [47.0, "shot", "96_maia_bebe"],
		[58.0, "shot", "97_nuit"], [75.0, "auto", false], [75.2, "shot", "98_matin"], [75.3, "state", null], [75.4, "party", null],
	],
	"ui_combat": [
		[1.0, "tp", Vector2(60.0, 62.0)], [1.1, "weather", &"rain"], [1.2, "battle", [&"protoceratops", 3]],
		[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"], [6.2, "shot", "80_actions"],
		[6.3, "moves", null], [6.8, "shot", "81_attaques"], [6.9, "audio", null],
	],
	"combat_brume": [
		[1.0, "tp", Vector2(60.0, 62.0)], [1.1, "weather", &"mist"], [1.2, "battle", [&"velociraptor", 3]], [4.5, "shot", "74_combat_brume"],
	],
	"combat_meteo": [
		[1.0, "tp", Vector2(60.0, 62.0)], [1.1, "clock", 22.0], [1.2, "battle", [&"protoceratops", 3]], [4.5, "shot", "70_combat_nuit"],
		[4.6, "auto", true], [16.0, "auto", false],
		[16.5, "clock", 12.0], [16.6, "weather", &"rain"], [16.7, "battle", [&"parasaurolophus", 3]], [20.0, "shot", "71_combat_pluie"],
		[20.1, "auto", true], [32.0, "auto", false],
		[32.5, "weather", &"mist"], [32.6, "state", null], [32.7, "battle", [&"velociraptor", 3]], [36.0, "shot", "72_combat_brume"],
		[36.1, "auto", true], [48.0, "auto", false],
		[48.5, "weather", &"rain"], [54.0, "shot", "73_exploration_pluie"],
	],
	"selle_prix": [
		[0.8, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "ferreol_rencontre", "selle_demandee", "gaspard_battu"]], [0.85, "calm", 600.0],
		[0.86, "item", ["cuir", 1]], [0.87, "item", ["boucle", 1]], [0.88, "item", ["piece", 100]], [0.89, "level", 12],
		[0.9, "zone", &"havre_dore"], [2.3, "tp", Vector2(42.0, 10.7)], [2.5, "hold", "move_up"], [2.6, "hold", ""], [2.9, "press", "interact"],
		[3.8, "shot", "p0_joss_refuse"], [5.0, "press", "interact"], [6.0, "tracker", null],
		[6.1, "item", ["piece", 300]], [6.2, "talk", true], [6.5, "press", "interact"], [14.0, "coins", null], [14.1, "state", null],
		[14.2, "talk", false], [14.3, "tp", Vector2(20.8, 11.2)], [14.5, "hold", "move_left"], [14.55, "hold", ""], [14.8, "press", "interact"], [17.0, "shot", "p2_revanche"],
	],
	"fin_ch1": [
		[0.8, "flags", ["ecaille_bosquet", "ecaille_grotte", "ecaille_falaises", "crane_ouvert"]], [0.85, "calm", 900.0], [0.86, "level", 16],
		[0.9, "zone", &"plaines"], [2.4, "tp", Vector2(105.6, 63.8)], [3.6, "hold", "move_right"], [3.7, "hold", ""], [3.9, "press", "interact"], [4.4, "auto", true],
		[60.0, "state", null], [60.05, "shot", "e0_maia"], [70.0, "state", null], [70.1, "shot", "e0b"], [80.0, "state", null], [80.1, "shot", "e0c"], [95.0, "state", null], [110.0, "state", null], [140.0, "auto", false], [140.1, "state", null], [140.2, "tracker", null], [140.3, "shot", "e1_apres_maia"],
	],
	"cabinet_vide": [
		[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_5", "roc_parti_vu", "roc_dehors"]], [0.85, "calm", 900.0], [0.86, "clock", 21.5],
		[0.9, "zone", &"cabinet"], [1.5, "shot", "c1"], [2.5, "shot", "c2"], [3.5, "shot", "c3"], [4.5, "shot", "c4"], [5.0, "state", null],
	],
	"labo_son": [
		[0.85, "calm", 900.0], [0.9, "zone", &"cabinet"], [3.0, "audio", null],
	],
	"couveuse": [
		[0.85, "calm", 900.0], [0.9, "zone", &"cabinet"], [2.3, "tp", Vector2(13.8, 4.6)], [2.5, "hold", "move_up"], [2.6, "hold", ""],
		[2.8, "press", "interact"], [4.5, "shot", "v1"], [4.6, "press", "interact"], [5.2, "press", "interact"], [6.9, "shot", "v2"],
		[7.0, "press", "interact"], [7.6, "press", "interact"], [9.3, "shot", "v3"], [9.4, "press", "interact"], [10.0, "press", "interact"], [11.7, "shot", "v4"],
	],
	"page6": [
		[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_5", "roc_parti_vu", "roc_dehors", "cabinet_vide_vu"]], [0.85, "calm", 900.0], [0.86, "clock", 21.5],
		[0.9, "zone", &"cabinet"], [2.3, "tp", Vector2(13.8, 4.8)], [2.5, "hold", "move_up"], [2.6, "hold", ""], [2.8, "press", "interact"],
		[4.2, "press", "interact"], [5.0, "press", "interact"], [9.5, "shot", "l0_lettre"], [9.6, "auto", true], [16.0, "auto", false],
		[16.1, "clock", 8.0], [17.5, "state", null], [17.6, "zone", &"port_ambre"], [19.0, "zone", &"cabinet"], [20.5, "tp", Vector2(6.5, 5.8)],
		[21.8, "hold", "move_up"], [21.9, "hold", ""], [22.1, "press", "interact"], [27.0, "shot", "l1_roc_matin"], [27.1, "press", "interact"], [31.0, "shot", "l2_roc_cendre"],
	],
	"fin_ch1_port": [
		[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_5"]], [0.85, "calm", 900.0],
		[0.9, "zone", &"port_ambre"], [3.0, "shot", "p0_soir"], [3.1, "auto", true], [6.5, "shot", "p1_roc_sort"], [9.0, "shot", "p2_roc_part"], [20.0, "auto", false], [20.1, "state", null],
		[20.3, "zone", &"cabinet"], [22.0, "auto", true], [26.0, "auto", false], [26.1, "shot", "p3_cabinet_vide"],
		[26.3, "tp", Vector2(13.8, 4.8)], [27.5, "hold", "move_up"], [27.6, "hold", ""], [27.8, "press", "interact"], [30.0, "shot", "p4_page"], [31.0, "press", "interact"], [33.5, "shot", "p5_lettre"],
		[33.6, "auto", true], [45.0, "auto", false], [45.1, "state", null], [45.2, "tracker", null],
	],
	"grotte2": [
		[0.8, "flags", ["ecaille_bosquet", "sbire_grotte_1", "sbire_grotte_2"]], [0.85, "calm", 900.0], [0.86, "level", 12],
		[0.9, "zone", &"grotte_echos"], [2.5, "tp", Vector2(17.4, 3.3)], [3.6, "shot", "m0_proto"],
		[3.7, "hold", "move_right"], [3.8, "hold", ""], [4.0, "press", "interact"], [5.5, "press", "ui_accept"], [12.0, "shot", "m1_lecon"],
		[12.1, "auto", true], [30.0, "shot", "m2_combat"], [70.0, "auto", false], [70.1, "state", null], [70.2, "party", null], [70.3, "shot", "m3_apres"],
		[70.5, "tp", Vector2(18.1, 3.3)], [71.5, "hold", "move_right"], [71.6, "hold", ""], [71.8, "press", "interact"], [72.5, "auto", true], [78.0, "auto", false],
		[78.1, "state", null], [78.2, "shot", "m4_ecaille"],
	],
	"grotte": [
		[0.8, "flags", ["ecaille_bosquet", "rocher_casse"]], [0.85, "calm", 900.0], [0.86, "level", 12], [0.87, "give", "triceratops"], [0.88, "level", 12],
		[0.9, "zone", &"grotte_echos"], [3.5, "shot", "k0_entree"], [3.6, "auto", true],
		[40.0, "state", null], [40.1, "auto", false], [40.2, "shot", "k1_apres_gustave"],
		[40.5, "tp", Vector2(14.8, 3.0)], [42.0, "shot", "k2_chef"], [42.1, "hold", "move_right"], [42.2, "hold", ""], [42.4, "press", "interact"], [42.6, "auto", true],
		[85.0, "auto", false], [85.1, "state", null], [85.2, "tp", Vector2(17.3, 3.3)], [86.5, "shot", "k3_proto"],
		[86.6, "hold", "move_right"], [86.7, "hold", ""], [86.9, "press", "interact"], [88.5, "press", "ui_accept"], [95.0, "shot", "k4_lecon"],
		[95.1, "auto", true], [135.0, "auto", false], [135.1, "state", null], [135.2, "shot", "k5_apres"],
	],
	"pages": [
		[0.8, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "ferreol_rencontre", "selle_demandee"]], [0.85, "calm", 600.0],
		[0.86, "item", ["piece", 120]], [0.87, "pebbles", 7],
		[0.9, "zone", &"havre_dore"], [2.3, "tp", Vector2(24.6, 11.0)], [2.5, "hold", "move_up"], [2.55, "hold", ""], [2.6, "shot", "g0_bourse"], [2.8, "press", "interact"],
		[7.0, "press", "ui_down"], [7.1, "press", "ui_down"], [7.3, "press", "ui_accept"], [8.6, "press", "interact"], [13.0, "shot", "g1_page1"],
		[13.1, "press", "interact"], [16.5, "shot", "g2_page2"], [16.6, "item", ["piece", 150]], [16.75, "shot", "g3_bourse_gain"],
	],
	"questions": [
		[0.8, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "ferreol_rencontre", "selle_demandee"]], [0.85, "calm", 600.0],
		[0.86, "item", ["piece", 120]], [0.87, "item", ["cuir", 1]],
		[0.9, "zone", &"havre_dore"], [2.3, "tp", Vector2(24.6, 11.0)], [2.5, "hold", "move_up"], [2.55, "hold", ""], [2.8, "press", "interact"],
		[7.0, "press", "ui_down"], [7.2, "press", "ui_accept"], [8.2, "press", "interact"], [12.0, "shot", "q1_maia_selle"],
		[12.1, "press", "interact"], [14.0, "press", "ui_down"], [14.2, "press", "ui_accept"], [15.2, "press", "interact"], [19.5, "shot", "q2_maia_monter"],
		[19.6, "press", "interact"], [21.0, "press", "cancel"],
		[22.0, "tp", Vector2(6.0, 10.7)], [22.2, "hold", "move_up"], [22.25, "hold", ""], [22.5, "press", "interact"],
		[28.0, "press", "ui_down"], [28.2, "press", "ui_accept"], [29.2, "press", "interact"], [33.5, "shot", "q3_pervenche_pieces"],
		[33.6, "press", "interact"], [35.0, "press", "ui_accept"], [36.0, "shot", "q4_boutique"],
	],
	"images": [
		[0.85, "calm", 600.0], [0.9, "tp", Vector2(104.0, 65.0)], [2.3, "shot", "i0_crane"],
		[2.4, "tp_prop", ["galet", Vector2(0, 50), 0]], [3.8, "shot", "i1_galet"],
		[3.9, "flags", ["sceau_plaines", "havre_arrive"]], [4.0, "zone", &"havre_dore"], [5.4, "tp", Vector2(28.0, 17.5)], [6.8, "shot", "i2_marche"],
		[6.9, "tp", Vector2(10.0, 11.2)], [8.3, "shot", "i3_boutiques"], [8.4, "tp", Vector2(37.0, 11.2)], [9.8, "shot", "i4_ferreol_joss"],
		[9.9, "tp", Vector2(12.0, 22.0)], [11.3, "shot", "i5_pecheur"],
	],
	"ride_alpha": [
		[0.8, "flags", ["sceau_plaines", "havre_arrive", "selle"]], [0.85, "calm", 600.0], [0.86, "give", "triceratops"], [0.87, "level", 14],
		[0.9, "zone", &"havre_dore"], [2.3, "tp", Vector2(17.0, 19.0)], [2.6, "press", "ride"], [3.5, "shot", "a0_arret"], [3.6, "poses", null],
		[3.7, "hold", "move_right"], [4.3, "shot", "a1_marche"], [4.35, "vis", null], [4.6, "hold", ""], [5.4, "shot", "a2_arret"], [5.45, "vis", null],
	],
	"dino_vues": [
		[0.85, "calm", 600.0], [0.86, "give", "parasaurolophus"], [0.87, "call", ["goto_zone", [&"havre_dore"]]],
		[1.0, "lead", 1], [2.4, "tp", Vector2(17.0, 12.0)], [2.6, "hold", "move_down"], [4.2, "shot", "v1_para_descend"], [4.3, "hold", ""], [5.0, "shot", "v2_para_arret_face"],
		[5.1, "hold", "move_up"], [6.6, "shot", "v3_para_monte"], [6.7, "hold", ""], [7.4, "shot", "v4_para_arret_dos"],
	],
	"debug_niv": [
		[1.5, "debug", null], [1.7, "debug_call", ["_party_level", [5]]], [1.8, "debug_call", ["_party_level", [1]]], [1.9, "debug_call", ["_party_level", [-1]]],
		[2.0, "party", null], [2.3, "shot", "dn_debug_niveau"],
	],
	"debug": [
		[1.5, "debug", null], [1.7, "debug_call", ["_cycle_species", [1]]], [1.8, "debug_call", ["_lead_dino", []]],
		[1.9, "debug_call", ["_close", []]], [2.2, "party", null],
		[2.3, "call", ["goto_zone", [&"plaines"]]], [3.5, "state", null], [3.6, "shot", "66_debug_zone"],
	],
	"meteo": [
		[1.4, "tp", Vector2(60.0, 62.0)], [1.5, "clock", 8.5], [2.8, "shot", "60_matin"],
		[2.9, "clock", 16.5], [4.0, "shot", "61_apres_midi"],
		[4.1, "weather", &"rain"], [9.5, "shot", "62_pluie"],
		[9.6, "weather", &"mist"], [15.5, "shot", "63_brume"],
		[15.6, "weather", &"clear"], [15.7, "clock", 23.0], [21.0, "shot", "64_nuit"],
		[21.1, "debug", null], [21.8, "shot", "65_debug"],
	],
	"zones": [
		[1.8, "state", null], [1.9, "shot", "30_arrivee"],
		[5.5, "clock", 19.2], [6.2, "state", null], [6.3, "shot", "32_crepuscule"],
		[6.4, "clock", 23.0], [7.2, "state", null], [7.3, "shot", "33_nuit"],
		[7.4, "clock", 10.0], [7.5, "xp", 25], [8.0, "shot", "34_xp"], [8.2, "tap", 0], [8.6, "shot", "35_menu_portrait"],
		[8.7, "close", null],
	],
	"story": [
		[1.0, "tp", Vector2(61.0, 44.6)], [1.3, "hold", "move_right"], [1.4, "hold", ""],
		[1.8, "press", "interact"], [2.6, "shot", "04_maia"],
		[3.0, "press", "interact"], [3.3, "press", "interact"], [3.6, "press", "interact"], [3.9, "press", "interact"],
		[4.2, "press", "interact"], [4.5, "press", "interact"], [4.8, "press", "interact"], [5.1, "press", "interact"],
		[5.4, "press", "interact"], [5.7, "press", "interact"], [6.0, "press", "interact"], [6.3, "press", "interact"],
		[7.0, "tp", Vector2(20.0, 42.4)], [7.2, "hold", "move_up"], [7.35, "hold", ""],
		[7.8, "press", "interact"], [8.6, "shot", "05_tranche"], [8.8, "press", "interact"], [9.1, "press", "interact"],
		[9.5, "shot", "06_tronc_tranche"],
		[11.0, "tp", Vector2(15.6, 28.6)], [11.2, "hold", "move_up"], [11.3, "hold", ""],
		[11.7, "press", "interact"], [12.2, "press", "interact"], [12.6, "press", "interact"], [13.0, "press", "interact"],
		[13.4, "press", "interact"], [15.5, "shot", "07_journal"],
		[15.8, "press", "interact"], [16.2, "press", "interact"], [16.6, "press", "interact"], [17.0, "press", "interact"],
		[17.4, "press", "interact"], [17.8, "press", "interact"],
		[18.6, "check", null], [19.5, "audio", null],
	],
	"monde": [
		[1.9, "calm", 60.0], [2.0, "state", null], [2.1, "shot", "c0_arrivee_port"],
		[2.2, "tp", Vector2(60.0, 60.0)], [3.6, "shot", "c1_prairie"],
		[3.7, "tp", Vector2(60.0, 47.0)], [5.1, "shot", "c2_carrefour"],
		[5.2, "tp", Vector2(58.0, 27.6)], [6.6, "shot", "c3_grotte"],
		[6.7, "tp", Vector2(93.0, 40.5)], [8.1, "shot", "c4_porte_falaises"],
		[8.2, "tp", Vector2(99.0, 11.0)], [9.6, "shot", "c5_falaises_haut"],
		[9.7, "tp", Vector2(104.0, 65.5)], [11.1, "shot", "c6_crane"],
		[11.2, "tp", Vector2(26.0, 64.0)], [12.6, "shot", "c7_anse"],
		[12.7, "tp", Vector2(20.0, 44.5)], [14.1, "shot", "c8_bosquet"],
		[14.2, "tp", Vector2(80.0, 42.0)], [15.6, "shot", "c9_etang"], [15.7, "state", null],
		[15.8, "map", null], [16.4, "shot", "c10_carte"], [16.5, "press", "cancel"], [17.0, "shot", "c11_carte_fermee"], [17.2, "tp", Vector2(97.0, 15.6)], [17.5, "hold", "move_up"], [18.8, "hold", ""], [19.8, "shot", "c12_pied_falaise"],
	],
	"perf": [
		[0.5, "vsync", false],
		[4.0, "perf", "arrivee"], [4.1, "tp", Vector2(60.0, 47.0)], [7.0, "perf", "carrefour"],
		[7.1, "tp", Vector2(93.0, 40.5)], [10.0, "perf", "porte_falaises"], [10.1, "tp", Vector2(20.0, 44.5)], [13.0, "perf", "bosquet"],
		[13.1, "tp", Vector2(80.0, 42.0)], [16.0, "perf", "etang"], [16.1, "quality", 0], [19.0, "perf", "etang_basse"],
		[19.1, "quality", 2], [22.0, "perf", "etang_haute"],
	],
}

var _out := "user://captures"
var _steps: Array = []
var _time := 0.0
var _step := 0
var _held := ""
var _auto := false
var _talk := false
var _talk_timer := 0.0
var _auto_timer := 0.0
var _quality_before := -1
var _pick := -1


func _initialize() -> void:
	var scenario := "walk"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("scenario="):
			scenario = arg.substr(9)
	_steps = SCENARIOS[scenario]
	DirAccess.make_dir_recursive_absolute(_out)
	if scenario == "title":   # the real main scene, as the game starts
		change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
		return
	var game := root.get_node("Game")
	game.call("new_game")
	# Past the prologue with Vif, unless the scenario plays the prologue.
	if not scenario.begins_with("prologue"):
		game.call("give_starter", &"velociraptor")
		game.call("set_flag", &"prologue_done")
		game.set("items", {"collier": 5, "baie": 3})
		# In the Plaines, at the south entrance (coming from the port).
		if game.get("region_id") == &"port_ambre":
			game.set("region_id", &"plaines")
			game.set("arrival", &"DepuisPort")
	change_scene_to_file("res://world/world.tscn")


func _process(delta: float) -> bool:
	_time += delta
	if _pick >= 0:
		var buttons := root.get_node("Dialogue").find_children("*", "Button", true, false)
		if buttons.size() > _pick:
			(buttons[_pick] as Button).pressed.emit()
			_pick = -1
	if _talk and root.get_node("Dialogue").get("active"):
		_talk_timer += delta
		if _talk_timer > 0.3:
			_talk_timer = 0.0
			_run("press", "interact")
	if _auto:
		_auto_timer += delta
		if _auto_timer > 0.35:
			_auto_timer = 0.0
			_auto_step()
	while _step < _steps.size() and _time >= _steps[_step][0]:
		_run(_steps[_step][1], _steps[_step][2])
		_step += 1
	if _step >= _steps.size():
		root.get_node("Save").set("enabled", false)
		if _quality_before >= 0:
			root.get_node("Quality").call("set_level", _quality_before)
		print("CAPTURE_DONE")
		quit()
	return false


func _run(command: String, arg: Variant) -> void:
	match command:
		"hold":
			if _held != "":
				Input.action_release(_held)
			_held = arg
			if _held != "":
				Input.action_press(_held)
		"press":
			for pressed in [true, false]:
				var ev := InputEventAction.new()
				ev.action = arg
				ev.pressed = pressed
				Input.parse_input_event(ev)
		"shot":
			var path: String = _out.path_join(arg + ".png")
			root.get_viewport().get_texture().get_image().save_png(path)
			print("capture: ", arg, " fps=", Engine.get_frames_per_second(), " pause=", paused)
		"tp":
			var world := current_scene
			var pos: Vector2 = arg * TILE
			world.get("player").call("teleport", pos)
			world.get("companion").call("teleport", pos + Vector2(-34, 8))
		"audio":
			for bus in ["Music", "Ambience", "SFX"]:
				print("bus ", bus, " %.1f dB" % AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)))
			var audio := root.get_node("Audio")
			print("ambiance : ", audio.get("ambience").call("current"), " mer=%.2f" % audio.get("ambience").get("_mix")["sea"])
			for p in audio.find_children("*", "AudioStreamPlayer", true, false):
				if p.playing:
					print("audio: ", p.bus, " ", p.stream.resource_path.get_file(), " pos=%.1fs vol=%.1fdB" % [p.get_playback_position(), p.volume_db])
		"battle":
			current_scene.call("_battle", load("res://game/dino.gd").create(arg[0], arg[1]))
		"act":
			for n in current_scene.get_children():
				if n.has_signal("_action_chosen"):
					n.emit_signal("_action_chosen", arg)
		"vis":
			for p: Dictionary in current_scene.get("_view").get("_proxies"):
				if p["src"] == current_scene.get("player") or p["src"] == current_scene.get("companion"):
					var v: SpriteBase3D = p["vis"]
					print(p["src"].name, " mod=", v.modulate, " cut=", v.alpha_cut, " transp=", v.transparency, " anim=", (v as AnimatedSprite3D).animation, " pos=", v.global_position, " sort=", v.sorting_offset)
		"poses":
			var fr: SpriteFrames = current_scene.get("player").get("sprite").sprite_frames
			for a in [&"ride_right", &"ride_down", &"walk_right"]:
				var img: Image = fr.get_frame_texture(a, 0).get_image()
				var sum := 0.0
				var n := 0
				for y in range(0, img.get_height(), 4):
					for x in range(0, img.get_width(), 4):
						var al := img.get_pixel(x, y).a
						if al > 0.05:
							sum += al
							n += 1
				print(a, " ", img.get_size(), " fmt=", img.get_format(), " alpha moyen=%.2f" % (sum / maxf(n, 1)), " tex=", fr.get_frame_texture(a, 0))
		"tracker":
			for o in load("res://story/objectives.gd").call("current"):
				print("objectif : ", o["text"])
		"lead":
			root.get_node("Game").call("set_lead", arg)
		"party":
			var game := root.get_node("Game")
			for d in game.get("party"):
				print("équipe: ", d.nickname, " niv.", d.level, " PV ", d.hp, "/", d.max_hp(), " xp ", d.xp, " attaques ", d.moves.map(func(m): return m["id"]))
			print("colliers: ", game.call("item_count", "collier"), " dex capturés: ", game.get("dex_caught").keys())
		"quality":
			var quality := root.get_node("Quality")
			if _quality_before < 0:
				_quality_before = quality.get("level")
			quality.call("set_level", arg)
			print("qualité: ", quality.call("level_name"), " max_fps=", Engine.max_fps, " objets=", current_scene.get_tree().get_node_count())
		"settings":
			load("res://ui/settings_menu.gd").open(current_scene)
		"call":
			current_scene.callv(arg[0], arg[1])
		"weather":
			root.get_node("Game").call("set_weather", arg)
		"moves":
			for n in current_scene.get_children():
				if n.has_signal("_action_chosen"):
					n.call("_show_menu", n.get("_moves_menu"))
		"flags":
			for f in arg:
				root.get_node("Game").call("set_flag", StringName(f))
		"level":
			for d in root.get_node("Game").get("party"):
				d.level = arg
				d.heal()
		"zone":
			current_scene.call("goto_zone", arg)
		"pick":
			_pick = arg   # pressed as soon as the question's buttons are shown
		"debug_call":
			for n in root.get_children():
				if n.get_script() == load("res://ui/debug_menu.gd"):
					n.callv(arg[0], arg[1])
		"debug":
			load("res://ui/debug_menu.gd").open(current_scene)
		"clock":
			root.get_node("Game").set("clock", float(arg) * 60.0)
		"xp":
			root.get_node("Game").call("award_team_xp", arg)
		"tap":
			current_scene.find_children("*", "PartyBar", true, false)[0].call("_open_menu", arg)
		"close":
			current_scene.find_children("*", "PartyBar", true, false)[0].call("_close_menu")
		"calm":   # the wild dinos keep away for `arg` seconds
			for n in current_scene.get("region").get_node("Entities").get_children():
				if n.has_method("calm_down"):
					n.call("calm_down", arg)
		"tp_secret":   # next to (just south of) a hiding place of an amber pebble, facing it
			var found: Node2D = null
			for n in current_scene.get("region").get_node("Entities").get_children():
				var k: String = n.get("kind") if "kind" in n else ""
				var hides: bool = n.has_method("is_hiding") and n.call("is_hiding")
				var ok := false
				match arg:
					"arbre": ok = k in ["arbre_rond", "fougere_arbre", "araucaria"] and hides
					"arbre_vide": ok = k == "arbre_rond" and not hides and n.get_script() == load("res://world/prop.gd")
					"cailloux": ok = k == "cailloux" and hides
					"monticule": ok = n.get_script() == load("res://world/dig_spot.gd")
					"galet": ok = k == "galet"
				if ok:
					found = n
					break
			if found == null:
				print("tp_secret : rien pour ", arg)
			else:
				print("tp_secret ", arg, " : ", (found.global_position / TILE).snapped(Vector2(0.1, 0.1)))
				var pos := found.global_position + Vector2(-40, 56)
				current_scene.get("player").call("teleport", pos)
				current_scene.get("companion").call("teleport", pos + Vector2(-34, 8))
		"tp_prop":   # [kind, offset (px)]: next to the first prop of that kind
			var skip: int = arg[2] if arg.size() > 2 else 0
			for n in current_scene.get("region").get_node("Entities").get_children():
				if n.get("kind") == arg[0] and skip > 0:
					skip -= 1
				elif n.get("kind") == arg[0]:
					print("tp_prop ", arg[0], " : ", (n.global_position / TILE).snapped(Vector2(0.1, 0.1)))
					var pos: Vector2 = n.global_position + arg[1]
					current_scene.get("player").call("teleport", pos)
					current_scene.get("companion").call("teleport", pos + Vector2(-34, 8))
					break
		"flash":   # a lightning flash now
			current_scene.get("_view").set("_next_lightning", 0.0)
		"card":   # the sheet of party dino #arg
			var bar: Node = current_scene.find_children("*", "PartyBar", true, false)[0]
			bar.call("_open_card", root.get_node("Game").get("party")[arg])
		"near":   # what Chloé could interact with around her
			var me: Node2D = current_scene.get("player")
			for n in get_nodes_in_group(&"interactable"):
				var d: float = (n as Node2D).global_position.distance_to(me.global_position)
				if d < 120.0:
					print("proche : ", n.name, " à %d px, visible=%s" % [d, (n as Node2D).visible])
			print("joueur occupé=", me.get("busy"), " dialogue=", root.get_node("Dialogue").get("active"), " router=", root.get_node("Router").call("is_busy"))
		"chipie":
			var ch: Node = current_scene.get("region").get_node("Entities").get_node_or_null("Chipie")
			if ch == null:
				print("Chipie : absente")
			else:
				print("Chipie : ", (ch.global_position / TILE).snapped(Vector2(0.1, 0.1)), " joueur occupé=", current_scene.get("player").get("busy"), " dialogue=", root.get_node("Dialogue").get("active"), " visible=", ch.visible, " physique=", ch.is_physics_processing(), " course=", ch.get("_running"), " points=", ch.get("waypoints").size())
		"talk":
			_talk = arg
		"map_island":
			_map_screen().call("_show_island")
		"map_zone":
			_map_screen().call("_show_zone", arg)
		"map_zoom":
			_map_screen().get("_map").call("zoom_by", arg)
		"map_goal":
			var goals: Array = load("res://story/objectives.gd").call("current")
			print("objectifs : ", goals.map(func(o: Dictionary) -> String: return o["text"]))
			if goals.size() > arg:
				root.get_node("Game").call("set_flag", &"suivi", goals[arg]["id"])
				_map_screen().call("_fill_objectives")
				_map_screen().call("_go_to", goals[arg])
		"tap_tracker":
			var tr: Control = current_scene.find_children("*", "QuestTracker", true, false)[0]
			var ev := InputEventMouseButton.new()
			ev.pressed = true
			ev.button_index = MOUSE_BUTTON_LEFT
			tr.call("_gui_input", ev)
		"proxies":
			var view: Node = current_scene.get("_view")
			for p: Dictionary in view.get("_proxies"):
				var src: Node = p["src"]
				if not is_instance_valid(src):
					continue
				if src.name in arg or (src.get("kind") != null and String(src.get("kind")).begins_with("maison")):
					var v: SpriteBase3D = p["vis"]
					print(src.name, " 2d=", src.global_position / TILE, " 3d=", v.global_position, " aabb=", v.get_aabb(), " offset=", v.offset, " px=", v.pixel_size, " alpha=", v.alpha_cut, " mod=", v.modulate, " vis=", v.visible)
		"shop_buy":
			for n in root.get_children():
				if n.has_method("_sell_tear"):
					n.call("_buy", arg)
		"shop_tab":
			for n in root.get_children():
				if n.has_method("_sell_tear"):
					var tabs: Array = n.get("_tabs")
					tabs[1 if arg else 0].emit_signal("pressed")
		"riding":
			var p: Node = current_scene.get("player")
			print("en selle : ", p.get("mount") != null, "  zone : ", root.get_node("Game").get("region_id"))
		"fight":
			current_scene.call("_battle", load("res://game/dino.gd").create(StringName(arg), 5))
		"item":
			root.get_node("Game").call("give_item", arg[0], arg[1])
		"coins":
			print("pièces : ", root.get_node("Game").call("coins"), "  objets : ", root.get_node("Game").get("items"))
		"gset":   # [property, value] on Game
			root.get_node("Game").set(arg[0], arg[1])
		"pebbles":   # the first `arg` amber pebbles of the Plaines found (test flags)
			for i in arg:
				root.get_node("Game").call("set_flag", StringName("galet_plaines_t%02d" % i))
		"egg":
			print("œuf : ", root.get_node("Game").get("egg"))
		"egg_steps":
			root.get_node("Game").get("egg")["steps"] = arg
		"give":
			root.get_node("Game").call("add_caught", load("res://game/dino.gd").create(StringName(arg), 6))
		"map":
			current_scene.call("_open_map")
		"vsync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if arg else DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = 0
		"perf":
			print("perf %s : %d im/s, %d appels de dessin, %d objets, %d k triangles" % [arg, Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000])
		"state":
			var game := root.get_node("Game")
			var zone: Node = current_scene.get("region")
			var wild := zone.get_node("Entities").get_children().filter(func(n: Node) -> bool: return n.has_signal("encountered"))
			print("zone=", game.get("region_id"), " moment=", game.call("phase"), " météo=", game.get("weather"), " pause=", paused, " dinos visibles=", wild.map(func(n: Node) -> String: return "%s niv.%s" % [n.get("species_id"), n.get("level_range")]),
				" jour=", game.get("day"), " heure=%.1f" % (float(game.get("clock")) / 60.0), " joueur=", (current_scene.get("player").global_position / TILE).round(), " fps=", Engine.get_frames_per_second(), " drapeaux=", game.get("flags").keys())
		"auto":
			_auto = arg
		"check":
			var game := root.get_node("Game")
			print("flags: ", game.get("flags"))
			var save := root.get_node("Save")
			print("save: ", save.call("save_game"), " load: ", save.call("load_game"), " flags après chargement: ", game.get("flags"))
			print("position sauvegardée: ", game.get("player_position"))
			print("galets trouvés : ", game.call("pebbles_found", "plaines"), "  baies : ", game.call("item_count", "baie"), "  jour : ", game.get("day"))
			var explored: Dictionary = game.get("explored")
			for id: String in explored:
				var seen: PackedByteArray = explored[id]
				print("carte %s après chargement : %d cases, %d vues" % [id, seen.size(), Array(seen).filter(func(v: int) -> bool: return v > 0).size()])


func _map_screen() -> Node:
	for n in root.get_children():
		if n.get_script() == load("res://ui/map_screen.gd"):
			return n
	return null


## Plays a battle by itself: first move when the menu is shown, otherwise taps.
func _auto_step() -> void:
	for n in current_scene.get_children():
		if n.has_signal("_action_chosen"):
			if n.get("_menu").visible:
				# A corrupted foe: calm it; otherwise the first move.
				var calm: bool = n.get("_calm_button").visible
				n.emit_signal("_action_chosen", {"type": "calm"} if calm else {"type": "move", "index": 0})
				return
	if root.get_node("Dialogue").get("_choosing"):
		_run("press", "ui_accept")
		return
	_run("press", "interact")
