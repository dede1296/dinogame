extends RefCounted
## ANIM-5's check of the staging (story/foret_fin.gd): cabinet. See tools/capture.gd.

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "oeuf_vole_apaise", "cage_ouverte", "utah_lecon", "sceau_foret", "cages_ouvertes", "found_journal_11", "papiers_brac_lus", "masque_en_vue", "masque_vu", "maia_pont_vue", "maia_defi_2", "found_journal_8"]],
	[0.82, "give_named", ["parasaurolophus", "Écho", 16]],
	[0.84, "level", 18],
	[0.86, "clock", 11],
	[0.88, "weather", &"clear"],
	[0.90, "dlog", true],
	[0.92, "demo", true],
	[0.94, "auto", true],
	[0.96, "fast_battles", true],
	[1.10, "zone", &"cabinet"],
	[2.00, "wait_idle", [1, 150]],
	[2.30, "shot", "cb_fin"],
	[2.50, "state", null],
]
