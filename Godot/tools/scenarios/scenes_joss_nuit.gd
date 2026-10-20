extends RefCounted
## Une scène à la fois (story/scenes.gd), rejoué dans le jeu : le bug (3) de Greg (20/10). La peau de
## Parasaurolophus ramassée au bord de l'étang ; au Havre, Joss pose sa question (il manque la boucle) ; la nuit
## tombe PENDANT la question : la barque d'Isaure attend la fin de la conversation (avant : ses répliques se
## mêlaient à celles de Joss, puis Chloé restait bloquée) ; puis Chloé est libre. Enfin « Se débloquer » sur une
## Chloé tenue sans raison : elle est rendue au joueur, la zone remise. Voir tools/capture.gd :
##   godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/scenes_joss_nuit.gd
##       "titre=Une scène à la fois : la peau, Joss, puis la nuit au Havre ; Se débloquer"
## À lire dans la sortie : « » les répliques dans l'ordre (dlog), « static busy » et « joueur occupé » à false
## à la fin de chaque partie, barque_vue dans les drapeaux.

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "ferreol_rencontre", "selle_demandee", "maia_defi_1"]],
	[0.84, "calm", 900.0],
	[0.86, "dlog", true],
	[0.88, "weather", &"clear"],
	[0.90, "clock", 11.0],
	[0.92, "level", 14],
	# 1. La peau mue, au bord de l'étang de la Prairie.
	[1.00, "zone", &"plaines"],
	[2.60, "tp", Vector2(84.4, 51.3)],
	[2.70, "hold", "move_up"],
	[2.78, "hold", ""],
	[3.00, "near", null],
	[3.10, "shot", "c1_peau"],
	[3.20, "interact_now", null],
	[3.80, "shot", "c2_peau_ramassee"],
	[3.90, "talk", true],
	[6.00, "talk", false],
	[6.10, "near", null],
	[6.20, "static", ["res://story/scenes.gd", "busy"]],
	# 2. Au Havre, à la tombée de la nuit : la question de Joss, puis la barque sans lumière.
	[6.40, "zone", &"havre_dore"],
	[8.20, "clock", 20.46],
	[8.30, "tp", Vector2(42.0, 10.7)],
	[8.40, "hold", "move_up"],
	[8.48, "hold", ""],
	[8.70, "interact_now", null],
	[9.40, "shot", "c3_joss_question"],
	[12.0, "state", null],
	[12.1, "static", ["res://story/scenes.gd", "waiting"]],
	[12.2, "shot", "c4_nuit_tombee_joss_seul"],
	[12.4, "pick", 2],
	[13.4, "shot", "c5_la_nuit_apres_joss"],
	[13.5, "talk", true],
	[45.0, "talk", false],
	[45.1, "shot", "c6_fin_de_la_nuit"],
	[45.2, "near", null],
	[45.3, "static", ["res://story/scenes.gd", "busy"]],
	[45.4, "state", null],
	# 3. Se débloquer : Chloé tenue sans scène (comme après une scène cassée), le bouton du menu la libère.
	[46.0, "static", ["res://story/story.gd", "lock", true]],
	[46.2, "near", null],
	[46.4, "shot", "c7_tenue"],
	[46.6, "static", ["res://story/unstick.gd", "run_now"]],
	[48.5, "near", null],
	[48.6, "static", ["res://story/scenes.gd", "busy"]],
	[48.8, "hold", "move_down"],
	[49.4, "hold", ""],
	[49.6, "shot", "c8_debloquee"],
	[49.8, "state", null],
]
