class_name ApexJetee
## The epilogue, the jetty of Port-Ambre the next morning (docs/chapitre-9-scenes.md § 5 a to 5 e;
## the Cabinet before it: story/epilogue.gd): the whole village; Hélène on Roc's arm, a straw hat
## (« pas de feutre, Cheminée aime le feutre »); the Réserve d'Ambrelune said in a few lines (« Vous
## aurez un banc. »); Brac from the end of the jetty, « ET MOI ? », his card has an address at last,
## night watchman; Chloé and Maïa the first guardians (two discs of bare amber with a fern); Isaure in
## the cardboard mask, « Bouh. », and the two Kerval laugh together for the first time; page 40 at the
## end of the jetty where Chloé landed on the first day; « Ambrelune »; the post-game opens.
## Flags: epilogue_port, reserve_annoncee, brac_gardien, gardiennes_nommees, masque_carton_porte,
## found_journal_40 (page_40), epilogue_fini, post_game.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const A := preload("res://story/apex.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
const HELENE := "Hélène"
const ROC := "Prof. Roc"
const BRAC := "Brac"
const LEONCE := "Léonce"
const HAMON := "M. Hamon"
const BADGE := "insigne_gardienne"
const MORNING := 10.0
## The village on the jetty: [node, sheet(s), display, ApexPlaces name, round Chloé elsewhere (px)].
const VILLAGE := [
	["GustaveJetee", ["pecheur"], "Gustave", "JETEE_GUSTAVE", Vector2(-140.0, -50.0)],
	["FirminJetee", ["firmin_sans_masque", "sbire"], "Firmin", "JETEE_FIRMIN", Vector2(-250.0, -60.0)],
	["RosalieJetee", ["rosalie"], "Rosalie", "JETEE_ROSALIE", Vector2(-200.0, -100.0)],
	["PervencheJetee", ["pervenche"], "Mémé Pervenche", "JETEE_PERVENCHE", Vector2(-150.0, -140.0)],
	["JossJetee", ["joss"], "Joss", "JETEE_JOSS", Vector2(160.0, -160.0)],
	["SuieJetee", ["dame_suie_sans_lunettes", "dame_suie"], "Dame Suie", "JETEE_SUIE", Vector2(-180.0, -240.0)],
]
const XP_EPILOGUE := 100


## 5 a to 5 e, the next morning on the jetty; then « Ambrelune », and the post-game.
static func jetty() -> void:
	if Game.flag(&"epilogue_port") or S.world() == null:
		return
	S.lock(true)
	await Router.fade_out(0.8)
	Game.pass_time_until(MORNING)
	await Epilogue.card("Le lendemain")
	var cast := _jetty_cast()
	await Router.fade_in(0.8)
	await _arrives(cast)
	await S.say(reserve(cast))
	await _hand_up(cast)
	await S.say(brac(cast))
	await _come_here(cast)
	await S.say(guardians(cast))
	await _mask_out(cast)
	await S.say(bouh(cast))
	await _laughs(cast)
	await _end_of_jetty(cast)
	await S.say(page_40(cast))
	Game.award_team_xp(XP_EPILOGUE)
	Save.save_game()
	await _the_end(cast)
	S.lock(false)


