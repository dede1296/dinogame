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
	# Sprite motion (world/view3d/sprite_motion.gd) on and off in turn, a banner says which.
	"foret_integ": [
		[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue"]], [0.85, "calm", 900.0], [0.86, "level", 14],
		[0.9, "zone", &"plaines"], [2.3, "tp", Vector2(3.0, 52.0)], [2.5, "hold", "move_left"], [3.4, "hold", ""], [3.5, "talk", true],
		[6.0, "shot", "i0_arrivee"], [22.0, "talk", false], [22.1, "state", null], [22.2, "tracker", null],
		[22.5, "tp", Vector2(23.4, 81.0)], [24.0, "shot", "i1_ravin"], [24.1, "hold", "move_left"], [24.2, "hold", ""], [24.4, "press", "interact"], [25.0, "auto", true],
		[30.0, "shot", "i2_griffe"], [70.0, "auto", false], [70.1, "state", null], [70.2, "tracker", null],
		[70.5, "tp", Vector2(24.0, 19.8)], [72.0, "hold", "move_up"], [72.1, "hold", ""], [72.3, "press", "interact"], [72.8, "auto", true],
		[76.0, "shot", "i3_clairiere"], [110.0, "auto", false], [110.1, "state", null], [110.2, "tracker", null], [110.3, "shot", "i4_fin"],
	],
	"griffe_ankylosaurus": [
		[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee"]], [0.85, "calm", 900.0],
		[0.86, "starter", "ankylosaurus"], [0.87, "dlog", true],
		[0.9, "zone", &"foret"], [2.5, "tp", Vector2(23.4, 81.0)], [3.8, "hold", "move_left"], [3.9, "hold", ""], [4.1, "press", "interact"], [4.6, "auto", true],
		[45.0, "auto", false], [45.1, "tracker", null],
	],
	"griffe_parasaurolophus": [
		[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee"]], [0.85, "calm", 900.0],
		[0.86, "starter", "parasaurolophus"], [0.87, "dlog", true],
		[0.9, "zone", &"foret"], [2.5, "tp", Vector2(23.4, 81.0)], [3.8, "hold", "move_left"], [3.9, "hold", ""], [4.1, "press", "interact"], [4.6, "auto", true],
		[45.0, "auto", false], [45.1, "tracker", null],
	],
	"etape2": [
		[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien"]], [0.9, "calm", 900.0], [0.9, "give", "pachycephalosaurus"], [1.0, "level", 18], [1.0, "dlog", true], [1.1, "zone", &"foret"], [1.6, "tp", Vector2(12, 42.2)], [1.9, "hold", "move_up"], [2.1, "hold", ""], [2.3, "shot", "e2_mur"], [2.4, "auto", true], [14.4, "auto", false], [14.6, "state", null], [14.7, "tracker", null], [15.0, "hold", "move_up"], [16.2, "hold", ""], [16.3, "auto", true], [38.3, "auto", false], [38.5, "state", null], [38.7, "shot", "e2_camp"], [39.2, "tp", Vector2(15, 18.2)], [39.5, "hold", "move_up"], [39.6, "hold", ""], [39.8, "shot", "e2_sbire1"], [39.9, "auto", true], [84.9, "auto", false], [85.1, "state", null], [85.2, "tracker", null], [85.7, "tp", Vector2(27, 18.2)], [86.0, "hold", "move_up"], [86.2, "hold", ""], [86.4, "shot", "e2_sbire2"], [86.5, "auto", true], [131.4, "auto", false], [131.6, "state", null], [131.7, "tracker", null], [132.2, "tp", Vector2(20, 12.2)], [132.5, "hold", "move_up"], [132.7, "hold", ""], [132.9, "shot", "e2_brac"], [133.0, "auto", true], [243.0, "auto", false], [243.2, "state", null], [243.3, "tracker", null], [243.8, "tp", Vector2(31, 9.2)], [244.1, "hold", "move_up"], [244.2, "hold", ""], [244.4, "shot", "e2_utah"], [244.5, "auto", true], [324.5, "auto", false], [324.7, "state", null], [324.8, "tracker", null], [325.3, "tp", Vector2(11, 9.2)], [325.6, "hold", "move_up"], [325.8, "hold", ""], [326.0, "shot", "e2_papiers"], [326.1, "auto", true], [351.1, "auto", false], [351.3, "state", null], [351.4, "tracker", null], [351.9, "zone", &"foret"], [353.5, "tp", Vector2(56.5, 78.5)], [353.8, "hold", "move_up"], [353.9, "hold", ""], [354.1, "shot", "e2_masque"], [354.3, "auto", true], [384.3, "auto", false], [384.4, "state", null], [384.6, "tracker", null], [385.1, "tp", Vector2(7.2, 12)], [385.4, "hold", "move_left"], [385.5, "hold", ""], [385.7, "shot", "e2_maia"], [385.8, "auto", true], [465.8, "auto", false], [466.0, "state", null], [466.1, "tracker", null], [466.6, "zone", &"cabinet"], [468.2, "tp", Vector2(4.35, 4.4)], [468.5, "hold", "move_up"], [468.7, "hold", ""], [468.9, "shot", "e2_tiroir"], [469.0, "auto", true], [499.0, "auto", false], [499.2, "state", null], [499.3, "tracker", null],
	],
	"etape2b": [
		[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "oeuf_vole_apaise", "cage_ouverte", "utah_lecon", "sceau_foret", "cages_ouvertes", "found_journal_11", "papiers_brac_lus", "masque_en_vue", "masque_vu"]], [0.9, "calm", 900.0], [0.9, "give", "pachycephalosaurus"], [1.0, "level", 18], [1.0, "dlog", true], [1.1, "zone", &"foret"], [2.6, "tp", Vector2(7.2, 12)], [2.9, "hold", "move_left"], [3.1, "hold", ""], [3.3, "shot", "e2m_maia"], [3.4, "auto", true], [103.3, "auto", false], [103.5, "state", null], [103.6, "tracker", null], [105.1, "tp", Vector2(7.2, 12)], [105.4, "hold", "move_left"], [105.6, "hold", ""], [105.8, "shot", "e2m_maia2"], [105.9, "auto", true], [205.9, "auto", false], [206.1, "state", null], [206.2, "tracker", null], [206.5, "shot", "e2m_maia_apres"],
	],
	"marais": [
		[0.8, "flags", ["sceau_plaines","maia_defi_1","found_journal_6","havre_arrive","selle","barque_vue","foret_arrivee","griffe_grise_vu","clairiere_vue","found_journal_ancien","mur_camp_brise","camp_arrive","sbire_camp_1_battu","sbire_camp_2_battu","brac_parle","brac_battu","oeuf_vole_apaise","cage_ouverte","sceau_foret","cages_ouvertes","found_journal_11","papiers_brac_lus","masque_en_vue","masque_vu","maia_pont_vue","maia_defi_2","roc_oeuf_retrouve","roc_sceau_foret","tiroir_flaire","ambre_noir_tiroir","found_journal_3","found_journal_4","found_journal_10"]], [0.8, "give", "parasaurolophus"], [0.8, "give", "pachycephalosaurus"], [0.9, "level", 19], [0.9, "item", ["collier", 10]], [0.9, "clock", 10.0], [0.9, "weather", &"clear"], [0.9, "dlog", true], [1.3, "zone", &"marais"], [2.9, "calm", 900.0], [3.0, "auto", true], [28.0, "auto", false], [28.2, "state", null], [28.3, "tracker", null], [28.7, "tp", Vector2(100, 68.5)], [29.0, "hold", "move_up"], [29.2, "hold", ""], [29.4, "shot", "m3_joss"], [29.5, "auto", true], [59.5, "auto", false], [59.7, "state", null], [59.8, "tracker", null], [60.2, "tp", Vector2(84, 42.4)], [60.5, "hold", "move_up"], [60.6, "hold", ""], [60.8, "shot", "m3_baryonyx"], [60.9, "auto", true], [130.9, "auto", false], [131.1, "state", null], [131.2, "tracker", null], [131.5, "give", "baryonyx"], [131.6, "level", 19], [131.7, "party", null], [132.1, "tp", Vector2(56, 43.35)], [132.4, "hold", "move_up"], [132.5, "hold", ""], [132.7, "shot", "m3_porte_voix"], [132.8, "auto", true], [144.8, "auto", false], [145.0, "state", null], [145.1, "tracker", null], [145.5, "tp", Vector2(56, 39.1)], [145.8, "hold", "move_up"], [146.0, "hold", ""], [146.2, "shot", "m3_voix"], [146.3, "auto", true], [196.3, "auto", false], [196.5, "state", null], [196.6, "tracker", null], [197.0, "tp", Vector2(26, 36.4)], [197.3, "hold", "move_up"], [197.4, "hold", ""], [197.6, "shot", "m3_dame_suie"], [197.7, "auto", true], [347.7, "auto", false], [347.9, "state", null], [348.0, "tracker", null], [348.4, "tp", Vector2(29.3, 35)], [348.7, "hold", "move_up"], [348.9, "hold", ""], [349.1, "shot", "m3_page13"], [349.2, "auto", true], [361.2, "auto", false], [361.4, "state", null], [361.5, "tracker", null], [361.9, "tp", Vector2(26, 75.4)], [362.2, "hold", "move_up"], [362.3, "hold", ""], [362.5, "shot", "m3_page14"], [362.6, "auto", true], [377.6, "auto", false], [377.8, "state", null], [377.9, "tracker", null], [378.3, "tp", Vector2(70, 73.5)], [378.6, "hold", "move_up"], [378.8, "hold", ""], [379.0, "shot", "m3_page15"], [379.1, "auto", true], [391.1, "auto", false], [391.3, "state", null], [391.4, "tracker", null], [391.8, "tp", Vector2(99.5, 23)], [392.0, "clock", 19.2], [392.1, "auto", true], [437.1, "auto", false], [437.3, "shot", "m3_roc_nuit"], [437.4, "state", null], [437.5, "tracker", null], [437.8, "gset", ["day", 2]], [437.9, "clock", 21.5], [438.3, "tp", Vector2(96, 86.6)], [438.6, "hold", "move_up"], [438.7, "hold", ""], [438.9, "shot", "m3_page16"], [439.0, "auto", true], [451.0, "auto", false], [451.2, "state", null], [451.3, "tracker", null], [451.6, "gset", ["day", 3]], [451.7, "clock", 10.0], [452.1, "tp", Vector2(30, 13.8)], [452.3, "shot", "m3_porte_temple"], [452.7, "zone", &"temple_englouti"], [454.3, "calm", 900.0], [454.4, "auto", true], [479.4, "auto", false], [479.6, "state", null], [479.7, "tracker", null], [480.1, "tp", Vector2(23.4, 16.5)], [480.4, "hold", "move_up"], [480.6, "hold", ""], [480.8, "shot", "m3_fresque1"], [480.9, "auto", true], [492.9, "auto", false], [493.1, "state", null], [493.2, "tracker", null], [493.6, "tp", Vector2(14.4, 18.5)], [493.9, "hold", "move_up"], [494.0, "hold", ""], [494.2, "shot", "m3_vanne1"], [494.3, "auto", true], [509.3, "auto", false], [509.5, "state", null], [509.6, "tracker", null], [510.0, "tp", Vector2(7.4, 6.4)], [510.3, "hold", "move_up"], [510.5, "hold", ""], [510.7, "shot", "m3_vanne2"], [510.8, "auto", true], [525.8, "auto", false], [526.0, "state", null], [526.1, "tracker", null], [526.5, "tp", Vector2(5.2, 3.5)], [526.8, "hold", "move_up"], [526.9, "hold", ""], [527.1, "shot", "m3_fresque2"], [527.2, "auto", true], [539.2, "auto", false], [539.4, "state", null], [539.5, "tracker", null], [539.9, "tp", Vector2(31.8, 6.4)], [540.2, "hold", "move_up"], [540.4, "hold", ""], [540.6, "shot", "m3_vanne3"], [540.7, "auto", true], [555.7, "auto", false], [555.9, "state", null], [556.0, "tracker", null], [556.4, "tp", Vector2(34.2, 3.5)], [556.7, "hold", "move_up"], [556.8, "hold", ""], [557.0, "shot", "m3_fresque3"], [557.1, "auto", true], [575.1, "auto", false], [575.3, "state", null], [575.4, "tracker", null], [575.8, "tp", Vector2(34.6, 13.8)], [576.1, "hold", "move_up"], [576.3, "hold", ""], [576.5, "shot", "m3_page12"], [576.6, "auto", true], [588.6, "auto", false], [588.8, "state", null], [588.9, "tracker", null], [589.3, "tp", Vector2(19.5, 7.7)], [589.6, "hold", "move_up"], [589.7, "hold", ""], [589.9, "shot", "m3_spinosaure"], [590.0, "auto", true], [760.0, "auto", false], [760.2, "state", null], [760.3, "tracker", null], [760.4, "party", null], [760.8, "zone", &"marais"], [762.4, "calm", 900.0], [762.5, "auto", true], [777.5, "auto", false], [777.7, "state", null], [777.8, "tracker", null], [778.2, "tp", Vector2(86, 6)], [778.5, "hold", "move_up"], [778.7, "hold", ""], [778.9, "shot", "m3_maia"], [779.0, "auto", true], [949.0, "auto", false], [949.2, "state", null], [949.3, "tracker", null], [949.7, "zone", &"cabinet"], [951.3, "calm", 900.0], [951.4, "auto", true], [971.4, "auto", false], [971.6, "state", null], [971.7, "tracker", null], [972.1, "tp", Vector2(6.5, 5.8)], [972.4, "hold", "move_up"], [972.5, "hold", ""], [972.7, "shot", "m3_roc_cabinet"], [972.8, "auto", true], [997.8, "auto", false], [998.0, "state", null], [998.1, "tracker", null],
	],
	"desert": [
		[0.8, "flags", ["sceau_plaines","maia_defi_1","found_journal_6","havre_arrive","selle","barque_vue","foret_arrivee","griffe_grise_vu","clairiere_vue","found_journal_ancien","mur_camp_brise","camp_arrive","sbire_camp_1_vu","sbire_camp_2_vu","sbire_camp_1_battu","sbire_camp_2_battu","brac_parle","brac_battu","cage_ouverte","sceau_foret","found_journal_11","papiers_brac_lus","masque_vu","maia_defi_2","ambre_noir_tiroir","marais_arrivee","joss_marais_vu","gilet_nage","porte_voix_ouverte","voix_rencontree","temple_ouvert","dame_suie_battue","temple_vanne_1","temple_vanne_2","temple_vanne_3","spinosaure_battu","sceau_marais","coeur_1","found_journal_12","found_journal_13","found_journal_14","found_journal_15","found_journal_16","roc_marais_vu","maia_defi_3"]], [0.8, "item", ["coeur_1", 1]], [0.8, "item", ["sceau_marais", 1]], [0.9, "item", ["sceau_foret", 1]], [0.9, "item", ["gilet_nage", 1]], [0.9, "item", ["baie", 10]], [0.9, "item", ["fougere", 4]], [1.0, "calm", 900.0], [1.0, "give", "compsognathus"], [1.1, "give", "protoceratops"], [1.1, "give", "baryonyx"], [1.2, "level", 24], [1.2, "clock", 10.0], [1.3, "weather", &"clear"], [1.3, "dlog", true], [1.4, "zone", &"desert"], [3.0, "shot", "d4_arrivee"], [3.1, "auto", true], [23.1, "auto", false], [23.3, "tracker", null], [23.8, "tp", Vector2(85.60, 68.80)], [24.1, "hold", "move_up"], [24.3, "hold", ""], [24.5, "shot", "d4_sirocco"], [24.6, "press", "interact"], [24.7, "auto", true], [74.7, "auto", false], [74.9, "state", null], [75.0, "tracker", null], [75.4, "tp_secret", "monticule"], [76.8, "hold", "move_up"], [76.9, "hold", ""], [77.1, "press", "interact"], [80.6, "shot", "d4_fossile_1"], [81.0, "tp_secret", "monticule"], [82.4, "hold", "move_up"], [82.5, "hold", ""], [82.7, "press", "interact"], [86.2, "shot", "d4_fossile_2"], [86.6, "tp_secret", "monticule"], [88.0, "hold", "move_up"], [88.1, "hold", ""], [88.3, "press", "interact"], [91.8, "shot", "d4_fossile_3"], [92.2, "tp_secret", "monticule"], [93.6, "hold", "move_up"], [93.7, "hold", ""], [93.9, "press", "interact"], [97.4, "shot", "d4_fossile_4"], [97.8, "tp_secret", "monticule"], [99.2, "hold", "move_up"], [99.3, "hold", ""], [99.5, "press", "interact"], [103.0, "shot", "d4_fossile_5"], [103.2, "flags", ["fossile_1","fossile_2","fossile_3","fossile_4","fossile_5"]], [103.7, "tp", Vector2(85.60, 68.80)], [104.0, "hold", "move_up"], [104.1, "hold", ""], [104.3, "shot", "d4_sirocco_cadeau"], [104.4, "press", "interact"], [104.5, "auto", true], [139.5, "auto", false], [139.7, "state", null], [139.8, "tracker", null], [140.3, "tp", Vector2(28.50, 60.50)], [140.6, "hold", "move_up"], [140.8, "hold", ""], [141.0, "shot", "d4_eboulis"], [141.1, "press", "interact"], [141.2, "auto", true], [153.2, "auto", false], [153.4, "state", null], [153.5, "tracker", null], [154.0, "tp", Vector2(20.50, 33.20)], [154.3, "hold", "move_up"], [154.4, "hold", ""], [154.6, "shot", "d4_vieux_rempart"], [154.7, "press", "interact"], [154.8, "auto", true], [214.8, "auto", false], [215.0, "state", null], [215.1, "tracker", null], [215.6, "tp", Vector2(60.50, 10.00)], [216.8, "shot", "d4_brac_porte"], [216.9, "auto", true], [276.9, "auto", false], [277.1, "state", null], [277.2, "tracker", null], [277.7, "tp", Vector2(45.00, 11.20)], [278.9, "shot", "d4_poursuite_1"], [279.0, "auto", true], [314.0, "auto", false], [314.2, "state", null], [314.3, "tracker", null], [314.8, "tp", Vector2(35.00, 15.00)], [316.0, "shot", "d4_poursuite_2"], [316.1, "auto", true], [351.1, "auto", false], [351.3, "state", null], [351.4, "tracker", null], [351.9, "tp", Vector2(25.50, 12.60)], [353.1, "shot", "d4_poursuite_3"], [353.2, "auto", true], [388.2, "auto", false], [388.4, "state", null], [388.5, "tracker", null], [388.7, "level", 24], [389.2, "tp", Vector2(15.50, 13.60)], [389.5, "hold", "move_up"], [389.7, "hold", ""], [389.9, "shot", "d4_brac"], [390.0, "press", "interact"], [390.1, "auto", true], [630.1, "auto", false], [630.3, "state", null], [630.4, "tracker", null], [630.7, "party", null], [631.2, "call", ["goto_zone", [&"sanctuaire_vents", &"DepuisDesert"]]], [633.0, "tp", Vector2(15.50, 9.20)], [633.3, "hold", "move_up"], [633.4, "hold", ""], [633.6, "shot", "d4_coeur"], [633.7, "press", "interact"], [633.8, "auto", true], [663.8, "auto", false], [664.0, "state", null], [664.1, "tracker", null], [664.6, "call", ["goto_zone", [&"desert", &"DepuisSanctuaire"]]], [666.4, "tp", Vector2(12.60, 9.40)], [666.7, "hold", "move_up"], [666.9, "hold", ""], [667.1, "shot", "d4_chariot"], [667.2, "press", "interact"], [667.3, "auto", true], [702.3, "auto", false], [702.5, "state", null], [702.6, "tracker", null], [702.8, "level", 24], [703.3, "tp", Vector2(93.20, 31.40)], [703.6, "hold", "move_up"], [703.7, "hold", ""], [703.9, "shot", "d4_maia"], [704.0, "press", "interact"], [704.1, "auto", true], [854.1, "auto", false], [854.3, "state", null], [854.4, "tracker", null], [854.6, "shot", "d4_fin"], [854.7, "check", null],
	],
	"desert2": [
		[0.8, "flags", ["sceau_plaines","maia_defi_1","found_journal_6","havre_arrive","selle","barque_vue","foret_arrivee","griffe_grise_vu","clairiere_vue","found_journal_ancien","mur_camp_brise","camp_arrive","sbire_camp_1_vu","sbire_camp_2_vu","sbire_camp_1_battu","sbire_camp_2_battu","brac_parle","brac_battu","cage_ouverte","sceau_foret","found_journal_11","papiers_brac_lus","masque_vu","maia_defi_2","ambre_noir_tiroir","marais_arrivee","joss_marais_vu","gilet_nage","porte_voix_ouverte","voix_rencontree","temple_ouvert","dame_suie_battue","temple_vanne_1","temple_vanne_2","temple_vanne_3","spinosaure_battu","sceau_marais","coeur_1","found_journal_12","found_journal_13","found_journal_14","found_journal_15","found_journal_16","roc_marais_vu","maia_defi_3"]], [0.8, "item", ["coeur_1", 1]], [0.8, "item", ["sceau_marais", 1]], [0.9, "item", ["sceau_foret", 1]], [0.9, "item", ["gilet_nage", 1]], [0.9, "item", ["baie", 10]], [0.9, "item", ["fougere", 4]], [1.0, "calm", 900.0], [1.0, "give", "compsognathus"], [1.1, "give", "protoceratops"], [1.1, "give", "baryonyx"], [1.2, "level", 24], [1.2, "clock", 10.0], [1.3, "weather", &"clear"], [1.3, "dlog", true], [1.4, "zone", &"desert"], [3.0, "shot", "d5_arrivee"], [3.1, "auto", true], [23.1, "auto", false], [23.3, "tracker", null], [23.5, "flags", ["sirocco_vue","fossile_1","fossile_2","fossile_3","fossile_4","fossile_5","fossiles_rendus","rempart_ouvert","rempart_rencontre","found_journal_17","found_journal_20"]], [24.0, "tp", Vector2(60.50, 10.00)], [25.2, "shot", "d5_brac_porte"], [25.3, "auto", true], [85.3, "auto", false], [85.5, "state", null], [85.6, "tracker", null], [86.1, "tp", Vector2(45.00, 11.20)], [87.3, "shot", "d5_poursuite_1"], [87.4, "auto", true], [127.4, "auto", false], [127.6, "state", null], [127.7, "tracker", null], [128.2, "tp", Vector2(35.00, 15.00)], [129.4, "shot", "d5_poursuite_2"], [129.5, "auto", true], [169.5, "auto", false], [169.7, "state", null], [169.8, "tracker", null], [170.3, "tp", Vector2(25.50, 12.60)], [171.5, "shot", "d5_poursuite_3"], [171.6, "auto", true], [211.6, "auto", false], [211.8, "state", null], [211.9, "tracker", null], [212.1, "level", 24], [212.6, "tp", Vector2(15.50, 13.60)], [212.9, "hold", "move_up"], [213.1, "hold", ""], [213.3, "shot", "d5_brac"], [213.4, "press", "interact"], [213.5, "auto", true], [413.5, "auto", false], [413.7, "state", null], [413.8, "tracker", null], [414.1, "party", null], [414.6, "tp", Vector2(19.40, 8.40)], [414.9, "hold", "move_left"], [415.0, "hold", ""], [415.2, "shot", "d5_carno"], [415.3, "press", "interact"], [415.4, "auto", true], [615.4, "auto", false], [615.6, "state", null], [615.7, "tracker", null], [616.0, "party", null], [616.5, "call", ["goto_zone", [&"sanctuaire_vents", &"DepuisDesert"]]], [618.3, "tp", Vector2(15.50, 9.20)], [618.6, "hold", "move_up"], [618.8, "hold", ""], [619.0, "shot", "d5_coeur"], [619.1, "press", "interact"], [619.2, "auto", true], [659.2, "auto", false], [659.4, "state", null], [659.5, "tracker", null], [660.0, "call", ["goto_zone", [&"desert", &"DepuisSanctuaire"]]], [661.8, "tp", Vector2(12.60, 9.40)], [662.1, "hold", "move_up"], [662.2, "hold", ""], [662.4, "shot", "d5_chariot"], [662.5, "press", "interact"], [662.6, "auto", true], [692.6, "auto", false], [692.8, "state", null], [692.9, "tracker", null], [693.1, "level", 24], [693.6, "tp", Vector2(93.20, 31.40)], [693.9, "hold", "move_up"], [694.1, "hold", ""], [694.3, "shot", "d5_maia"], [694.4, "press", "interact"], [694.5, "auto", true], [864.5, "auto", false], [864.7, "state", null], [864.8, "tracker", null], [865.1, "clock", 18.9], [865.2, "auto", true], [905.2, "auto", false], [905.4, "shot", "d5_crepuscule"], [905.5, "state", null], [905.6, "tracker", null],
	],
	"perf_regions": [
		[0.5, "flags", ["selle","sceau_plaines","maia_defi_1","havre_arrive"]], [0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [0.9, "vsync", false], [1.4, "zone", &"plaines"], [3.9, "weather", &"clear"], [4.2, "tp", Vector2(60, 47)], [7.2, "perf", "plaines/carrefour"], [7.4, "tp", Vector2(80, 42)], [10.4, "perf", "plaines/etang"], [10.9, "zone", &"foret"], [13.4, "weather", &"clear"], [13.7, "tp", Vector2(68, 52)], [16.7, "perf", "foret/sous_bois"], [16.9, "tp", Vector2(56.5, 77)], [19.9, "perf", "foret/passerelle"], [20.4, "zone", &"camp_ombre"], [22.9, "weather", &"clear"], [23.2, "tp", Vector2(20, 14)], [26.2, "perf", "camp_ombre/camp"], [26.7, "zone", &"marais"], [29.2, "weather", &"clear"], [29.5, "tp", Vector2(116, 70)], [32.5, "perf", "marais/arrivee"], [32.7, "tp", Vector2(84, 43)], [35.7, "perf", "marais/roseliere_est"], [35.9, "tp", Vector2(26, 76)], [38.9, "perf", "marais/foret_noyee"], [39.1, "tp", Vector2(99.5, 22)], [42.1, "perf", "marais/grand_ponton"], [42.3, "tp", Vector2(30, 15)], [45.3, "perf", "marais/parvis_temple"], [45.8, "zone", &"temple_englouti"], [48.3, "weather", &"clear"], [48.6, "tp", Vector2(19.5, 27)], [51.6, "perf", "temple_englouti/hall"], [51.8, "tp", Vector2(19.5, 9)], [54.8, "perf", "temple_englouti/grande_salle"], [55.3, "zone", &"desert"], [57.8, "weather", &"clear"], [58.1, "tp", Vector2(102, 94)], [61.1, "perf", "desert/entree"], [61.3, "tp", Vector2(74.5, 75)], [64.3, "perf", "desert/cimetiere"], [64.5, "tp", Vector2(60, 40)], [67.5, "perf", "desert/erg"], [67.7, "tp", Vector2(99, 33)], [70.7, "perf", "desert/oasis"], [70.9, "tp", Vector2(35, 15)], [73.9, "perf", "desert/canyon_vents"], [74.1, "tp", Vector2(60.5, 10)], [77.1, "perf", "desert/place_sanctuaire"], [77.6, "zone", &"sanctuaire_vents"], [80.1, "weather", &"clear"], [80.4, "tp", Vector2(15.5, 15)], [83.4, "perf", "sanctuaire_vents/salle"], [83.9, "zone", &"marais"], [86.4, "tp", Vector2(26, 76)], [86.6, "weather", &"rain"], [89.6, "perf", "marais/foret_noyee_pluie"], [89.8, "weather", &"mist"], [92.8, "perf", "marais/foret_noyee_brume"], [93.0, "quality", 0], [93.1, "vsync", false], [96.1, "perf", "marais/foret_noyee_brume_BASSE"], [96.3, "quality", 2], [96.4, "vsync", false], [99.4, "perf", "marais/foret_noyee_brume_HAUTE"], [99.6, "quality", 1], [99.7, "vsync", false], [100.2, "zone", &"desert"], [102.7, "tp", Vector2(74.5, 75)], [102.9, "weather", &"sandstorm"], [105.9, "perf", "desert/cimetiere_tempete"], [106.1, "quality", 0], [106.2, "vsync", false], [109.2, "perf", "desert/cimetiere_tempete_BASSE"], [109.4, "quality", 2], [109.5, "vsync", false], [112.5, "perf", "desert/cimetiere_tempete_HAUTE"], [112.7, "quality", 1], [112.8, "vsync", false],
	],
	"marais_echo": [
		[0.8, "flags", ["sceau_plaines","maia_defi_1","found_journal_6","havre_arrive","selle","barque_vue","foret_arrivee","griffe_grise_vu","clairiere_vue","found_journal_ancien","mur_camp_brise","camp_arrive","sbire_camp_1_battu","sbire_camp_2_battu","brac_parle","brac_battu","oeuf_vole_apaise","cage_ouverte","sceau_foret","cages_ouvertes","found_journal_11","papiers_brac_lus","masque_en_vue","masque_vu","maia_pont_vue","maia_defi_2","roc_oeuf_retrouve","roc_sceau_foret","tiroir_flaire","ambre_noir_tiroir","found_journal_3","found_journal_4","found_journal_10"]], [0.8, "starter", "parasaurolophus"], [0.8, "give", "velociraptor"], [0.9, "give", "pachycephalosaurus"], [0.9, "level", 19], [0.9, "item", ["collier", 10]], [0.9, "clock", 10.0], [0.9, "weather", &"clear"], [1.0, "dlog", true], [1.4, "zone", &"marais"], [3.0, "calm", 900.0], [3.1, "auto", true], [28.1, "auto", false], [28.3, "state", null], [28.4, "tracker", null], [28.8, "tp", Vector2(100, 68.5)], [29.1, "hold", "move_up"], [29.2, "hold", ""], [29.4, "shot", "e3_joss"], [29.5, "auto", true], [59.5, "auto", false], [59.7, "state", null], [59.8, "tracker", null], [60.2, "tp", Vector2(84, 42.4)], [60.5, "hold", "move_up"], [60.7, "hold", ""], [60.9, "shot", "e3_baryonyx"], [61.0, "auto", true], [131.0, "auto", false], [131.2, "state", null], [131.3, "tracker", null], [131.6, "give", "baryonyx"], [131.6, "level", 19], [131.7, "party", null], [132.1, "tp", Vector2(56, 43.35)], [132.4, "hold", "move_up"], [132.6, "hold", ""], [132.8, "shot", "e3_porte_voix"], [132.9, "auto", true], [144.9, "auto", false], [145.1, "state", null], [145.2, "tracker", null], [145.6, "tp", Vector2(56, 39.1)], [145.9, "hold", "move_up"], [146.0, "hold", ""], [146.2, "shot", "e3_voix"], [146.3, "auto", true], [196.3, "auto", false], [196.5, "state", null], [196.6, "tracker", null], [197.0, "tp", Vector2(26, 36.4)], [197.3, "hold", "move_up"], [197.5, "hold", ""], [197.7, "shot", "e3_dame_suie"], [197.8, "auto", true], [347.8, "auto", false], [348.0, "state", null], [348.1, "tracker", null], [348.5, "tp", Vector2(29.3, 35)], [348.8, "hold", "move_up"], [348.9, "hold", ""], [349.1, "shot", "e3_page13"], [349.2, "auto", true], [361.2, "auto", false], [361.4, "state", null], [361.5, "tracker", null], [361.9, "tp", Vector2(26, 75.4)], [362.2, "hold", "move_up"], [362.4, "hold", ""], [362.6, "shot", "e3_page14"], [362.7, "auto", true], [377.7, "auto", false], [377.9, "state", null], [378.0, "tracker", null], [378.4, "tp", Vector2(70, 73.5)], [378.7, "hold", "move_up"], [378.8, "hold", ""], [379.0, "shot", "e3_page15"], [379.1, "auto", true], [391.1, "auto", false], [391.3, "state", null], [391.4, "tracker", null], [391.8, "tp", Vector2(99.5, 23)], [392.0, "clock", 19.2], [392.1, "auto", true], [437.1, "auto", false], [437.3, "shot", "e3_roc_nuit"], [437.4, "state", null], [437.5, "tracker", null], [437.8, "gset", ["day", 2]], [437.9, "clock", 21.5], [438.3, "tp", Vector2(96, 86.6)], [438.6, "hold", "move_up"], [438.8, "hold", ""], [439.0, "shot", "e3_page16"], [439.1, "auto", true], [451.1, "auto", false], [451.3, "state", null], [451.4, "tracker", null], [451.7, "gset", ["day", 3]], [451.8, "clock", 10.0], [452.2, "tp", Vector2(30, 13.8)], [452.4, "shot", "e3_porte_temple"], [452.8, "zone", &"temple_englouti"], [454.4, "calm", 900.0], [454.5, "auto", true], [479.5, "auto", false], [479.7, "state", null], [479.8, "tracker", null], [480.2, "tp", Vector2(23.4, 16.5)], [480.5, "hold", "move_up"], [480.6, "hold", ""], [480.8, "shot", "e3_fresque1"], [480.9, "auto", true], [492.9, "auto", false], [493.1, "state", null], [493.2, "tracker", null], [493.6, "tp", Vector2(14.4, 18.5)], [493.9, "hold", "move_up"], [494.1, "hold", ""], [494.3, "shot", "e3_vanne1"], [494.4, "auto", true], [509.4, "auto", false], [509.6, "state", null], [509.7, "tracker", null], [510.1, "tp", Vector2(7.4, 6.4)], [510.4, "hold", "move_up"], [510.5, "hold", ""], [510.7, "shot", "e3_vanne2"], [510.8, "auto", true], [525.8, "auto", false], [526.0, "state", null], [526.1, "tracker", null], [526.5, "tp", Vector2(5.2, 3.5)], [526.8, "hold", "move_up"], [527.0, "hold", ""], [527.2, "shot", "e3_fresque2"], [527.3, "auto", true], [539.3, "auto", false], [539.5, "state", null], [539.6, "tracker", null], [540.0, "tp", Vector2(31.8, 6.4)], [540.3, "hold", "move_up"], [540.4, "hold", ""], [540.6, "shot", "e3_vanne3"], [540.7, "auto", true], [555.7, "auto", false], [555.9, "state", null], [556.0, "tracker", null], [556.4, "tp", Vector2(34.2, 3.5)], [556.7, "hold", "move_up"], [556.9, "hold", ""], [557.1, "shot", "e3_fresque3"], [557.2, "auto", true], [575.2, "auto", false], [575.4, "state", null], [575.5, "tracker", null], [575.9, "tp", Vector2(34.6, 13.8)], [576.2, "hold", "move_up"], [576.3, "hold", ""], [576.5, "shot", "e3_page12"], [576.6, "auto", true], [588.6, "auto", false], [588.8, "state", null], [588.9, "tracker", null], [589.3, "tp", Vector2(19.5, 7.7)], [589.6, "hold", "move_up"], [589.8, "hold", ""], [590.0, "shot", "e3_spinosaure"], [590.1, "auto", true], [760.1, "auto", false], [760.3, "state", null], [760.4, "tracker", null], [760.5, "party", null], [760.9, "zone", &"marais"], [762.5, "calm", 900.0], [762.6, "auto", true], [777.6, "auto", false], [777.8, "state", null], [777.9, "tracker", null], [778.3, "tp", Vector2(86, 6)], [778.6, "hold", "move_up"], [778.7, "hold", ""], [778.9, "shot", "e3_maia"], [779.0, "auto", true], [949.0, "auto", false], [949.2, "state", null], [949.3, "tracker", null], [949.7, "zone", &"cabinet"], [951.3, "calm", 900.0], [951.4, "auto", true], [971.4, "auto", false], [971.6, "state", null], [971.7, "tracker", null], [972.1, "tp", Vector2(6.5, 5.8)], [972.4, "hold", "move_up"], [972.6, "hold", ""], [972.8, "shot", "e3_roc_cabinet"], [972.9, "auto", true], [997.9, "auto", false], [998.1, "state", null], [998.2, "tracker", null],
	],
	"desert_bastion": [
		[0.8, "flags", ["sceau_plaines","maia_defi_1","found_journal_6","havre_arrive","selle","barque_vue","foret_arrivee","griffe_grise_vu","clairiere_vue","found_journal_ancien","mur_camp_brise","camp_arrive","sbire_camp_1_vu","sbire_camp_2_vu","sbire_camp_1_battu","sbire_camp_2_battu","brac_parle","brac_battu","cage_ouverte","sceau_foret","found_journal_11","papiers_brac_lus","masque_vu","maia_defi_2","ambre_noir_tiroir","marais_arrivee","joss_marais_vu","gilet_nage","porte_voix_ouverte","voix_rencontree","temple_ouvert","dame_suie_battue","temple_vanne_1","temple_vanne_2","temple_vanne_3","spinosaure_battu","sceau_marais","coeur_1","found_journal_12","found_journal_13","found_journal_14","found_journal_15","found_journal_16","roc_marais_vu","maia_defi_3"]], [0.8, "item", ["coeur_1", 1]], [0.8, "item", ["sceau_marais", 1]], [0.9, "item", ["sceau_foret", 1]], [0.9, "item", ["gilet_nage", 1]], [0.9, "item", ["baie", 10]], [0.9, "item", ["fougere", 4]], [1.0, "calm", 900.0], [1.0, "give", "compsognathus"], [1.1, "give", "protoceratops"], [1.1, "give", "baryonyx"], [1.2, "level", 24], [1.2, "clock", 10.0], [1.3, "weather", &"clear"], [1.3, "dlog", true], [1.4, "zone", &"desert"], [3.0, "shot", "d6_arrivee"], [3.1, "auto", true], [23.1, "auto", false], [23.3, "tracker", null], [23.5, "flags", ["sirocco_vue","fossile_1","fossile_2","fossile_3","fossile_4","fossile_5","fossiles_rendus","found_journal_17"]], [23.6, "starter", "ankylosaurus"], [23.6, "level", 24], [24.1, "tp", Vector2(28.50, 60.50)], [24.4, "hold", "move_up"], [24.6, "hold", ""], [24.8, "shot", "d6_eboulis"], [24.9, "press", "interact"], [25.0, "auto", true], [37.0, "auto", false], [37.2, "state", null], [37.3, "tracker", null], [37.8, "tp", Vector2(20.50, 33.20)], [38.1, "hold", "move_up"], [38.2, "hold", ""], [38.4, "shot", "d6_vieux_rempart"], [38.5, "press", "interact"], [38.6, "auto", true], [108.6, "auto", false], [108.8, "state", null], [108.9, "tracker", null], [109.4, "tp", Vector2(60.50, 10.00)], [110.6, "shot", "d6_brac_porte"], [110.7, "auto", true], [170.7, "auto", false], [170.9, "state", null], [171.0, "tracker", null], [171.5, "tp", Vector2(45.00, 11.20)], [172.7, "shot", "d6_poursuite_1"], [172.8, "auto", true], [212.8, "auto", false], [213.0, "state", null], [213.1, "tracker", null], [213.6, "tp", Vector2(35.00, 15.00)], [214.8, "shot", "d6_poursuite_2"], [214.9, "auto", true], [254.9, "auto", false], [255.1, "state", null], [255.2, "tracker", null], [255.7, "tp", Vector2(25.50, 12.60)], [256.9, "shot", "d6_poursuite_3"], [257.0, "auto", true], [297.0, "auto", false], [297.2, "state", null], [297.3, "tracker", null], [297.5, "level", 24], [298.0, "tp", Vector2(15.50, 13.60)], [298.3, "hold", "move_up"], [298.5, "hold", ""], [298.7, "shot", "d6_brac"], [298.8, "press", "interact"], [298.9, "auto", true], [498.9, "auto", false], [499.1, "state", null], [499.2, "tracker", null], [499.5, "party", null], [500.0, "tp", Vector2(19.40, 8.40)], [500.3, "hold", "move_left"], [500.4, "hold", ""], [500.6, "shot", "d6_carno"], [500.7, "press", "interact"], [500.8, "auto", true], [700.8, "auto", false], [701.0, "state", null], [701.1, "tracker", null], [701.4, "party", null], [701.9, "call", ["goto_zone", [&"sanctuaire_vents", &"DepuisDesert"]]], [703.7, "tp", Vector2(15.50, 9.20)], [704.0, "hold", "move_up"], [704.2, "hold", ""], [704.4, "shot", "d6_coeur"], [704.5, "press", "interact"], [704.6, "auto", true], [744.6, "auto", false], [744.8, "state", null], [744.9, "tracker", null], [745.4, "call", ["goto_zone", [&"desert", &"DepuisSanctuaire"]]], [747.2, "tp", Vector2(12.60, 9.40)], [747.5, "hold", "move_up"], [747.6, "hold", ""], [747.8, "shot", "d6_chariot"], [747.9, "press", "interact"], [748.0, "auto", true], [778.0, "auto", false], [778.2, "state", null], [778.3, "tracker", null], [778.5, "level", 24], [779.0, "tp", Vector2(93.20, 31.40)], [779.3, "hold", "move_up"], [779.5, "hold", ""], [779.7, "shot", "d6_maia"], [779.8, "press", "interact"], [779.9, "auto", true], [949.9, "auto", false], [950.1, "state", null], [950.2, "tracker", null], [950.5, "clock", 18.9], [950.6, "auto", true], [990.6, "auto", false], [990.8, "shot", "d6_crepuscule"], [990.9, "state", null], [991.0, "tracker", null],
	],
	"visuels": [
		[0.8, "flags", ["selle","sceau_plaines","maia_defi_1","havre_arrive","maia_defi_2","marais_arrivee","gilet_nage","temple_arrive"]], [0.9, "calm", 900.0], [0.9, "item", ["gilet_nage", 1]], [1.0, "give", "baryonyx"], [1.0, "level", 16], [1.1, "clock", 11.0], [1.1, "weather", &"clear"], [1.3, "zone", &"marais"], [3.3, "tp", Vector2(70, 60)], [3.7, "hold", "move_left"], [4.9, "shot", "v_nage_left"], [5.0, "hold", ""], [5.4, "hold", "move_down"], [6.6, "shot", "v_nage_down"], [6.7, "hold", ""], [7.1, "hold", "move_right"], [8.3, "shot", "v_nage_right"], [8.4, "hold", ""], [8.8, "hold", "move_up"], [10.0, "shot", "v_nage_up"], [10.1, "hold", ""], [10.4, "state", null], [10.9, "zone", &"temple_englouti"], [12.9, "tp", Vector2(15.5, 20.2)], [13.2, "hold", "move_left"], [13.4, "hold", ""], [14.2, "shot", "v_crue_pleine"], [14.4, "flags", ["temple_vanne_1"]], [15.6, "shot", "v_crue_baisse"], [19.1, "shot", "v_crue_vide"], [19.4, "tp", Vector2(20.5, 16.5)], [20.4, "shot", "v_escalier_noye"], [20.6, "flags", ["temple_vanne_3"]], [21.9, "shot", "v_escalier_baisse"], [25.4, "shot", "v_escalier_sec"],
	],
	"demo_nuit": [
		[0.85, "flags", ["sceau_plaines","maia_defi_1","found_journal_6","havre_arrive","selle","barque_vue","foret_arrivee","griffe_grise_vu","clairiere_vue","found_journal_ancien"]], [0.90, "calm", 900.0], [0.95, "give", "pachycephalosaurus"], [1.00, "level", 18], [1.05, "item", ["collier",10]], [1.10, "clock", 10.0], [1.15, "weather", &"clear"], [1.20, "dlog", true], [1.25, "demo", true], [1.30, "auto", true], [1.35, "fast_battles", true], [1.65, "zone", &"foret"], [3.65, "banner", ""], [4.25, "segment", ["Chapitre 2 · La Forêt Jurassique (fin)","Le mur fissuré : Coup de crâne"]], [4.55, "tp", Vector2(12, 42.2)], [4.75, "hold", "move_up"], [4.87, "hold", ""], [5.17, "interact_now", null], [5.27, "wait_idle", [1.5, 240]], [5.87, "segment", ["Chapitre 2 · La Forêt Jurassique (fin)","Derrière le mur : le camp de l'Ombre Noire"]], [6.17, "hold", "move_up"], [7.57, "hold", ""], [7.67, "wait_idle", [2, 90]], [8.27, "segment", ["Chapitre 2 · La Forêt Jurassique (fin)","Brac, et le petit volé au Cabinet : on l'apaise"]], [8.32, "flags", ["sceau_plaines","maia_defi_1","found_journal_6","havre_arrive","selle","barque_vue","foret_arrivee","griffe_grise_vu","clairiere_vue","found_journal_ancien","mur_camp_brise","camp_arrive","sbire_camp_1_vu","sbire_camp_2_vu","sbire_camp_1_battu","sbire_camp_2_battu"]], [8.62, "tp", Vector2(20, 12.2)], [8.82, "hold", "move_up"], [8.94, "hold", ""], [9.24, "interact_now", null], [9.34, "wait_idle", [1.5, 240]], [9.94, "segment", ["Chapitre 2 · La Forêt Jurassique (fin)","Le chef de meute : un long apaisement, puis le Sceau de la Forêt"]], [9.99, "flags", ["brac_parle","brac_battu","oeuf_vole_apaise"]], [10.29, "tp", Vector2(31, 9.2)], [10.49, "hold", "move_up"], [10.61, "hold", ""], [10.91, "interact_now", null], [11.01, "wait_idle", [1.5, 240]], [11.61, "segment", ["Chapitre 2 · La Forêt Jurassique (fin)","Sur la passerelle des géants : le Masque d'Obsidienne"]], [11.66, "flags", ["cage_ouverte","utah_lecon","sceau_foret","cages_ouvertes","papiers_brac_lus","found_journal_11"]], [11.96, "zone", &"foret"], [12.06, "wait_idle", [2, 90]], [12.36, "tp", Vector2(56.5, 77.6)], [12.46, "wait_idle", [2, 120]], [13.06, "segment", ["Chapitre 2 · La Forêt Jurassique (fin)","Au pont du Marais : le défi n° 2 de Maïa"]], [13.11, "flags", ["masque_en_vue","masque_vu"]], [13.16, "level", 18], [13.46, "tp", Vector2(7.2, 12)], [13.66, "hold", "move_left"], [13.78, "hold", ""], [14.08, "interact_now", null], [14.18, "wait_idle", [1.5, 240]], [14.78, "segment", ["Chapitre 2 · La Forêt Jurassique (fin)","Au Cabinet : ce que Roc cache dans son tiroir"]], [14.83, "flags", ["maia_pont_vue","maia_defi_2"]], [15.13, "zone", &"cabinet"], [15.23, "wait_idle", [2, 90]], [15.53, "tp", Vector2(4.35, 4.4)], [15.73, "hold", "move_up"], [15.85, "hold", ""], [16.15, "interact_now", null], [16.25, "wait_idle", [1.5, 240]], [16.85, "segment", ["Chapitre 3 · Le Marais Brumeux","L'arrivée dans la brume"]], [16.90, "flags", ["roc_oeuf_retrouve","roc_sceau_foret","tiroir_flaire","ambre_noir_tiroir"]], [16.95, "level", 19], [17.00, "clock", 10.0], [17.30, "zone", &"marais"], [17.40, "wait_idle", [2, 90]], [18.00, "segment", ["Chapitre 3 · Le Marais Brumeux","Joss, sellier et inventeur de gilets de nage"]], [18.30, "tp", Vector2(100, 68.5)], [18.50, "hold", "move_up"], [18.62, "hold", ""], [18.92, "interact_now", null], [19.02, "wait_idle", [1.5, 240]], [19.62, "segment", ["Chapitre 3 · Le Marais Brumeux","Le Baryonyx chapardeur et le gilet de nage"]], [19.92, "tp", Vector2(84, 42.4)], [20.12, "hold", "move_up"], [20.24, "hold", ""], [20.54, "interact_now", null], [20.64, "wait_idle", [1.5, 240]], [21.24, "segment", ["Chapitre 3 · Le Marais Brumeux","La Nage : dans l'eau profonde, sur le dos d'un Baryonyx"]], [21.29, "give", "baryonyx"], [21.34, "level", 19], [21.64, "tp", Vector2(73, 60)], [22.04, "hold", "move_left"], [24.24, "hold", "move_up"], [25.84, "hold", ""], [26.44, "segment", ["Chapitre 3 · Le Marais Brumeux","La porte d'ambre, et la Voix du Marais"]], [26.74, "tp", Vector2(56, 43.3)], [26.94, "hold", "move_up"], [27.06, "hold", ""], [27.36, "interact_now", null], [27.46, "wait_idle", [1.5, 240]], [27.76, "tp", Vector2(56, 39.1)], [27.96, "hold", "move_up"], [28.08, "hold", ""], [28.38, "interact_now", null], [28.48, "wait_idle", [1.5, 240]], [29.08, "segment", ["Chapitre 3 · Le Marais Brumeux","Dame Suie, la chimiste de l'Ombre Noire"]], [29.38, "tp", Vector2(26, 36.4)], [29.58, "hold", "move_up"], [29.70, "hold", ""], [30.00, "interact_now", null], [30.10, "wait_idle", [1.5, 240]], [30.40, "tp", Vector2(29.3, 35)], [30.60, "hold", "move_up"], [30.72, "hold", ""], [31.02, "interact_now", null], [31.12, "wait_idle", [1.5, 240]], [31.72, "segment", ["Chapitre 3 · Le Marais Brumeux","La nuit, une lanterne sur les pontons…"]], [31.77, "flags", ["found_journal_14","found_journal_15"]], [32.07, "tp", Vector2(99.5, 23)], [32.37, "clock", 19.2], [32.47, "wait_idle", [3, 150]], [33.07, "segment", ["Chapitre 3 · Le Marais Brumeux","Le temple englouti : fresques, vannes et crues"]], [33.12, "clock", 10.0], [33.42, "zone", &"temple_englouti"], [33.52, "wait_idle", [2, 90]], [33.82, "tp", Vector2(23.4, 16.5)], [34.02, "hold", "move_up"], [34.14, "hold", ""], [34.44, "interact_now", null], [34.54, "wait_idle", [1.5, 240]], [34.84, "tp", Vector2(14.4, 18.5)], [35.04, "hold", "move_up"], [35.16, "hold", ""], [35.46, "interact_now", null], [35.56, "wait_idle", [1.5, 240]], [36.16, "segment", ["Chapitre 3 · Le Marais Brumeux","Le Spinosaure Ancestral, le Sceau et le premier Cœur"]], [36.21, "flags", ["temple_vanne_2","temple_vanne_3","fresque_2_vue","fresque_3_vue","found_journal_12"]], [36.51, "tp", Vector2(19.5, 7.7)], [36.71, "hold", "move_up"], [36.83, "hold", ""], [37.13, "interact_now", null], [37.23, "wait_idle", [1.5, 240]], [37.83, "segment", ["Chapitre 3 · Le Marais Brumeux","Dans la roselière du nord : le défi n° 3 de Maïa"]], [38.13, "zone", &"marais"], [38.23, "wait_idle", [2, 90]], [38.28, "level", 20], [38.58, "tp", Vector2(86, 6)], [38.78, "hold", "move_up"], [38.90, "hold", ""], [39.20, "interact_now", null], [39.30, "wait_idle", [1.5, 240]], [39.90, "segment", ["Chapitre 4 · Le Désert Aride","L'arrivée, et Tante Sirocco"]], [39.95, "give", "compsognathus"], [40.00, "give", "protoceratops"], [40.05, "level", 24], [40.35, "zone", &"desert"], [40.45, "wait_idle", [2, 90]], [40.75, "tp", Vector2(85.6, 68.8)], [40.95, "hold", "move_up"], [41.07, "hold", ""], [41.37, "interact_now", null], [41.47, "wait_idle", [1.5, 240]], [42.07, "segment", ["Chapitre 4 · Le Désert Aride","Les fossiles du Cimetière des Géants (Flair)"]], [42.37, "tp_secret", "monticule"], [43.77, "hold", "move_up"], [43.87, "hold", ""], [44.07, "interact_now", null], [44.17, "wait_idle", [1, 20]], [44.22, "flags", ["fossile_1","fossile_2","fossile_3","fossile_4","fossile_5"]], [44.52, "tp", Vector2(85.6, 68.8)], [44.72, "hold", "move_up"], [44.84, "hold", ""], [45.14, "interact_now", null], [45.24, "wait_idle", [1.5, 240]], [45.84, "segment", ["Chapitre 4 · Le Désert Aride","L'éboulis (Charge), et le Vieux Rempart"]], [46.14, "tp", Vector2(28.5, 60.5)], [46.34, "hold", "move_up"], [46.46, "hold", ""], [46.76, "interact_now", null], [46.86, "wait_idle", [1.5, 240]], [47.16, "tp", Vector2(20.5, 33.2)], [47.36, "hold", "move_up"], [47.48, "hold", ""], [47.78, "interact_now", null], [47.88, "wait_idle", [1.5, 240]], [48.48, "segment", ["Chapitre 4 · Le Désert Aride","Brac au sanctuaire des Vents, et la tempête de sable"]], [48.78, "tp", Vector2(60.5, 10)], [48.88, "wait_idle", [2, 150]], [49.48, "segment", ["Chapitre 4 · Le Désert Aride","La poursuite dans le canyon des Vents"]], [49.78, "tp", Vector2(45, 11.2)], [49.88, "wait_idle", [1.5, 90]], [50.18, "tp", Vector2(35, 15)], [50.28, "wait_idle", [1.5, 90]], [50.58, "tp", Vector2(25.5, 12.6)], [50.68, "wait_idle", [1.5, 90]], [51.28, "segment", ["Chapitre 4 · Le Désert Aride","Brac acculé, puis le Carnotaurus Rouge apaisé"]], [51.33, "level", 24], [51.63, "tp", Vector2(15.5, 13.6)], [51.83, "hold", "move_up"], [51.95, "hold", ""], [52.25, "interact_now", null], [52.35, "wait_idle", [1.5, 240]], [52.65, "tp", Vector2(19.4, 8.4)], [52.85, "hold", "move_left"], [52.97, "hold", ""], [53.27, "interact_now", null], [53.37, "wait_idle", [1.5, 240]], [53.97, "segment", ["Chapitre 4 · Le Désert Aride","Dans le sanctuaire : le deuxième Cœur"]], [54.27, "call", ["goto_zone",[&"sanctuaire_vents",&"DepuisDesert"]]], [54.37, "wait_idle", [2, 90]], [54.67, "tp", Vector2(15.5, 9.2)], [54.87, "hold", "move_up"], [54.99, "hold", ""], [55.29, "interact_now", null], [55.39, "wait_idle", [1.5, 240]], [55.99, "segment", ["Chapitre 4 · Le Désert Aride","À l'oasis : le défi n° 4 de Maïa, puis le crépuscule"]], [56.29, "call", ["goto_zone",[&"desert",&"DepuisSanctuaire"]]], [56.39, "wait_idle", [2, 60]], [56.44, "level", 25], [56.74, "tp", Vector2(93.2, 31.4)], [56.94, "hold", "move_up"], [57.06, "hold", ""], [57.36, "interact_now", null], [57.46, "wait_idle", [1.5, 240]], [57.76, "clock", 18.9], [57.86, "wait_idle", [3, 90]], [58.46, "segment", ["Fin de la démo","La suite : la Côte Préhistorique"]], [65.46, "banner", ""],
	],
	"test_utah": [
		[0.80, "flags", ["sceau_plaines","maia_defi_1","found_journal_6","havre_arrive","selle","foret_arrivee","griffe_grise_vu","clairiere_vue","found_journal_ancien","mur_camp_brise","camp_arrive","sbire_camp_1_battu","sbire_camp_2_battu","brac_parle","brac_battu","oeuf_vole_apaise"]], [0.85, "calm", 900.0], [0.90, "give", "pachycephalosaurus"], [0.95, "level", 18], [1.00, "dlog", true], [1.05, "demo", true], [1.10, "auto", true], [1.15, "fast_battles", true], [1.45, "zone", &"camp_ombre"], [3.95, "tp", Vector2(31, 9.2)], [4.15, "hold", "move_up"], [4.27, "hold", ""], [4.77, "shot", "u0"], [5.07, "interact_now", null], [5.32, "shot", "u1"], [5.82, "shot", "u2"], [6.92, "shot", "u3"], [8.92, "shot", "u4"], [11.92, "shot", "u5"], [12.02, "wait_idle", [1.5, 200]], [12.52, "shot", "u9"],
	],
	"demo_live": [
		[0.85, "calm", 900.0], [0.9, "motion", true], [0.95, "tp", Vector2(58.4, 60.0)], [2, "banner", "Pas plus rapides, un rebond par pas"], [2.1, "tp", Vector2(58.4, 60.0)], [2.4, "hold", "move_down"], [3.8, "hold", ""], [4.4, "hold", "move_left"], [5.4, "hold", ""], [6, "hold", "move_right"], [7, "hold", ""], [7.6, "hold", "move_up"], [9, "hold", ""], [11, "banner", "Pas plus rapides, un rebond par pas"], [11.1, "tp", Vector2(58.4, 60.0)], [11.4, "hold", "move_down"], [12.8, "hold", ""], [13.4, "hold", "move_left"], [14.4, "hold", ""], [15, "hold", "move_right"], [16, "hold", ""], [16.6, "hold", "move_up"], [18, "hold", ""], [20, "banner", "Pas plus rapides, un rebond par pas"], [20.1, "tp", Vector2(58.4, 60.0)], [20.4, "hold", "move_down"], [21.8, "hold", ""], [22.4, "hold", "move_left"], [23.4, "hold", ""], [24, "hold", "move_right"], [25, "hold", ""], [25.6, "hold", "move_up"], [27, "hold", ""], [29, "banner", "Pas plus rapides, un rebond par pas"], [29.1, "tp", Vector2(58.4, 60.0)], [29.4, "hold", "move_down"], [30.8, "hold", ""], [31.4, "hold", "move_left"], [32.4, "hold", ""], [33, "hold", "move_right"], [34, "hold", ""], [34.6, "hold", "move_up"], [36, "hold", ""], [38, "banner", "Pas plus rapides, un rebond par pas"], [38.1, "tp", Vector2(58.4, 60.0)], [38.4, "hold", "move_down"], [39.8, "hold", ""], [40.4, "hold", "move_left"], [41.4, "hold", ""], [42, "hold", "move_right"], [43, "hold", ""], [43.6, "hold", "move_up"], [45, "hold", ""], [47, "banner", "Pas plus rapides, un rebond par pas"], [47.1, "tp", Vector2(58.4, 60.0)], [47.4, "hold", "move_down"], [48.8, "hold", ""], [49.4, "hold", "move_left"], [50.4, "hold", ""], [51, "hold", "move_right"], [52, "hold", ""], [52.6, "hold", "move_up"], [54, "hold", ""], [56, "banner", ""],
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
	# The Forêt Jurassique: in by the Plaines' west trail (saddle), its places, page 10 at full
	# moon, the map, the frame rate at each quality, a battle on its backdrop.
	"foret": [
		[0.8, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee"]], [0.82, "level", 14],
		[0.84, "clock", 11.0], [0.86, "weather", &"clear"], [0.9, "calm", 900.0], [0.95, "talk", true],
		[1.0, "tp", Vector2(5.0, 52.0)], [2.4, "shot", "f00_plaines_ouest"], [2.5, "hold", "move_left"], [3.8, "hold", ""],
		[5.4, "state", null], [5.5, "shot", "f01_arrivee"], [5.6, "calm", 900.0], [5.7, "weather", &"clear"],
		[5.8, "tp", Vector2(119.0, 53.5)], [7.2, "shot", "f02_lisiere"],
		[7.3, "tp", Vector2(118.5, 44.0)], [8.7, "shot", "f03_mare_de_lune"],
		[8.8, "tp", Vector2(68.5, 55.4)], [10.2, "shot", "f04_page7"],
		[10.3, "tp", Vector2(62.5, 57.5)], [11.7, "shot", "f05_carrefour"],
		[11.8, "tp", Vector2(63.5, 28.5)], [13.2, "shot", "f06_passerelle_nord"],
		[13.3, "tp", Vector2(46.5, 28.5)], [14.7, "shot", "f07_clairiere_page9"],
		[14.8, "tp", Vector2(24.0, 23.5)], [16.2, "shot", "f08_clairiere_fougeres"],
		[16.3, "tp", Vector2(95.0, 25.5)], [17.7, "shot", "f09_rocheuses"],
		[17.8, "tp", Vector2(81.0, 61.5)], [19.2, "shot", "f10_rampe_nord"],
		[19.3, "tp", Vector2(70.5, 86.0)], [20.7, "shot", "f11_futaie_page8"],
		[20.8, "tp", Vector2(44.5, 58.0)], [22.2, "shot", "f12_passerelle_ouest"],
		[22.3, "tp", Vector2(31.5, 62.0)], [23.7, "shot", "f13_entree_ravin"],
		[23.8, "tp", Vector2(24.0, 83.5)], [25.2, "shot", "f14_griffe_grise"],
		[25.3, "tp", Vector2(14.0, 47.0)], [26.7, "shot", "f15_face_du_camp"],
		[26.8, "tp", Vector2(116.0, 72.0)], [28.2, "shot", "f16_prairie"], [28.3, "state", null],
		[28.4, "gset", ["day", 2]], [28.5, "clock", 22.0], [28.6, "tp", Vector2(118.5, 43.0)], [31.0, "shot", "f17_page10_pleine_lune"],
		[31.1, "near", null], [31.2, "clock", 11.0], [31.3, "gset", ["day", 3]],
		[31.5, "map", null], [32.4, "shot", "f18_carte"], [32.5, "press", "cancel"],
		[33.0, "vsync", false], [33.05, "quality", 1], [33.1, "tp", Vector2(62.5, 57.5)], [36.0, "perf", "carrefour_moyenne"],
		[36.1, "quality", 2], [39.0, "perf", "carrefour_haute"], [39.1, "quality", 0], [42.0, "perf", "carrefour_basse"],
		[42.1, "quality", 1], [42.2, "tp", Vector2(70.5, 86.0)], [45.0, "perf", "futaie_moyenne"],
		[45.1, "tp", Vector2(119.0, 53.5)], [48.0, "perf", "lisiere_moyenne"], [48.1, "state", null],
		[48.2, "fight", "dilophosaurus"], [51.5, "shot", "f19_combat"],
	],
	# The way into the Forêt closed without a saddle; the ramps of the Haute futaie; rain and
	# mist under the trees; Griffe-Grise, the empty clearing and page 7 (the story's scenes).
	"foret2": [
		[0.8, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1"]], [0.82, "level", 14],
		[0.84, "clock", 11.0], [0.86, "weather", &"clear"], [0.9, "calm", 900.0],
		[1.0, "tp", Vector2(3.0, 52.0)], [1.5, "hold", "move_left"], [2.4, "hold", ""], [3.2, "shot", "g00_foret_fermee"], [3.3, "state", null],
		[3.4, "talk", true], [6.0, "talk", false], [6.1, "flags", ["selle", "foret_arrivee"]],
		[6.2, "tp", Vector2(3.0, 52.0)], [6.4, "hold", "move_left"], [7.4, "hold", ""], [9.0, "state", null],
		[9.1, "calm", 900.0], [9.2, "weather", &"clear"],
		[9.3, "tp", Vector2(81.0, 71.5)], [10.8, "shot", "g01_rampe_nord_haut"],
		[10.9, "tp", Vector2(41.5, 79.5)], [12.4, "shot", "g02_rampe_ouest"],
		[12.5, "tp", Vector2(113.0, 88.0)], [14.0, "shot", "g03_rampe_est"],
		[14.1, "tp", Vector2(68.5, 56.0)], [14.2, "weather", &"rain"], [19.0, "shot", "g04_sous_bois_pluie"],
		[19.1, "weather", &"mist"], [24.0, "shot", "g05_sous_bois_brume"], [24.1, "weather", &"clear"],
		[24.2, "talk", true], [24.3, "tp", Vector2(68.5, 53.7)], [25.0, "hold", "move_up"], [25.1, "hold", ""], [25.3, "press", "interact"],
		[26.2, "shot", "g06_page7"], [32.0, "state", null],
		[32.1, "tp", Vector2(22.4, 81.3)], [33.0, "hold", "move_up"], [33.1, "hold", ""], [33.3, "press", "interact"],
		[34.5, "shot", "g07_griffe_grise"], [50.0, "state", null],
		[50.1, "tp", Vector2(24.0, 19.9)], [51.0, "hold", "move_up"], [51.1, "hold", ""], [51.3, "press", "interact"],
		[52.5, "shot", "g08_clairiere_vide"], [66.0, "state", null], [66.1, "shot", "g09_apres"],
	],
	# The Forêt, step 2 (the map): the cracked wall in its notch (closed, then broken), the
	# Masque on the futaie's footbridge, the bridge to the Marais and Maïa, the map, the scene of
	# the Masque's circle, Roc's drawer in the Cabinet.
	"foret_pont": [
		[0.8, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee", "maia_defi_1"]],
		[0.82, "level", 16], [0.84, "clock", 11.0], [0.86, "weather", &"clear"], [0.9, "zone", &"foret"],
		[2.4, "calm", 900.0], [2.45, "weather", &"clear"],
		[2.5, "tp", Vector2(13.6, 44.6)], [3.9, "shot", "p00_baie_mur"],
		[4.0, "tp", Vector2(12.0, 42.0)], [4.1, "hold", "move_up"], [4.25, "hold", ""], [4.5, "press", "interact"],
		[5.6, "shot", "p01_mur_bloque"], [5.7, "near", null], [5.8, "talk", true], [10.9, "talk", false],
		[11.0, "flags", ["mur_camp_brise"]], [11.1, "zone", &"foret"], [12.6, "calm", 900.0], [12.7, "tp", Vector2(12.6, 43.4)],
		[14.1, "shot", "p02_tunnel_ouvert"],
		[14.2, "flags", ["masque_en_vue"]], [14.3, "zone", &"foret"], [15.8, "calm", 900.0], [15.9, "tp", Vector2(56.5, 77.2)],
		[17.3, "shot", "p03_passerelle_masque"], [17.4, "tp", Vector2(49.0, 76.6)], [18.8, "shot", "p04_passerelle_loin"],
		[18.9, "vsync", false], [19.0, "quality", 1], [21.5, "perf", "passerelle_moyenne"],
		[21.6, "flags", ["sceau_foret", "meute_revenue"]], [21.7, "zone", &"foret"], [23.2, "calm", 900.0], [23.3, "tp", Vector2(9.5, 13.2)],
		[24.8, "shot", "p05_pont_maia"], [27.0, "perf", "pont_moyenne"],
		[27.1, "tp", Vector2(3.0, 12.0)], [28.5, "shot", "p06_sur_le_pont"], [28.6, "hold", "move_left"], [29.4, "hold", ""],
		[30.4, "shot", "p07_pont_bloque"], [30.5, "state", null], [30.6, "talk", true], [34.6, "talk", false], [34.7, "near", null],
		[34.8, "map", null], [35.6, "shot", "p08_carte"], [35.7, "press", "cancel"],
		[36.0, "dlog", true], [36.1, "tp", Vector2(53.0, 77.0)], [37.5, "hold", "move_right"], [38.3, "hold", ""],
		[40.0, "shot", "p09_scene_masque"], [40.1, "talk", true], [43.0, "shot", "p10_scene_masque_2"], [55.0, "talk", false], [55.1, "state", null],
		[55.2, "zone", &"cabinet"], [57.0, "tp", Vector2(4.35, 4.3)], [57.1, "hold", "move_up"], [57.2, "hold", ""], [57.4, "near", null],
		[57.5, "press", "interact"], [58.6, "shot", "p11_tiroir"], [58.7, "talk", true], [65.0, "talk", false], [65.1, "state", null],
	],
	# The camp of the Ombre Noire (camp_ombre): its places, by day and by night, the frame rate at
	# each quality, its map, the way back to the Forêt.
	"camp": [
		[0.8, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee", "maia_defi_1",
			"mur_camp_brise", "camp_arrive"]],
		[0.82, "level", 16], [0.84, "clock", 11.0], [0.86, "weather", &"clear"], [0.9, "zone", &"camp_ombre"],
		[2.5, "weather", &"clear"], [2.6, "shot", "c00_entree"], [2.7, "state", null],
		[2.8, "tp", Vector2(26.0, 14.5)], [4.2, "shot", "c01_centre"],
		[4.3, "tp", Vector2(20.0, 13.2)], [5.7, "shot", "c02_brac"],
		[5.8, "tp", Vector2(31.0, 10.0)], [7.2, "shot", "c03_utahraptor"], [7.3, "near", null],
		[7.4, "tp", Vector2(11.0, 10.2)], [8.8, "shot", "c04_table"], [8.9, "near", null],
		[9.0, "tp", Vector2(8.0, 15.0)], [10.4, "shot", "c05_ouest"],
		[10.5, "tp", Vector2(21.0, 19.5)], [11.9, "shot", "c06_sud"],
		[12.0, "clock", 22.0], [12.1, "tp", Vector2(22.0, 14.0)], [14.0, "shot", "c07_nuit"],
		[14.1, "clock", 11.0], [14.2, "vsync", false], [14.3, "quality", 1], [17.0, "perf", "camp_moyenne"],
		[17.1, "quality", 2], [20.0, "perf", "camp_haute"], [20.1, "quality", 0], [23.0, "perf", "camp_basse"], [23.1, "quality", 1],
		[23.2, "map", null], [24.0, "shot", "c08_carte"], [24.1, "press", "cancel"],
		[24.5, "tp", Vector2(37.5, 14.0)], [24.6, "hold", "move_right"], [26.0, "hold", ""], [28.0, "state", null], [28.1, "shot", "c09_retour_foret"],
	],
	# The first time in the camp (its arrival scene, story/foret_camp.gd).
	"camp_arrivee": [
		[0.8, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee", "maia_defi_1", "mur_camp_brise"]],
		[0.82, "level", 16], [0.84, "clock", 11.0], [0.86, "weather", &"clear"], [0.87, "dlog", true], [0.9, "zone", &"camp_ombre"],
		[1.0, "talk", true], [4.0, "shot", "a0_arrivee"], [9.0, "shot", "a1_arrivee"], [16.0, "shot", "a2_arrivee"], [24.0, "state", null], [24.1, "shot", "a3_apres"],
	],
	# The Marais Brumeux (CARTE-B): its places on foot, then swimming (vest + Baryonyx), in the mist, at night, its map, a battle.
	# The Marais Brumeux (CARTE-B): its places on foot, then swimming (vest + Baryonyx), in the mist, at night, its map, a battle.
	"marais_tour": [
		[0.80, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee", "maia_defi_1", "sceau_foret", "maia_defi_2", "meute_revenue", "marais_arrivee", "joss_marais_vu"]], [0.82, "level", 16], [0.84, "clock", 11.0], [0.86, "weather", &"clear"], [0.88, "talk", true], [0.93, "zone", &"marais"], [2.53, "weather", &"clear"], [2.63, "tp", Vector2(115, 70.4)], [2.68, "calm", 900.0], [4.18, "shot", "m00_arrivee_ponton"], [4.28, "tp", Vector2(99.5, 69.8)], [4.33, "calm", 900.0], [5.83, "shot", "m01_debarcadere_joss"], [5.93, "tp", Vector2(97.9, 60)], [5.98, "calm", 900.0], [7.48, "shot", "m02_ponton_vers_roselieres"], [7.58, "tp", Vector2(85.5, 44.6)], [7.63, "calm", 900.0], [9.13, "shot", "m03_baryonyx_gilet"], [9.23, "tp", Vector2(100.5, 41.5)], [9.28, "calm", 900.0], [10.78, "shot", "m04_roseliere_est_feu"], [10.88, "tp", Vector2(99.9, 26)], [10.93, "calm", 900.0], [12.43, "shot", "m05_grand_ponton"], [12.53, "tp", Vector2(86, 9.5)], [12.58, "calm", 900.0], [14.08, "shot", "m06_roseliere_nord_sortie"], [14.18, "tp", Vector2(96, 89.4)], [14.23, "calm", 900.0], [15.73, "shot", "m07_bassin_nenuphars"], [15.83, "flags", ["gilet_nage"]], [15.85, "item", ["gilet_nage", 1]], [15.87, "give", "baryonyx"], [15.89, "level", 16], [15.99, "tp", Vector2(80.0, 66.0)], [16.29, "hold", "move_left"], [17.49, "hold", ""], [18.09, "shot", "m08_nage_chenal"], [18.14, "state", null], [18.24, "tp", Vector2(70, 74.8)], [18.29, "calm", 900.0], [19.79, "shot", "m09_page15_banc"], [19.89, "tp", Vector2(56, 46)], [19.94, "calm", 900.0], [21.44, "shot", "m10_voix_porte"], [21.54, "tp", Vector2(26, 40)], [21.59, "calm", 900.0], [23.09, "shot", "m11_ilot_racines"], [23.19, "tp", Vector2(35, 77.2)], [23.24, "calm", 900.0], [24.74, "shot", "m12_foret_noyee"], [24.84, "tp", Vector2(27, 77)], [24.89, "calm", 900.0], [26.39, "shot", "m13_page14"], [26.49, "tp", Vector2(30, 15.6)], [26.54, "calm", 900.0], [28.04, "shot", "m14_temple_parvis"], [28.14, "tp", Vector2(44, 34)], [28.19, "calm", 900.0], [29.69, "shot", "m15_coeur_roseliere"], [29.89, "map", null], [30.89, "shot", "m16_carte"], [30.99, "press", "cancel"], [31.49, "weather", &"mist"], [31.59, "tp", Vector2(100, 70)], [31.64, "calm", 900.0], [37.64, "shot", "m17_brume_debarcadere"], [37.74, "weather", &"rain"], [37.84, "tp", Vector2(56, 46)], [37.89, "calm", 900.0], [42.89, "shot", "m18_pluie_voix"], [42.99, "weather", &"clear"], [43.04, "clock", 22.0], [43.14, "tp", Vector2(99.9, 26)], [43.19, "calm", 900.0], [48.19, "shot", "m19_nuit_grand_ponton"], [48.29, "clock", 11.0], [48.39, "fight", "baryonyx"], [51.59, "shot", "m20_combat"],
	],
	# The sunken temple (CARTE-B): the hall and its flooded stairs, the three sluices draining the floods in turn, the galleries, the great hall, a battle.
	# The sunken temple (CARTE-B): the hall and its flooded stairs, the three sluices draining the floods in turn, the galleries, the great hall, a battle.
	"temple_tour": [
		[0.80, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee", "maia_defi_1", "sceau_foret", "maia_defi_2", "meute_revenue", "marais_arrivee", "joss_marais_vu"]], [0.82, "flags", ["gilet_nage", "temple_ouvert", "porte_voix_ouverte", "voix_rencontree"]], [0.84, "give", "baryonyx"], [0.86, "level", 18], [0.88, "clock", 11.0], [0.90, "talk", true], [0.95, "zone", &"temple_englouti"], [2.75, "shot", "t00_entree"], [2.85, "tp", Vector2(16.5, 20.6)], [2.90, "calm", 900.0], [4.40, "shot", "t01_hall_vanne1"], [4.50, "flags", ["temple_vanne_1"]], [5.70, "shot", "t02_crue1_baisse"], [8.20, "shot", "t03_crue1_vide"], [8.30, "tp", Vector2(4.8, 14)], [8.35, "calm", 900.0], [9.85, "shot", "t04_galerie_ouest"], [9.95, "tp", Vector2(5.2, 5.8)], [10.00, "calm", 900.0], [11.50, "shot", "t05_salle_nord_ouest"], [11.60, "flags", ["temple_vanne_2"]], [11.70, "tp", Vector2(25, 20.4)], [11.75, "calm", 900.0], [15.25, "shot", "t06_passage_est_seche"], [15.35, "tp", Vector2(34.6, 15.2)], [15.40, "calm", 900.0], [16.90, "shot", "t07_galerie_est_page12"], [17.00, "tp", Vector2(34.2, 5.8)], [17.05, "calm", 900.0], [18.55, "shot", "t08_salle_nord_est"], [18.65, "tp", Vector2(19.9, 17.2)], [18.75, "calm", 900.0], [19.95, "shot", "t09_escalier_inonde"], [20.05, "flags", ["temple_vanne_3"]], [21.35, "shot", "t10_escalier_baisse"], [23.75, "shot", "t11_escalier_sec"], [23.85, "tp", Vector2(19.9, 10.2)], [23.90, "calm", 900.0], [25.40, "shot", "t12_grande_salle"], [25.50, "fight", "spinosaurus"], [28.70, "shot", "t13_combat"],
	],
	# The Marais (CARTE-B): the seam with the Forêt from both sides, page 16 at full moon, Maïa, Roc at night, the Voix behind her opened door, page 13, the temple's door opening.
	"marais_lieux": [
		[0.80, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee", "maia_defi_1", "sceau_foret", "maia_defi_2", "meute_revenue", "marais_arrivee", "joss_marais_vu"]], [0.82, "level", 16], [0.84, "clock", 11.0], [0.86, "weather", &"clear"], [0.88, "talk", true], [0.93, "zone", &"foret"], [2.53, "weather", &"clear"], [2.63, "tp", Vector2(5.5, 12.4)], [2.68, "calm", 900.0], [4.18, "shot", "l00_foret_pont_vers_marais"], [4.28, "zone", &"marais"], [5.88, "weather", &"clear"], [5.98, "tp", Vector2(113.5, 70.3)], [6.03, "calm", 900.0], [7.53, "shot", "l01_marais_couture_foret"], [7.63, "flags", ["gilet_nage", "porte_voix_ouverte", "dame_suie_battue", "sceau_marais", "roc_marais_en_vue"]], [7.65, "give", "baryonyx"], [7.67, "level", 16], [7.77, "zone", &"marais"], [9.37, "weather", &"clear"], [9.47, "tp", Vector2(86.4, 8.6)], [9.52, "calm", 900.0], [11.02, "shot", "l02_maia_nord"], [11.12, "tp", Vector2(56.2, 40.6)], [11.17, "calm", 900.0], [12.67, "shot", "l03_voix_rampe"], [12.77, "tp", Vector2(56.6, 38.9)], [12.82, "calm", 900.0], [14.32, "shot", "l04_voix_rocher"], [14.42, "tp", Vector2(29.6, 36.6)], [14.47, "calm", 900.0], [15.97, "shot", "l05_page13_racines"], [16.07, "tp", Vector2(30.1, 13.2)], [16.12, "calm", 900.0], [17.62, "shot", "l06_temple_porte_fermee"], [17.72, "flags", ["temple_ouvert"]], [18.32, "shot", "l07_temple_porte_s_ouvre"], [19.92, "shot", "l08_temple_porte_ouverte"], [20.02, "gset", ["day", 2]], [20.07, "clock", 22.0], [20.12, "weather", &"clear"], [20.22, "tp", Vector2(99.9, 23.2)], [20.27, "calm", 900.0], [23.27, "shot", "l09_nuit_roc_ponton"], [23.32, "weather", &"clear"], [23.42, "tp", Vector2(96.1, 87.6)], [23.47, "calm", 900.0], [26.47, "shot", "l10_pleine_lune_page16"], [26.57, "near", null],
	],
	# The Désert Aride (CARTE-C): the seam with the Marais, its places, Brac at the dead end, a sandstorm, the night, its map, a battle; the Carnotaurus, the door open, Maïa.
	# The Désert Aride (CARTE-C): the seam with the Marais, its places, Brac at the dead end, a sandstorm, the night, its map, a battle; the Carnotaurus, the door open, Maïa.
	# The Désert Aride (CARTE-C): the seam with the Marais, its places, Brac at the dead end, a sandstorm, the night, its map, a battle; the Carnotaurus, the door open, Maïa.
	# The Désert Aride (CARTE-C): the seam with the Marais, its places, Brac at the dead end, a sandstorm, the night, its map, a battle; the Carnotaurus, the door open, Maïa.
	"desert_tour": [
		[0.80, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee", "maia_defi_1", "sceau_foret", "maia_defi_2", "meute_revenue", "marais_arrivee", "joss_marais_vu", "gilet_nage", "sceau_marais", "coeur_1", "maia_defi_3", "desert_arrivee", "sirocco_vue", "brac_desert_vu", "poursuite_1_ok", "poursuite_2_ok", "poursuite_3_ok"]], [0.82, "level", 24], [0.84, "give", "pinacosaurus"], [0.86, "level", 24], [0.88, "clock", 11.0], [0.90, "weather", &"clear"], [0.92, "talk", true], [1.02, "zone", &"marais"], [2.62, "weather", &"clear"], [2.72, "tp", Vector2(86, 4.5)], [2.77, "calm", 900.0], [4.27, "shot", "d00_marais_vers_desert"], [4.37, "zone", &"desert"], [5.97, "weather", &"clear"], [6.07, "tp", Vector2(102, 95)], [6.12, "calm", 900.0], [7.62, "shot", "d01_entree"], [7.72, "tp", Vector2(101, 85)], [7.77, "calm", 900.0], [9.27, "shot", "d02_canyon_entree"], [9.37, "tp", Vector2(87.5, 71.5)], [9.42, "calm", 900.0], [10.92, "shot", "d03_sirocco"], [11.02, "tp", Vector2(74.5, 75)], [11.07, "calm", 900.0], [12.57, "shot", "d04_cimetiere_crane"], [12.67, "tp", Vector2(65, 80)], [12.72, "calm", 900.0], [14.22, "shot", "d05_squelette_arche"], [14.32, "tp", Vector2(79, 93.2)], [14.37, "calm", 900.0], [15.87, "shot", "d06_lac_de_sel"], [15.97, "tp", Vector2(28.5, 63)], [16.02, "calm", 900.0], [17.52, "shot", "d07_eboulis"], [17.62, "tp", Vector2(21.5, 37.5)], [17.67, "calm", 900.0], [19.17, "shot", "d08_canyon_mure"], [19.27, "tp", Vector2(66, 44)], [19.32, "calm", 900.0], [20.82, "shot", "d09_erg"], [20.92, "tp", Vector2(60.5, 11.5)], [20.97, "calm", 900.0], [22.47, "shot", "d10_place_porte"], [22.57, "tp", Vector2(41, 13.6)], [22.62, "calm", 900.0], [24.12, "shot", "d11_canyon_vents"], [24.22, "tp", Vector2(15, 14.8)], [24.27, "calm", 900.0], [25.77, "shot", "d12_cul_de_sac_brac"], [25.87, "tp", Vector2(98, 37.5)], [25.92, "calm", 900.0], [27.42, "shot", "d13_oasis"], [27.52, "tp", Vector2(103, 16)], [27.57, "calm", 900.0], [29.07, "shot", "d14_grande_dune"], [29.17, "tp", Vector2(100, 5)], [29.22, "calm", 900.0], [30.72, "shot", "d15_sortie_cote"], [30.92, "map", null], [31.92, "shot", "d16_carte"], [32.02, "press", "cancel"], [32.32, "weather", &"sandstorm"], [32.42, "tp", Vector2(74.5, 75)], [32.47, "calm", 900.0], [40.47, "shot", "d17_tempete_cimetiere"], [40.57, "tp", Vector2(41, 13.6)], [40.62, "calm", 900.0], [42.62, "shot", "d18_tempete_canyon"], [42.72, "weather", &"clear"], [42.77, "clock", 22.0], [42.87, "tp", Vector2(60.5, 11.5)], [42.92, "calm", 900.0], [47.92, "shot", "d19_nuit_place"], [48.02, "tp", Vector2(98, 37.5)], [48.07, "calm", 900.0], [50.07, "shot", "d20_nuit_oasis"], [50.17, "clock", 11.0], [50.27, "fight", "pinacosaurus"], [53.47, "shot", "d21_combat"], [53.57, "auto", true], [67.57, "auto", false], [68.07, "flags", ["brac_desert_battu"]], [68.17, "zone", &"desert"], [69.77, "weather", &"clear"], [69.87, "tp", Vector2(16.5, 12.6)], [69.92, "calm", 900.0], [71.42, "shot", "d22_carnotaurus_cul_de_sac"], [71.52, "flags", ["carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert"]], [71.62, "zone", &"desert"], [73.22, "weather", &"clear"], [73.32, "tp", Vector2(60.5, 9)], [73.37, "calm", 900.0], [74.87, "shot", "d23_porte_ouverte_gardien"], [74.97, "tp", Vector2(94, 34)], [75.02, "calm", 900.0], [76.52, "shot", "d24_maia_oasis"], [76.62, "state", null],
	],
	# The sanctuary des Vents (CARTE-C): the corridor, the round hall, the altar, page 18, its map, the night, the way back out to the door.
	# The sanctuary des Vents (CARTE-C): the corridor, the round hall, the altar, page 18, its map, the night, the way back out to the door.
	# The sanctuary des Vents (CARTE-C): the corridor, the round hall, the altar, page 18, its map, the night, the way back out to the door.
	# The sanctuary des Vents (CARTE-C): the corridor, the round hall, the altar, page 18, its map, the night, the way back out to the door.
	"sanctuaire_tour": [
		[0.80, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee", "maia_defi_1", "sceau_foret", "maia_defi_2", "meute_revenue", "marais_arrivee", "joss_marais_vu", "gilet_nage", "sceau_marais", "coeur_1", "maia_defi_3", "desert_arrivee", "sirocco_vue", "brac_desert_vu", "poursuite_1_ok", "poursuite_2_ok", "poursuite_3_ok"]], [0.82, "flags", ["brac_desert_battu", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre"]], [0.84, "level", 24], [0.86, "clock", 11.0], [0.88, "talk", true], [0.98, "zone", &"sanctuaire_vents"], [2.58, "weather", &"clear"], [2.68, "shot", "s00_arrivee"], [2.78, "tp", Vector2(15.5, 19)], [2.83, "calm", 900.0], [4.33, "shot", "s01_couloir"], [4.43, "tp", Vector2(15.5, 14)], [4.48, "calm", 900.0], [5.98, "shot", "s02_salle"], [6.08, "tp", Vector2(15.5, 10.5)], [6.13, "calm", 900.0], [7.63, "shot", "s03_autel"], [7.73, "tp", Vector2(21, 7.5)], [7.78, "calm", 900.0], [9.28, "shot", "s04_page18"], [9.48, "map", null], [10.48, "shot", "s05_carte"], [10.58, "press", "cancel"], [10.68, "clock", 22.0], [10.78, "tp", Vector2(15.5, 13)], [10.83, "calm", 900.0], [14.83, "shot", "s06_nuit"], [14.93, "clock", 11.0], [15.03, "tp", Vector2(15.5, 22.4)], [15.13, "hold", "move_down"], [16.53, "hold", ""], [18.33, "weather", &"clear"], [18.83, "shot", "s07_retour_porte"], [18.93, "state", null],
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
var _dlog := false
var _dlog_last := ""
var _talk := false
var _talk_timer := 0.0
var _auto_timer := 0.0
var _quality_before := -1
var _pick := -1
## The live demo (command "demo"): the scenario's own clock, which stands still while it is
## paused (P) or while a scene plays ("wait_idle"); N hurries the current scene and goes on to
## the next part ("segment"); the lines stay on screen long enough to be read.
var _demo := false
var _sched := 0.0
var _paused := false
var _wait := {}
var _turbo := false
var _line_seen := ""
var _line_at := 0.0
var _menu_at := -1.0
var _fast_battles := false
var _fast_engine: Object = null
var _hud_taps: Array = []   # (command "hud_tap")
var _keys := {}
var _pause_layer: CanvasLayer
var _rush := false   # (command line « rush=1 »: the demo at full speed, to check it)


func _initialize() -> void:
	var scenario := "walk"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("scenario="):
			scenario = arg.substr(9)
		elif arg == "rush=1":
			_rush = true
		elif arg.begins_with("scenario_file="):   # a scenario of its own file: const STEPS := [...]
			scenario = arg.substr(14)
	_steps = SCENARIOS[scenario] if SCENARIOS.has(scenario) else (load(scenario) as Script).get_script_constant_map()["STEPS"]
	# Never over the player's game: the tool saves in a file of its own.
	root.get_node("Save").set("path", "user://capture_save.json")
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
	if _demo:
		_demo_keys()
		if _paused:
			return false
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
	if _dlog:
		var box = root.get_node("Dialogue").get("_text")
		if box and box.text != _dlog_last and box.visible_characters == -1:
			_dlog_last = box.text
			print("» ", box.text)
	if _auto:
		_auto_timer += delta
		if _auto_timer > (0.1 if _turbo or _rush else 0.35):
			_auto_timer = 0.0
			_auto_step()
	if _wait.is_empty():
		_sched += delta
	else:
		_check_wait(delta)
	while _step < _steps.size() and _sched >= _steps[_step][0] and _wait.is_empty():
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
		"hold_also":   # [action, pressed]: a second action held with the one of "hold" (B to run)
			if arg[1]:
				Input.action_press(StringName(arg[0]))
			else:
				Input.action_release(StringName(arg[0]))
		"where":   # Chloé's position (tiles), to measure a speed
			var p: Node2D = current_scene.get("player")
			print("where ", arg, " : ", p.global_position / 48.0, " t=", Time.get_ticks_msec())
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
			world.get("companion").call("stand_beside", pos)
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
		"motion":
			load("res://world/view3d/sprite_motion.gd").set("enabled", arg)
		"pose":   # [pose, secs]: Chloé holds a pose drawn for her (Stage.pose; "": back on her feet)
			print("pose ", arg, " : ", load("res://story/stage.gd").call("pose", current_scene.get("player"), StringName(arg[0]), float(arg[1])))
		"dress":   # [name, look]: someone of the zone (node name) in another look (Stage.dress; "": as usual)
			var who: Node = current_scene.get("region").get_node("Entities").find_child(String(arg[0]), true, false)
			print("tenue ", arg, " : ", load("res://story/stage.gd").call("dress", who, StringName(arg[1])))
		"static":   # [script, function, args…]: a staging helper called directly (a visual check without playing its scene);
			# "@Name" = a node of the zone (the last one «static» made, when named so), "@player" = Chloé, a Vector2 = cells
			var args: Array = []
			for a in (arg as Array).slice(2):
				if a is String and (a as String).begins_with("@"):
					var node_name := (a as String).substr(1)
					args.append(current_scene.get("player") if node_name == "player" else current_scene.get("region").get_node("Entities").find_child(node_name, true, false))
				elif a is Vector2:
					args.append((a as Vector2) * 48.0)   # (Story.CELL)
				else:
					args.append(a)
			print("static ", arg[1], " : ", load(String(arg[0])).callv(String(arg[1]), args))
		"face":   # a direction (Vector2): Chloé turns that way
			var p: Node2D = current_scene.get("player")
			p.call("face_towards", p.global_position + (arg as Vector2) * 10.0)
		"demo":   # the live demo mode (see _demo): its help line, its pace
			_demo = arg
			_demo_help()
		"no_help":   # the demo's pace without its help line (clean screenshots)
			var help := root.get_node_or_null("DemoHelp")
			if help:
				help.queue_free()
		"segment":   # a part of the demo: [chapter, title], shown a few seconds
			_segment(arg[0], arg[1])
		"wait_idle":   # the demo waits for the scene to be over: [at least, at most] seconds
			_wait = {"since": _time, "min": float(arg[0]), "max": float(arg[1]), "idle": 0.0}
		"interact_now":   # Chloé talks to what is in front of her (not a simulated key: never lost)
			current_scene.get("player").call("_interact")
		"fast_battles":   # the demo's battles are short: the foe falls (or calms) at once
			_fast_battles = arg
		"give_named":   # [species, name, level]: a dino of the party with its own name
			root.get_node("Game").call("add_caught", load("res://game/dino.gd").create(StringName(arg[0]), arg[2], arg[1]))
		"banner":   # big text at the top of the screen (a live demo)
			var old := root.get_node_or_null("DemoBanner")
			if old:
				old.queue_free()
			if arg != "":
				var layer := CanvasLayer.new()
				layer.name = "DemoBanner"
				layer.layer = 90
				var l := Label.new()
				l.text = arg
				l.add_theme_font_size_override("font_size", 34)
				l.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
				l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04))
				l.add_theme_constant_override("outline_size", 10)
				l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
				l.grow_horizontal = Control.GROW_DIRECTION_BOTH
				l.offset_top = 150
				layer.add_child(l)
				root.add_child(layer)
		"starter":   # play with another hatchling: it replaces the first dino of the party
			var game := root.get_node("Game")
			game.call("set_flag", &"starter", String(arg))
			var names: Dictionary = game.get_script().get_script_constant_map()["STARTERS"]
			var d = load("res://game/dino.gd").create(StringName(arg), 14, names[StringName(arg)])
			game.get("party")[0] = d
			game.emit_signal("party_changed")
		"dlog":   # print every line the dialogue box shows
			_dlog = arg
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
		"reliefs":   # big scenery as its real 3D models (true) or as pictures (false), the zone rebuilt
			current_scene.get("_view").set("reliefs", arg)
			current_scene.get("_view").call("_apply_quality")
		"details":   # the 3D models' details from normal maps (true) or not (false)
			current_scene.get("_view").set("details", arg)
			current_scene.get("_view").call("_apply_quality")
		"camera_distance":   # the 3D camera's distance (m, CameraRig limits), not remembered
			current_scene.get("_view").get("camera").call("set_distance", arg, false)
		"weather":
			root.get_node("Game").call("set_weather", arg)
		"moves":
			for n in current_scene.get_children():
				if n.has_signal("_action_chosen"):
					n.call("_show_menu", n.get("_moves_menu"))
		"hud":   # the battle HUD shows "wheel", "moves", "bag" or "team" (BattleHud.show_panel)
			for n in current_scene.get_children():
				if n.has_signal("_action_chosen"):
					n.get("_hud").call("show_panel", arg)
		"hud_tap":   # with "auto": at the next choice, taps these buttons of the battle HUD in turn
			_hud_taps.append_array(arg if arg is Array else [arg])   # (BattleHud.tap: "sac", "item:baie", "dinos", "dino:1"…)
		"hud_press":   # taps this button of the battle HUD now (BattleHud.tap), without "auto"
			for n in current_scene.get_children():
				if n.has_signal("_action_chosen"):
					print("⚔ [tap ", arg, "] ", "ok" if n.get("_hud").call("tap", arg) else "IMPOSSIBLE")
		"pp":   # [party index, PP]: every move of that dino of the party left with these power points
			for m: Dictionary in root.get_node("Game").get("party")[arg[0]].get("moves"):
				m["pp"] = arg[1]
		"key":   # a real key, pressed and released (InputEventKey: "E"…), unlike "press" (an action)
			for pressed in [true, false]:
				var key := InputEventKey.new()
				key.physical_keycode = OS.find_keycode_from_string(String(arg))
				key.keycode = key.physical_keycode
				key.pressed = pressed
				Input.parse_input_event(key)
		"battle_corrupt":   # [species, level]: a battle against a corrupted dino (black amber)
			var corrupt = load("res://game/dino.gd").create(StringName(arg[0]), arg[1])
			corrupt.set("corrupted", true)
			current_scene.call("_battle", corrupt)
		"battle_set":   # [property, value] on the battle's engine (BattleEngine, UnderwaterEngine: "deep"…)
			for n in current_scene.get_children():
				if n.has_signal("_action_chosen"):
					n.get("engine").set(arg[0], arg[1])
		"hurt":   # [party index, PV]: that dino of the party down to these PV (-1: the foe in battle)
			if arg[0] >= 0:
				root.get_node("Game").get("party")[arg[0]].set("hp", arg[1])
			for n in current_scene.get_children():
				if arg[0] < 0 and n.has_signal("_action_chosen"):
					n.get("engine").get("foe").set("hp", arg[1])
					n.call("_refresh_panel", n.get("_foe_panel"), n.get("engine").get("foe"))
		"dive":   # Chloé dives at the dive spot named `arg` (put in its water first; "": the one she is on)
			load("res://world/dive.gd").call("debug_plunge", current_scene, String(arg) if arg else "")
		"surface":   # under the water, she goes back up (the Remonter button)
			load("res://world/dive.gd").call("surface")
		"dive_state":
			print(load("res://world/dive.gd").call("describe", current_scene))
		"battle_rules":   # [species, level, rules, name?]: a battle with its own rules (underwater, abyss…)
			current_scene.call("_battle", load("res://game/dino.gd").create(StringName(arg[0]), arg[1], arg[3] if arg.size() > 3 else ""), arg[2])
		"flags":
			for f in arg:
				root.get_node("Game").call("set_flag", StringName(f))
		"nodes":   # the zone's entities whose name contains `arg`: where (tiles), how shown
			for n in current_scene.get("region").get_node("Entities").get_children():
				if n is Node2D and String(n.name).contains(String(arg)):
					var sprite = n.get("sprite")
					print("nœud %s à %s alpha %.2f visible %s image %s" % [n.name, ((n as Node2D).global_position / TILE).snapped(Vector2(0.1, 0.1)),
						(n as CanvasItem).modulate.a, (n as CanvasItem).visible, str((sprite as Node2D).position) if sprite is Node2D else "—"])
					var view = current_scene.get("_view")
					for p in (view.get("_proxies") if view else []):
						if p["src"] == n:
							var vis: Node3D = p["vis"]
							print("   3D : visible %s à %s couleur %s taille %s caméra %s" % [vis.visible, vis.global_position.snapped(Vector3(0.1, 0.1, 0.1)),
								vis.get("modulate"), vis.global_basis.get_scale().snapped(Vector3(0.01, 0.01, 0.01)), view.get("camera").global_position.snapped(Vector3(0.1, 0.1, 0.1))])
		"unflag":   # story flags cleared (a moment played without them)
			for f in arg:
				root.get_node("Game").call("set_flag", StringName(f), false)
		"level":
			for d in root.get_node("Game").get("party"):
				d.level = arg
				d.moves = d.call("_moves_at_level")   # the moves of that level, as in play
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
		"door":   # [house (node name), open?]: its door opens or closes (WorldView.open_door)
			var house: Node = current_scene.get("region").get_node("Entities").get_node_or_null(String(arg[0]))
			current_scene.get("_view").call("open_door", house, arg[1])
		"door_peek":   # [house, dx (m)]: Chloé in its doorway, dx aside, not faded (do the jambs hide her?)
			var house: Node = current_scene.get("region").get_node("Entities").get_node_or_null(String(arg[0]))
			load("res://story/doorway.gd").place_inside(house)
			var me: Node2D = current_scene.get("player")
			me.set("busy", true)   # (as in a scene: the exit in front of the door is not taken)
			me.modulate = Color.WHITE
			me.call("teleport", me.global_position + Vector2(float(arg[1]) * TILE, 0.0))
		"door_out":   # house: Chloé, inside its doorway (door_peek), comes out and the door closes
			var house: Node = current_scene.get("region").get_node("Entities").get_node_or_null(String(arg))
			var me: Node2D = current_scene.get("player")
			var out := func() -> void:
				await load("res://story/doorway.gd").chloe_out(house)
				me.set("busy", false)
			out.call()
		"doors":   # the zone's houses one goes into, their doors, and who is where
			var view: Node = current_scene.get("_view")
			for house in view.get("doors").get("houses"):
				if is_instance_valid(house):
					var d: Dictionary = view.call("door", house)
					print("porte ", house.name, " : seuil=", (d["threshold"] / TILE).snapped(Vector2(0.01, 0.01)), " devant=", (d["front"] / TILE).snapped(Vector2(0.01, 0.01)),
						" marche=%.2f m, haut=%.2f m, large=%.2f m, ouverte=%s, battants=%d" % [d["sill"], d["height"], d["width"],
						view.get("doors").call("is_open", house), view.get("doors").get("houses")[house]["pivots"].size()])
			var me: Node2D = current_scene.get("player")
			var dino: Node2D = current_scene.get("companion")
			var lead = dino.get("dino")
			var tall: float = load("res://actors/dino_size.gd").height_m(lead.species(), absf(dino.get("sprite").scale.y)) if lead else 0.0
			print("Chloé ", (me.global_position / TILE).snapped(Vector2(0.01, 0.01)), " mod=", me.modulate, " occupée=", me.get("busy"),
				" | dino ", lead.nickname if lead else "-", " %.2f m " % tall, (dino.global_position / TILE).snapped(Vector2(0.01, 0.01)),
				" visible=", dino.visible, " dehors=", dino.get("outside"), " mod=", dino.modulate, " physique=", dino.is_physics_processing())
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
					if p["vis"] is MeshInstance3D:   # shown as its real 3D model
						var m: MeshInstance3D = p["vis"]
						print(src.name, " 2d=", src.global_position / TILE, " modèle 3d=", m.global_position, " échelle=", m.scale, " aabb=", m.get_aabb(), " vis=", m.visible)
						continue
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
		"gset":   # [property, value] on Game (a copy: the scenario's STEPS are read-only)
			root.get_node("Game").set(arg[0], arg[1].duplicate(true) if arg[1] is Dictionary or arg[1] is Array else arg[1])
		"pebbles":   # the first `arg` amber pebbles of the Plaines found (test flags)
			for i in arg:
				root.get_node("Game").call("set_flag", StringName("galet_plaines_t%02d" % i))
		"egg":
			print("œuf : ", root.get_node("Game").get("egg"))
		"egg_steps":
			root.get_node("Game").get("egg")["steps"] = arg
		"give":
			root.get_node("Game").call("add_caught", load("res://game/dino.gd").create(StringName(arg), 6))
		"npc":   # [sheet, tile Vector2, facing]: someone standing there (Story.stranger), to compare sizes
			load("res://story/story.gd").stranger("Echelle_" + String(arg[0]), arg[0], arg[1] * TILE, arg[2])
		"dino_npc":   # [species, tile Vector2, size_scale, level, flip, (lift px)]: a dino of a scene standing there
			var d: Node2D = load("res://actors/dino_npc.gd").new()   # (by path: no class compiled before the autoloads)
			d.set("species_id", StringName(arg[0]))
			d.set("size_scale", arg[2])
			d.set("level", arg[3])
			d.set("flip", arg[4])
			d.set("lift", arg[5] if arg.size() > 5 else 0.0)
			d.position = arg[1] * TILE
			current_scene.get("region").get_node("Entities").add_child(d)
		"wild":   # [species, level, tiles from Chloé]: a wild dino of that level roaming there (calm: no battle)
			var w: Node2D = load("res://actors/wild_dino.tscn").instantiate()
			w.set("species_id", StringName(arg[0]))
			w.set("level_range", Vector2i(arg[1], arg[1]))
			w.set("roam_radius", 30.0)
			w.position = (current_scene.get("player") as Node2D).global_position + arg[2] * TILE
			current_scene.get("region").get_node("Entities").add_child(w)
			w.call("calm_down", 999.0)
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
var _battle_said := ""


## The move a player would pick: the strongest against the foe, among those left (none left:
## it struggles, the index moves.size()).
func _best_move(engine) -> int:
	var moves_db = load("res://data/moves_db.gd")
	var best: int = engine.player().moves.size()
	var best_power := -1.0
	var mine: Array = engine.player().moves
	for k in mine.size():
		var mv: Dictionary = moves_db.move(mine[k]["id"])
		var power: float = mv["power"] * moves_db.effectiveness(mv["type"], engine.foe.type())
		if mine[k]["pp"] > 0 and power > best_power:
			best_power = power
			best = k
	return best


func _auto_step() -> void:
	var fast := _turbo or _rush
	for n in current_scene.get_children():
		if n.has_signal("_action_chosen"):
			var said: String = n.get("_message").text
			if said != _battle_said and said != "":   # the battle's messages, in the log
				_battle_said = said
				print("⚔ ", said)
			if _fast_battles:
				_shorten(n.get("engine"))
			var moves_open: bool = n.get("_moves_menu") != null and n.get("_moves_menu").visible   # (opened by "moves")
			var hud = n.get("_hud")
			if n.get("_menu").visible or moves_open or (hud != null and hud.call("is_open")):
				if _demo and not fast:   # a moment to see the menu
					if _menu_at < 0.0:
						_menu_at = _time
					if _time - _menu_at < 0.8:
						return
				_menu_at = -1.0
				if not _hud_taps.is_empty():   # the scenario's own choices first (command "hud_tap")
					var what: String = _hud_taps.pop_front()
					print("⚔ [tap ", what, "] ", "ok" if hud.call("tap", what) else "IMPOSSIBLE")
					return
				var battle = n.get("engine")
				if battle.get("must_switch"):   # after a knock-out: the first dino still standing goes in
					for k in battle.get("team").size():
						if battle.call("can_switch_to", k):
							n.emit_signal("_action_chosen", {"type": "switch", "index": k})
							return
				# A corrupted foe: calm it; otherwise the first move.
				var calm: bool = n.get("_calm_button").visible
				n.emit_signal("_action_chosen", {"type": "calm"} if calm else {"type": "move", "index": _best_move(n.get("engine"))})
				return
			if _demo:   # the battle's lines move on by themselves
				if fast:
					_run("press", "interact")
				return
	var dialogue := root.get_node("Dialogue")
	if dialogue.get("_choosing"):
		if _demo and not fast and not _read_long_enough("<choix>", 1.8):
			return
		_run("press", "ui_accept")
		return
	if _demo:   # only the demo's steps start the scenes; here, the lines go on when read
		if dialogue.get("active") and (fast or _page_read(dialogue)):
			_run("press", "interact")
		return
	_run("press", "interact")


## The page on screen has been there long enough to be read (a letter: a little longer).
func _page_read(dialogue: Node) -> bool:
	if dialogue.get("_in_letter"):
		return _read_long_enough("<lettre>", 8.0)
	var box: RichTextLabel = dialogue.get("_text")
	if box == null or box.visible_characters != -1:
		return false   # still being typed
	var text := box.get_parsed_text()
	return _read_long_enough(text, clampf(1.2 + text.length() * 0.032, 1.8, 6.0))


func _read_long_enough(what: String, seconds: float) -> bool:
	if what != _line_seen:
		_line_seen = what
		_line_at = _time
		return false
	return _time - _line_at >= seconds


## A short battle for the demo: the foe at 1 PV, or a corrupted one nearly calm.
func _shorten(engine: Object) -> void:
	if engine == null or engine == _fast_engine:
		return
	_fast_engine = engine
	var foe = engine.get("foe")
	if foe.get("corrupted"):
		engine.set("calm", int(engine.get("calm_full")) - 5)
	else:
		foe.set("hp", 1)


## Something is playing: a line, a question, a battle, a zone change, Chloé held by a scene.
func _scene_busy() -> bool:
	if root.get_node("Dialogue").get("active"):
		return true
	if int(load("res://story/story.gd").get("playing")) > 0:   # a scene of the story is still going on
		return true
	for n in current_scene.get_children():
		if n.has_signal("_action_chosen"):
			return true
	var player = current_scene.get("player")
	return (player != null and player.get("busy")) or current_scene.get("_changing_zone")


func _check_wait(delta: float) -> void:
	_wait["idle"] = 0.0 if _scene_busy() else float(_wait["idle"]) + delta
	var waited := _time - float(_wait["since"])
	if (waited >= float(_wait["min"]) and float(_wait["idle"]) >= 1.2) or waited >= float(_wait["max"]):
		_wait = {}
		if _turbo:
			_turbo = false
			_next_part()


## N: the current scene goes by as fast as it can, then the next part begins.
func _skip_part() -> void:
	if _wait.is_empty():
		_next_part()
	else:
		_turbo = true


func _next_part() -> void:
	for j in range(_step, _steps.size()):
		if _steps[j][1] == "segment":
			_step = j
			_sched = float(_steps[j][0])
			return


func _demo_keys() -> void:
	for key: Key in [KEY_P, KEY_N]:
		var down := Input.is_physical_key_pressed(key)
		if down and not _keys.get(key, false):
			if key == KEY_P:
				_toggle_pause()
			elif not _paused:
				_skip_part()
		_keys[key] = down


func _toggle_pause() -> void:
	_paused = not _paused
	if _held != "":   # Chloé stops walking during the pause, and goes on afterwards
		if _paused:
			Input.action_release(_held)
		else:
			Input.action_press(_held)
	if _pause_layer == null:
		_pause_layer = CanvasLayer.new()
		_pause_layer.layer = 96
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.35)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_pause_layer.add_child(dim)
		var l := _demo_label("⏸  PAUSE\nP pour reprendre · N pour passer à la suite", 40)
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		l.grow_horizontal = Control.GROW_DIRECTION_BOTH
		l.grow_vertical = Control.GROW_DIRECTION_BOTH
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pause_layer.add_child(l)
		root.add_child(_pause_layer)
	_pause_layer.visible = _paused


func _demo_help() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DemoHelp"
	layer.layer = 95
	var l := _demo_label("DÉMO   ·   P : pause   ·   N : étape suivante   ·   Espace : réplique suivante", 17)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.offset_top = 6
	layer.add_child(l)
	root.add_child(layer)


## A part's title: the chapter, then what it shows; it fades after a few seconds.
func _segment(chapter: String, title: String) -> void:
	print("— ", chapter, " · ", title)
	var old := root.get_node_or_null("DemoBanner")
	if old:
		old.queue_free()
	var layer := CanvasLayer.new()
	layer.name = "DemoBanner"
	layer.layer = 90
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.offset_top = 120
	box.add_child(_demo_label(chapter, 24))
	box.add_child(_demo_label(title, 36))
	for l: Label in box.get_children():
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(box)
	root.add_child(layer)
	var fade := box.create_tween()
	fade.tween_interval(4.5)
	fade.tween_property(box, "modulate:a", 0.0, 1.0)


func _demo_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04))
	l.add_theme_constant_override("outline_size", 10)
	return l
