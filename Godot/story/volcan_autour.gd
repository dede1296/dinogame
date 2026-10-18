class_name VolcanAutour
## Chapter 8, the Plaine Volcanique, around it (docs/chapitre-8-scenes.md, « Autour »): Roc at the
## Cabinet (the lady in grey brought Hélène's notebooks back: « Je n'ai rien compris. J'ai fait du
## thé. »; Brac at the end of the jetty with a sandwich; the Sceau du Volcan, « Cheminée m'a mangé
## deux chapeaux »; « Ne la laisse pas ouvrir. Et ne la laisse pas toute seule non plus. »);
## Bertille at the Monts (the fires gone out: zero); Joss at the Havre (a coat at Maïa's size, « avec
## une poche pour le piaf »); Léonce back on the pontoon of Port-Ambre, without his mask. Roc's
## question about the T-Rex is in data/dialogue_volcan.gd (the chapter's questions).
## Flags: roc_suie_carnets, carnets_rendus, roc_brac_parti, roc_sceau_volcan, bertille_forges_eteintes,
## joss_volcan, leonce_port_vu; leonce_port_n (lines).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const CHLOE := "Chloé"
const ROC := "Prof. Roc"
const JOSS := "Joss"
const LEONCE := "Léonce"
const LEONCE_PORT := [
	"Le poisson ne revient pas plus vite quand on le regarde. Mais on le regarde quand même.",
	"Le rouquin est assis au bout de la jetée. Il regarde la mer. De loin. Il ne dérange personne : il a l'air d'un phare qui boude.",
]


# ------------------------------------------------------------------ Roc, at the Cabinet

## Roc at the Cabinet (Story.run « roc »): the notebooks, Brac at the jetty, the Sceau and the
## Cœur, in that order, each once. True if he said something.
static func roc() -> bool:
	var todo: Array = []
	if Game.flag(&"suie_partie") and not Game.flag(&"roc_suie_carnets"):
		todo.append(_notebooks())
	if Game.flag(&"brac_parti") and not Game.flag(&"roc_brac_parti"):
		todo.append([
			{"who": ROC, "text": "Brac est parti ? Voir la mer ? … Il est passé par le port. Il a demandé à Léonce où on voit la mer « de loin ». Léonce lui a montré la jetée. Il s'est assis au bout avec ses trois bêtes, et il a mangé un sandwich. Il y est peut-être encore."},
			{"flag": &"roc_brac_parti"},
		])
	if Game.flag(&"sceau_volcan") and not Game.flag(&"roc_sceau_volcan"):
		todo.append(_the_seal())
	if todo.is_empty():
		return false
	var prof = S.actor("Roc")
	if prof is Node2D:
		await CS.step_aside(prof, 66.0)
		Stage.turn_to(prof, Stage.chloe().global_position)
	for lines: Array in todo:
		await S.say(lines)
	Save.save_game()
	return true


## The lady in grey came: a crate on the desk, all of Hélène's notebooks; « Je refais mes tables »;
## she looked at the incubator, and left. He made tea; she did not want any. Her note on the crate.
static func _notebooks() -> Array:
	var prof = S.actor("Roc")
	var crate := func() -> void:
		if prof:
			Stage.emote(prof, "…")
	return [
		CS.cue({"who": ROC, "text": "La dame en gris est venue. Ici. Elle a posé une caisse sur le bureau : les carnets d'Hélène. Tous. Ceux de l'ambre forcé, ceux qu'on avait pris il y a douze ans. Elle a dit « Je refais mes tables », elle a regardé la couveuse, et elle est repartie. … Je n'ai rien compris. J'ai fait du thé. Elle n'en a pas voulu."}, crate),
		{"who": ROC, "text": "Elle a laissé un mot sur la caisse : « Pour le professeur Roc, qui a une clé. » Je ne sais pas si c'est un compliment."},
		{"flag": &"roc_suie_carnets"},
		{"flag": &"carnets_rendus"},
	]


## The Sceau du Volcan, the last; Cheminée ate two of his hats; then the Cœur: « Ne la laisse pas
## ouvrir, Chloé. Et ne la laisse pas toute seule non plus. »
static func _the_seal() -> Array:
	var prof = S.actor("Roc")
	var hats := func() -> void:
		if prof:
			Stage.hop(prof, 1, 3.0)
	var heart := func() -> void:
		CS.hearts_beat(2, 1.0)
		if prof:
			Stage.bow(prof, 1.4)
	return [
		CS.cue({"who": ROC, "text": "Le Sceau du Volcan. Le dernier. … Cheminée t'a laissée passer ? Il m'a mangé deux chapeaux, à moi. Hélène disait qu'il aimait le feutre."}, hats),
		CS.cue({"who": ROC, "text": "Le cinquième. Le plus bruyant, elle disait. Et elle en a quatre, là-haut, devant la porte. Avec ma Maïa. … Ne la laisse pas ouvrir, Chloé. Et ne la laisse pas toute seule non plus. Je sais : c'est deux choses. Hélène aussi faisait toujours deux choses."}, heart),
		{"flag": &"roc_sceau_volcan"},
	]


# ------------------------------------------------------------------ Bertille, Joss, Léonce

## Bertille at the Monts (Monts._again, her line before her questions): the fires gone out, once.
## "" when she has nothing of the chapter's to say.
static func bertille_line() -> String:
	if not Game.flag(&"grande_forge_eteinte") or Game.flag(&"bertille_forges_eteintes"):
		return ""
	Game.set_flag(&"bertille_forges_eteintes")
	return "Les feux se sont éteints, au pied du volcan. Un par un, et puis le grand. J'ai recompté deux fois : zéro. Ça ne m'était pas arrivé depuis l'hiver où elle est descendue voir. … Tiens. Une soupe. Tu as une tête à soupe."


## Joss at the Havre (Story.run « joss », before the chapter 7's lines): once Chloé has seen Maïa
## at the door, once. True if he said it.
static func joss() -> bool:
	if not Game.flag(&"porte_arrivee") or Game.flag(&"joss_volcan"):
		return false
	await S.say([
		{"who": JOSS, "text": "Tu l'as vue ? Maïa ? Elle a toujours mon manteau ? … Il sent la colle à cuir, je sais. Dis-lui que j'en ai cousu un autre. À sa taille. Avec une poche pour le piaf."},
		{"flag": &"joss_volcan"},
	])
	Save.save_game()
	return true


## Léonce on the pontoon of Port-Ambre (Npc « Leonce » of the port, event « leonce_port »,
## show_flag grande_forge_eteinte), without his mask; Brac at the jetty once he has gone.
static func leonce_port(who: Node) -> void:
	if who is Npc:
		(who as Npc).face(Stage.chloe().global_position)
	Game.set_flag(&"leonce_port_vu")
	var pool: Array = LEONCE_PORT if Game.flag(&"brac_parti") else LEONCE_PORT.slice(0, 1)
	await S.say([{"who": LEONCE, "text": ForetCamp.next_line(&"leonce_port_n", pool)}])


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): Roc brought on beside Chloé, on any zone (his news
## of the chapter, then the next ones: none left).
static func static_roc() -> void:
	S.playing += 1
	var chloe := Stage.chloe()
	S.stranger("Roc", "roc", S.ground_near(chloe.global_position + Vector2(0.0, -2.4 * S.CELL), 3), "down", ROC)
	await roc()
	S.playing -= 1