## Everybody on the jetty (ApexPlaces.JETEE_*; round Chloé elsewhere): Hélène and Roc at the foot of
## the pier (they walk up from the village), Isaure by her boat, Maïa (Moustique on her shoulder),
## Caillou, Léonce, M. Hamon, Brac at the end with his three, the others (Gustave and Firmin without
## masks, Rosalie, Mémé Pervenche, Joss, Dame Suie without gloves).
static func _jetty_cast() -> Dictionary:
	var cast := {}
	var up := Vector2(0.0, -4.0 * S.CELL)   # (Hélène and Roc start up the street, then walk down)
	cast["helene"] = A.person(["HeleneJetee"], A.HELENE_SHEETS, A.spot("JETEE_HELENE", Vector2(10.0, -110.0)) + up, "down", HELENE)
	A.tint_helene(cast["helene"])
	cast["roc"] = A.person(["RocJetee"], ["roc"], A.spot("JETEE_ROC", Vector2(60.0, -120.0)) + up, "down", ROC)
	cast["isaure"] = A.person(["IsaureJetee"], A.ISAURE_SHEETS, A.spot("JETEE_ISAURE", Vector2(50.0, 100.0)), "left", ISAURE)
	cast["maia"] = A.person(["MaiaJetee"], A.MAIA_SHEETS, A.spot("JETEE_MAIA", Vector2(-4.0 * S.CELL, -2.0 * S.CELL)), "right", MAIA)
	cast["leonce"] = A.person(["Leonce", "LeonceJetee"], ["leonce_port", "pecheur"], A.spot("JETEE_LEONCE", Vector2(-40.0, 50.0)), "right", LEONCE)
	cast["hamon"] = A.person(["HamonJetee"], ["hamon"], A.spot("JETEE_HAMON", Vector2(140.0, -100.0)), "left", HAMON)
	cast["brac"] = A.person(["BracJetee"], ["brac_assis_cage", "brac"], A.spot("JETEE_BRAC", Vector2(-40.0, 220.0)), "down", BRAC)
	cast["caillou"] = A.dino(["CaillouJetee"], &"triceratops", A.spot("JETEE_CAILLOU", Vector2(120.0, -220.0)))
	cast["mastoc"] = A.dino(["MastocJetee"], &"allosaurus", A.spot("JETEE_MASTOC", Vector2(20.0, 160.0)))
	cast["cabosse"] = A.dino(["CabosseJetee"], &"stygimoloch", A.spot("JETEE_CABOSSE", Vector2(-340.0, -60.0)))
	cast["grognon"] = A.dino(["GrognonJetee"], &"majungasaurus", A.spot("JETEE_GROGNON", Vector2(-440.0, -70.0)))
	for row: Array in VILLAGE:
		cast[row[0]] = A.person([row[0]], row[1], A.spot(row[3], row[4]), "down", row[2])
	return cast


## Watched, no line: the village on the jetty; Hélène comes on Roc's arm, a new hat; Maïa runs to
## Chloé.
static func _arrives(cast: Dictionary) -> void:
	var jetty := A.spot("JETEE_CHLOE", Vector2.ZERO)
	Stage.look_at(jetty + Vector2(0.0, -1.5 * S.CELL), 1.0)
	var chloe := Stage.chloe()
	if chloe and A.has_place("JETEE_CHLOE"):
		await CS.chloe_walk(jetty, 110.0, 3.0)
	for k in ["helene", "roc"]:
		var n = cast.get(k)
		if n is Npc:
			var to := A.spot("JETEE_HELENE" if k == "helene" else "JETEE_ROC", Vector2(10.0 if k == "helene" else 60.0, -110.0))
			(n as Npc).walk_to(to, "down", 50.0)
	var maia = cast.get("maia")
	if maia is Npc and chloe:
		await (maia as Npc).walk_to(S.ground_near(chloe.global_position + Vector2(-56.0, -6.0), 2), "", 190.0)
		(maia as Npc).face(chloe.global_position)
	await S.wait(1.4)


