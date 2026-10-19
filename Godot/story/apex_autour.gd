class_name ApexAutour
## After chapter 9 (docs/chapitre-9-scenes.md « Autour », the post-game): who says what once the
## epilogue is over. Hélène in her armchair at the Cabinet; Isaure at her boat (the fast travel, « Tarif
## unique : rien »); Maïa at the Grand Crâne (her challenge n° 6 « pour voir », once a day, when the
## MÉCANIQUES agent has written it); Bertille at the Monts (once); Joss on the jetty (the coat with a
## pocket for the bird, once); Dame Suie on the quay without gloves (Hélène with her, once); Brac
## night watchman; Léonce; the Anciens (a line each, once). Roc's words are DialogueApex.chatter
## (his chatter, so his questions and the Cabinet's reserve stay). The words: data/dialogue_apex.gd.
## Flags: helene_cabinet_n, isaure_barque_n, maia_gardienne_n, bertille_helene_remontee,
## joss_poche_piaf, suie_port_n, brac_jetee_n, leonce_port_n, anciens_helene_n (one bit each).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const V := preload("res://story/volcan.gd")
const A := preload("res://story/apex.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
const HELENE := "Hélène"
## Maïa at the Grand Crâne (the Plaines, where her first challenge was: Objectives.MAIA_DUEL).
const CRANE := Vector2(100.8, 65.2)
const ANCIENS_BITS := {&"griffe_grise": 1, &"vieux_rempart": 2, &"voix_du_marais": 4}


## Hélène in her armchair (event « helene_cabinet »): a line each time.
static func helene(who: Node) -> void:
	_faces(who)
	if not Game.flag(&"epilogue_fini"):   # (the epilogue's own scene plays on entering the Cabinet)
		Stage.emote(who, "…")
		return
	var pool: Array = DialogueApex.HELENE_CABINET.duplicate()
	pool[1] = DialogueApex.HELENE_ANCIEN.get(A.starter_species(), DialogueApex.HELENE_ANCIEN[&"parasaurolophus"])
	await S.say([{"who": HELENE, "text": ForetCamp.next_line(&"helene_cabinet_n", pool)}])


## Isaure at her boat (event « isaure_barque »): a line, then « Où met-on le cap ? » (Maïa's boat's
## landings, Barque) when Chloé knows another one.
static func isaure(who: Node) -> void:
	_faces(who)
	await S.say([{"who": ISAURE, "text": ForetCamp.next_line(&"isaure_barque_n", DialogueApex.ISAURE_BARQUE)}])
	var boat = S.actor(Barque.BOAT)
	var known: Array = Barque.known_quays()
	if boat == null or known.size() < 2:
		return
	var rows := []
	for q: Dictionary in known:
		rows.append([q["zone"], q["region"], q["sight"]])
	var title := DialogueApex.ISAURE_CAP.get_slice(" Tarif", 0)
	var goes: StringName = await VoyageScreen.ask(S.world(), rows, Voyage.zone_now(), title, "Tarif unique : rien.")
	if goes != &"":
		await Barque._cross(boat, goes)


## Maïa at the Grand Crâne (event « maia_gardienne »): a line each time; then her challenge n° 6, once
## a day, when ApexBattles has it (maia_team).
static func maia(who: Node) -> void:
	_faces(who)
	await S.say([{"who": MAIA, "text": ForetCamp.next_line(&"maia_gardienne_n", DialogueApex.MAIA_GARDIENNE)}])
	var team = A.from_battles(&"maia_team", [], null)
	if not team is Array or int(Game.flag(&"maia_defi_6_jour")) == Game.day:
		return
	if await Dialogue.choose("", "Le défi n° 6 de Maïa : « pour voir ».", ["Le relever", "Pas aujourd'hui"]) != 0:
		return
	Game.set_flag(&"maia_defi_6_jour", Game.day)
	if await S.duel(MAIA, team, A.battles_const("MAIA_RULES", {})):
		Game.set_flag(&"maia_defi_6")
	Save.save_game()


## On entering the Plaines after the epilogue: Maïa keeps the Grand Crâne.
static func on_plaines() -> void:
	if Game.flag(&"epilogue_fini"):
		A.resident(["MaiaCrane", "MaiaGardienne"], A.MAIA_SHEETS, S.at(CRANE.x, CRANE.y), MAIA, &"maia_gardienne")


## Bertille at the Monts (Monts._again, before chapter 8's line): Hélène came back, once.
static func bertille_line() -> String:
	if not Game.flag(&"apex_fini") or Game.flag(&"bertille_helene_remontee"):
		return ""
	Game.set_flag(&"bertille_helene_remontee")
	return DialogueApex.BERTILLE_LINE


## Joss on the jetty right after the epilogue (event « joss_jetee »): the coat for Maïa, a pocket for
## the bird (once); afterwards, his usual words.
static func joss(who: Node) -> void:
	if not Game.flag(&"epilogue_fini"):   # (before the end: the jetty's scene)
		await Epilogue.jetty_event(&"joss_jetee", who)
		return
	_faces(who)
	if Game.flag(&"joss_poche_piaf"):
		await Dialogue.run(DialogueDB.chatter(&"joss"))
		return
	var lines := DialogueApex.joss_lines()
	lines[1] = CS.cue(lines[1], func() -> void:
		var maia = S.actor("MaiaJetee")
		if maia:
			Stage.hop(maia, 1, 4.0)
			Stage.emote(maia, "♥"))
	await S.say(lines)
	Save.save_game()


## Dame Suie on the quay (event « suie_port »): the first time, Hélène comes by (four lines between
## them); then a line each time.
static func suie(who: Node) -> void:
	_faces(who)
	var n := int(Game.flag(&"suie_port_n"))
	Game.set_flag(&"suie_port_n", n + 1)
	if n == 0:
		var at := A.px_of(who)
		var h := S.stranger("HeleneQuai", V.sheet(A.HELENE_SHEETS), S.ground_near(at + Vector2(70.0, 10.0), 2), "left", HELENE)
		A.tint_helene(h)
		if h:
			h.modulate.a = 0.0
			await Stage.fade_in(h, 0.5)
		await S.say(DialogueApex.suie_helene())
		if h:
			Stage.fade_out(h, 0.6, true)
		return
	await S.say([{"who": DialogueApex.SUIE, "text": DialogueApex.SUIE_PORT[(n - 1) % DialogueApex.SUIE_PORT.size()]}])


## Brac at the end of the jetty, night watchman (event « brac_jetee » once the epilogue is over).
static func brac(who: Node) -> void:
	_faces(who)
	await S.say([{"who": DialogueApex.BRAC, "text": ForetCamp.next_line(&"brac_jetee_n", DialogueApex.BRAC_JETEE)}])


## Léonce on the pontoon (event « leonce_port » once the epilogue is over).
static func leonce(who: Node) -> void:
	_faces(who)
	await S.say([{"who": DialogueApex.LEONCE, "text": ForetCamp.next_line(&"leonce_port_n", DialogueApex.LEONCE_PORT)}])


## An Ancien after the epilogue (Story.run: griffe_grise, vieux_rempart, voix_du_marais): its line,
## once. True when said (its own scene does not play then).
static func ancien(id: StringName, who: Node) -> bool:
	if not Game.flag(&"epilogue_fini") or not ANCIENS_BITS.has(id):
		return false
	var seen := int(Game.flag(&"anciens_helene_n"))
	var bit: int = ANCIENS_BITS[id]
	if seen & bit:
		return false
	Game.set_flag(&"anciens_helene_n", seen | bit)
	await S.say([CS.cue({"text": DialogueApex.ANCIENS[id]}, func() -> void:
		if who is DinoNpc:
			(who as DinoNpc).cry(&"neutre")
			Stage.bow(who, 1.2))])
	Save.save_game()
	return true


static func _faces(who) -> void:
	if who is Npc and Stage.chloe():
		(who as Npc).face(Stage.chloe().global_position)
