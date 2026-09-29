extends RefCounted
## Visual check only (finition B, 29/09), no scene played: Maïa's new &"accroupi" scene pose
## (actors/outfits.gd, Outfits.POSES["maia"]), the four ways she can face — same flags/spot as
## tools/scenarios/vis_ch5.gd (the belvédère on the Côte, where @MaiaGuet already stands).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_poses_b_maia.gd

const ST := "res://story/stage.gd"
const SELF := "res://tools/scenarios/vis_poses_b_maia.gd"
const StageScript := preload("res://story/stage.gd")

# Outfits._facing reads the direction off the NPC's currently playing animation name, not off
# Npc.facing directly (setting that property alone did nothing here — she kept facing "up", her
# idle look-out direction at the belvédère). Stage.turn_to() is the real entry point: it calls the
# NPC's own "face" method, which turns her AND updates that animation. `dir` arrives already scaled
# by capture.gd's "static" (a Vector2 argument × the cell size): only its sign matters here.
static func turn(actor, dir: Vector2) -> bool:
	StageScript.turn_to(actor, (actor as Node2D).global_position + dir)
	return true


const STEPS := [
	[0.8, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "moustique_vu", "joss_cote_vu", "filet_coupe", "nessie", "masque_plongee", "barque_nuit_vue", "grottes_arrivee", "cache_vue", "passeur_parle", "passeur_battu", "passeur_parti", "caisses_fouillees", "barque_isaure_vue", "found_journal_21", "passe_recif", "recif_arrivee", "mosasaure_parle", "mosasaure_battu", "sceau_cote", "coeur_3"]],
	[1.0, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "weather", &"clear"], [1.2, "zone", &"cote"],
	[3.2, "camera_distance", 7.0], [3.25, "tp", Vector2(99.2, 31.2)], [3.3, "face", Vector2(-1, -1)],
	[4.2, "shot", "b0_maia_debout"],
	[4.3, "static", [SELF, "turn", "@MaiaGuet", Vector2.DOWN]],
	[4.4, "static", [ST, "pose", "@MaiaGuet", "accroupi", 0.0]],
	[4.7, "shot", "b1_accroupi_face"],
	[4.8, "static", [ST, "pose", "@MaiaGuet", "", 0.0]],
	[4.9, "static", [SELF, "turn", "@MaiaGuet", Vector2.LEFT]],
	[5.0, "static", [ST, "pose", "@MaiaGuet", "accroupi", 0.0]],
	[5.3, "shot", "b2_accroupi_gauche"],
	[5.4, "static", [ST, "pose", "@MaiaGuet", "", 0.0]],
	[5.5, "static", [SELF, "turn", "@MaiaGuet", Vector2.RIGHT]],
	[5.6, "static", [ST, "pose", "@MaiaGuet", "accroupi", 0.0]],
	[5.9, "shot", "b3_accroupi_droite"],
	[6.0, "static", [ST, "pose", "@MaiaGuet", "", 0.0]],
	[6.1, "static", [SELF, "turn", "@MaiaGuet", Vector2.UP]],
	[6.2, "static", [ST, "pose", "@MaiaGuet", "accroupi", 0.0]],
	[6.5, "shot", "b4_accroupi_dos"],
	[6.8, "static", [ST, "pose", "@MaiaGuet", "", 0.0]],
	[6.9, "static", [SELF, "turn", "@MaiaGuet", Vector2.DOWN]],
	[7.2, "state", null],
]