## 5 a (10 lines): « Je ne ferai pas de discours. »; the Réserve; the captain's boats, a single fare;
## « c'est moi qui tiens la barre »; the fish; « Un parc ! » « Une réserve. Vous aurez un banc. »
static func reserve(cast: Dictionary) -> Array:
	var hat := func() -> void:
		var h = cast.get("helene")
		if h:
			Stage.look_at((h as Node2D).global_position, 0.8)
			Stage.hop(h, 1, 3.0)
	var hamon := func() -> void:
		var m = cast.get("hamon")
		if m:
			Stage.hop(m, 2, 8.0)
			Stage.emote(m, "!")
	return [
		{"text": "Port-Ambre. Tout le village sur la jetée, ce qui ne fait pas beaucoup de monde, et c'est déjà plus qu'avant."},
		CS.cue({"text": "Hélène au bras de Roc, un chapeau neuf. En paille : pas de feutre, Cheminée aime le feutre."}, hat),
		{"who": HELENE, "text": "Je ne ferai pas de discours. Anselme en a préparé un ; il le gardera."},
		{"who": HELENE, "text": "Cette île est à ceux qui y dorment. Elle ne se vend pas, pas un galet. Mais elle se montre. À partir de demain, Ambrelune est une Réserve. Des gens viendront la voir, encadrés, à pied, et ils repartiront le soir avec rien dans les poches qui brille."},
		{"who": HELENE, "text": "Les barques de la capitaine Kerval les amèneront. Tarif unique. Le port vivra de ça."},
		{"who": ISAURE, "text": "Et on ne vend rien qui brille. Elle l'a dit ; je le redis, parce que c'est moi qui tiens la barre."},
		{"who": LEONCE, "text": "Et le poisson ?"},
		{"who": HELENE, "text": "Il reviendra, Léonce. Il revient toujours quand on arrête de le regarder."},
		CS.cue({"who": HAMON, "text": "Un parc ! Enfin ! Je n'ai lésiné sur rien !"}, hamon),
		{"who": HELENE, "text": "Une réserve, monsieur Hamon. … Non, ce n'est pas pareil. Chacun chez soi. Vous aurez un banc."},
		{"flag": &"epilogue_port"},
		{"flag": &"reserve_annoncee"},
	]


## Watched, no line: at the end of the jetty, a big hand goes up. Everybody turns round.
static func _hand_up(cast: Dictionary) -> void:
	var b = cast.get("brac")
	var end: Vector2 = (b as Node2D).global_position if b is Node2D else A.spot("JETEE_BRAC", Vector2(-40.0, 220.0))
	Stage.look_at(end, 1.0)
	if b:
		Stage.pose(b, &"")
		CS.get_up(b, 0.4)
		await Stage.rear(b, 0.8)
	for k in cast:
		var n = cast[k]
		if n is Npc and k != "brac":
			(n as Npc).face(end)
	if Stage.chloe():
		Stage.turn_to(Stage.chloe(), end)
	await S.wait(1.0)


## 5 b (9 lines): « ET MOI ? »; his card, with ash on it; « Le bout de la jetée. » « C'est une
## adresse. » Night watchman; « Crotte de Stégosaure. C'est oui. »; Fournaise.
static func brac(cast: Dictionary) -> Array:
	var b = cast.get("brac")
	var h = cast.get("helene")
	var comes := func() -> void:
		if b is Npc and h is Node2D:
			await (b as Npc).walk_to(S.ground_near((h as Node2D).global_position + Vector2(0.0, 1.8 * S.CELL), 2), "up", 90.0)
	var card := func() -> void:
		if b and h is Node2D:
			await CS.reach(b, (h as Node2D).global_position, 10.0, 1.0)
	var head := func() -> void:
		var mastoc = cast.get("mastoc")
		if mastoc is DinoNpc and b is Node2D:
			await (mastoc as DinoNpc).walk_to(S.ground_near((b as Node2D).global_position + Vector2(50.0, 10.0), 2), 80.0)
			Stage.turn_to(mastoc, (b as Node2D).global_position)
			Stage.bow(mastoc, 1.2)
	return [
		CS.cue({"who": BRAC, "text": "ET MOI ? … Et moi, madame Varenne ? Je connais les cages. Dans l'autre sens, ça doit se faire."}, comes),
		{"who": HELENE, "text": "Vous êtes Brac."},
		CS.cue({"who": BRAC, "text": "Brac. Braconnier. C'est écrit."}, card),
		{"who": HELENE, "text": "Il y a une adresse ?"},
		{"who": BRAC, "text": "Le bout de la jetée."},
		{"who": HELENE, "text": "C'est une adresse. Gardien de nuit. Les visiteurs auront peur de vous : c'est parfait, ils resteront sur le chemin."},
		CS.cue({"who": BRAC, "text": "… Crotte de Stégosaure. C'est oui. C'est oui, moucheron, arrête de sourire."}, head),
		{"who": MAIA, "text": "Il lui reste deux cent quatre-vingt-dix-huit cartes. Il va falloir les distribuer."},
		{"who": BRAC, "text": "Et tu as gardé Fournaise, moucheron ? Il mange à la pelle. Je te préviens." if Game.flag(&"fournaise_garde")
			else "Fournaise est aux coulées. Il dort au chaud. Il m'a jamais écrit."},
		{"flag": &"brac_gardien"},
	]


## Watched, no line: Hélène beckons Chloé and Maïa; Isaure leaves her boat and comes closer.
static func _come_here(cast: Dictionary) -> void:
	var h = cast.get("helene")
	var at: Vector2 = (h as Node2D).global_position if h is Node2D else A.spot("JETEE_HELENE", Vector2(10.0, -110.0))
	if h:
		Stage.hop(h, 1, 3.0)
		Stage.turn_to(h, A.chloe_px())
	await CS.chloe_walk(S.ground_near(at + Vector2(-30.0, 1.6 * S.CELL), 2), 90.0, 2.0)
	var maia = cast.get("maia")
	if maia is Npc:
		(maia as Npc).walk_to(S.ground_near(at + Vector2(-90.0, 1.6 * S.CELL), 2), "up", 90.0)
	var isaure = cast.get("isaure")
	if isaure is Npc:
		await (isaure as Npc).walk_to(S.ground_near(at + Vector2(-150.0, 1.0 * S.CELL), 2), "right", 70.0)
	await S.wait(0.6)


## 5 c (8 lines): « Une réserve, ça se garde »; two discs of bare amber with a fern; « Premières
## gardiennes de la Réserve d'Ambrelune. Ce n'est pas un cadeau : c'est du travail. »; Maïa; « C'est
## stylé. »; Roc blows his nose: « C'est le vent. »
static func guardians(cast: Dictionary) -> Array:
	var discs := func() -> void:
		var h = cast.get("helene")
		if h is Node2D:
			Act.pop((h as Node2D).global_position, BADGE, 0.9)
			await CS.reach(h, A.chloe_px(), 10.0, 1.0)
		badge_given()
	var nose := func() -> void:
		var roc = cast.get("roc")
		if roc:
			Stage.bow(roc, 0.8)
			Stage.emote(roc, "…")
	return [
		CS.cue({"who": HELENE, "text": "Une réserve, ça se garde. Pas avec des cages : avec des gens que les bêtes connaissent. Les Alphas vous reconnaîtront. Ils vous reconnaissent déjà."}, discs),
		{"who": HELENE, "text": "Chloé Varenne. Maïa Kerval. Premières gardiennes de la Réserve d'Ambrelune. Ce n'est pas un cadeau : c'est du travail. Vous avez l'habitude."},
		{"who": MAIA, "text": "Moi ? Je… j'étais de l'autre côté de la porte."},
		{"who": HELENE, "text": "Tu étais du côté de ta mère. C'est le plus difficile des deux. Et tu as tenu : la ligne, et elle. Les gardiens, c'est ça."},
		{"who": ISAURE, "text": "Elle a mon courage. Je l'ai dit."},
		{"who": MAIA, "text": "Et pas assez de prudence. Tu l'as dit aussi. Gardiennes. C'est stylé. Hein ? C'est stylé."},
		{"who": CHLOE, "text": "C'est stylé."},
		CS.cue({"who": ROC, "text": "C'est le vent. Il y a du vent."}, nose),
		{"flag": &"gardiennes_nommees"},
	]


## Chloé's guardian's badge (ApexBag; Maïa keeps hers).
static func badge_given() -> void:
	ApexBag.give_insigne()
	Game.set_flag(&"gardiennes_nommees")
	Game.party_changed.emit()


## Watched, no line: Isaure takes the cardboard mask out of her jacket (or out of Maïa's coat pocket,
## if Chloé did not have it: « Tu l'avais gardé ? — Depuis la Forêt. »), looks at Maïa, and puts it
## on: the elastic is broken, she holds it with one hand.
static func _mask_out(cast: Dictionary) -> void:
	var isaure = cast.get("isaure")
	var maia = cast.get("maia")
	if not Game.flag(&"masque_carton_pris"):
		await S.say([
			CS.cue({"who": ISAURE, "text": "Tu l'avais gardé ?"}, func() -> void:
				if isaure and maia is Node2D:
					await CS.reach(isaure, (maia as Node2D).global_position, 10.0, 1.0)),
			{"who": MAIA, "text": "Depuis la Forêt."},
		])
	if isaure is Node2D:
		Stage.look_at((isaure as Node2D).global_position, 0.8)
		if maia is Node2D:
			Stage.turn_to(isaure, (maia as Node2D).global_position)
		if ItemsDB.ITEMS.has("masque_carton"):
			Act.pop((isaure as Node2D).global_position, "masque_carton", 1.0)
		if not Stage.dress(isaure, &"masque_carton"):
			await CS.reach(isaure, (isaure as Node2D).global_position + Vector2(0.0, -30.0), 6.0, 0.8)
	await S.wait(1.0)


## 5 d (3 lines): « Bouh. » « C'est nul. C'est le meilleur « bouh » du monde. » The last mask of the
## Ombre Noire, put on for a laugh.
static func bouh(cast: Dictionary) -> Array:
	var laugh := func() -> void:
		for k in ["maia", "isaure"]:
			var n = cast.get(k)
			if n:
				Stage.hop(n, 2, 6.0)
				Stage.emote(n, "♥")
				await S.wait(0.3)
	return [
		{"who": ISAURE, "text": "Bouh."},
		CS.cue({"who": MAIA, "text": "… C'est nul. C'est le meilleur « bouh » du monde."}, laugh),
		{"who": CHLOE, "text": "(Un masque en carton, tenu à la main parce que l'élastique est cassé. Le premier masque de l'Ombre Noire que quelqu'un met pour rire. Et le dernier.)"},
		{"flag": &"masque_carton_porte"},
	]


## Watched, no line: Brac bursts out laughing, enough to shake the pans; Caillou sneezes on Brac.
static func _laughs(cast: Dictionary) -> void:
	var b = cast.get("brac")
	var caillou = cast.get("caillou")
	if b:
		Stage.hop(b, 3, 10.0)
		Stage.emote(b, "!")
		Stage.shake(0.8, 0.4)
	await S.wait(0.8)
	if caillou is DinoNpc and b is Node2D:
		await (caillou as DinoNpc).walk_to(S.ground_near((b as Node2D).global_position + Vector2(-70.0, 10.0), 2), 80.0)
		Stage.turn_to(caillou, (b as Node2D).global_position)
		Stage.rear(caillou, 0.6)
		Stage.cry(caillou, &"neutre")
		Act.burst((b as Node2D).global_position + Vector2(0.0, -30.0), V.ASH_BITS, 8, 0.8, 0.3)
		Stage.recoil(b, (caillou as Node2D).global_position, 10.0)
	if Game.flag(&"masque_carton_porte") and cast.get("isaure"):
		Stage.dress(cast.get("isaure"), &"")
	await S.wait(1.0)


## Watched, no line: Hélène takes Chloé to the end of the jetty, where she landed the first day from
## Isaure's boat. The little one follows them.
static func _end_of_jetty(cast: Dictionary) -> void:
	var end := A.spot("JETEE_BOUT", Vector2(-60.0, 160.0))
	var h = cast.get("helene")
	if h is Npc:
		(h as Npc).walk_to(S.ground_near(end + Vector2(50.0, 0.0), 2), "down", 60.0)
	Stage.look_at(end, 1.4)
	await CS.chloe_walk(S.ground_near(end, 2), 60.0, 4.0)
	CS.lead_walk(S.ground_near(end + Vector2(-40.0, 10.0), 2), 50.0)
	if h is Node2D:
		Stage.turn_to(Stage.chloe(), (h as Node2D).global_position)
	await S.wait(0.8)


## 5 e (1 line, the page, 3 lines): « Il te manque une page »; page 40; « Quarante pages »; the little
## one's head against Chloé's leg, and far off, on the crater's rim, an immense shape lying down,
## looking at the sea; « Tu as grandi, toi aussi. »
static func page_40(_cast: Dictionary) -> Array:
	var leg := func() -> void:
		var dino := CS.lead()
		if dino:
			await CS.lead_walk(A.chloe_px() + Vector2(-30.0, 8.0), 40.0)
			Stage.bow(dino, 1.4)
			Stage.emote(dino, "♥")
		Stage.look_at(A.chloe_px() + Vector2(-6.0 * S.CELL, -10.0 * S.CELL), 2.4)
	var to_it := func() -> void:
		Stage.look_back(1.2)
		var dino := CS.lead()
		if dino and Stage.chloe():
			Stage.turn_to(Stage.chloe(), (dino as Node2D).global_position)
	return [
		{"who": HELENE, "text": "Il te manque une page. Je l'ai écrite ce matin ; l'encre a séché sur la barque. Je n'écris pas « je t'aime » aux enfants que j'ai trop peu vues. Alors lis entre les lignes. Tu sais faire : tu as mes yeux."},
		DialogueApex.page_40(),
		{"flag": &"found_journal_40"},
		{"flag": &"page_40"},
		{"who": CHLOE, "text": "(Quarante pages. Sur la première, elle pleurait de joie à côté d'Anselme. Sur la dernière, elle est à côté de moi.)"},
		CS.cue({"text": "%s pose sa tête contre la jambe de Chloé. Au loin, sur le bord du cratère, une forme immense s'est couchée, et regarde la mer." % A.starter_name()}, leg),
		CS.cue({"who": CHLOE, "text": "Tu as grandi, toi aussi."}, to_it),
		{"flag": &"epilogue_fini"},
		{"flag": &"post_game"},
	]


## Fade; « Ambrelune »; « L'île est à vous. Les géants du cratère se réveillent un à un… »; back on
## the jetty: the post-game is open. Who stays: Isaure at her boat, Dame Suie on the quay, Joss
## (his coat for Maïa, once), Maïa beside him, Brac (the zone's own).
static func _the_end(cast: Dictionary) -> void:
	await Router.fade_out(2.0)
	await Epilogue.card("Ambrelune", 3.4)
	await Epilogue.card("L'île est à vous. Les géants du cratère se réveillent un à un…", 3.4)
	var keep := ["brac", "maia", "JossJetee", "isaure", "SuieJetee"]   # (Isaure and Dame Suie stay: residents)
	A.clean_up(cast, keep)
	var joss = cast.get("JossJetee")
	if joss is Npc and A.brought(joss):
		(joss as Npc).event = &"joss_jetee"
		(joss as Npc).add_to_group(&"interactable")
	Epilogue.port_residents()
	CS.lead_back()
	Stage.look_back()
	await Router.fade_in(1.2)


# ------------------------------------------------------------------ for the tests

## For the tests: the jetty on any zone (the village brought on round Chloé), 5 a to 5 e, the cards.
static func static_jetee() -> void:
	S.playing += 1
	Game.set_flag(&"epilogue_cabinet")
	await jetty()
	S.playing -= 1
