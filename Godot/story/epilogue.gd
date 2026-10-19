class_name Epilogue
## The epilogue (docs/chapitre-9-scenes.md § 4 and 5): three days later at the Cabinet (Hélène in
## Roc's armchair, Roc who has made tea for three days, the red mittens, the notebooks; a knock:
## Isaure on the doorstep, « Je suis à la porte, Anselme. »; the blue cup; what Isaure will do: the
## forges with her own hands, then people by boat, « vivants, et avec rien dans les poches qui
## brille »: the Réserve d'Ambrelune; Isaure drinks); Maïa on the step outside. The next day on the
## jetty of Port-Ambre: the Réserve said to the whole village, Brac night watchman (« ET MOI ? »),
## Chloé and Maïa the first guardians, Isaure in the cardboard mask (« Bouh. »: the first laugh of
## the two Kerval together), page 40 at the end of the jetty where Chloé landed on the first day:
## story/apex_jetee.gd. Here: the Cabinet and the step, the title cards (card) and who stays after
## (residents).
## Flags: epilogue_cabinet, moufles_rendues, isaure_cabinet, tasse_bleue, lettre_lue, reserve_dite.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const A := preload("res://story/apex.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
const HELENE := "Hélène"
const ROC := "Prof. Roc"
const MITTENS := "moufles_helene"
const LETTER := "lettre_isaure"
## The title cards: how long a card stays (s), its fade (s).
const CARD_SECS := 2.6
const CARD_FADE := 0.7


# ------------------------------------------------------------------ entering the Cabinet, the port

## The Cabinet (Story._on_zone_entered, after its own scenes): three days after the crater, the tea,
## the door, the blue cup; Hélène in her armchair afterwards (post-game: to be talked to).
static func cabinet() -> void:
	if Game.flag(&"epilogue_fini"):
		A.tint_helene(A.resident(["HeleneAssise", "Helene"], A.HELENE_SHEETS, _fauteuil(), HELENE, &"helene_cabinet"))
		return
	if not Game.flag(&"apex_fini"):
		return
	if Game.flag(&"reserve_dite"):
		_helene_sitting()   # (she stays in the armchair until the jetty)
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.4)
	var cast := _cabinet_cast()
	if not Game.flag(&"isaure_cabinet"):
		await S.say(tea(cast))
		await _knock(cast)
		await S.say(the_door(cast))
		await _blue_cup(cast)
	else:
		_isaure_sitting(cast)
	await _the_letter(cast)
	await S.say(blue_cup(cast))
	var pick := await Dialogue.choose("", "Elles se regardent. Chloé…", ["Reste.", "Les laisse."])
	await S.say(leaving(pick == 0))
	Save.save_game()
	S.lock(false)
	if w.has_method(&"goto_zone"):
		w.call(&"goto_zone", A.PORT, &"DepuisCabinet")


## Port-Ambre (Story._on_zone_entered, after its own scenes): out of the Cabinet, Maïa on the step
## (4 d); the next entry, or walking onto the jetty, the next morning (5); after it all, who stays
## (Isaure at her boat, Dame Suie on the quay).
static func port() -> void:
	if Game.flag(&"epilogue_fini"):
		port_residents()
		return
	if Game.flag(&"epilogue_cabinet") and not Game.flag(&"epilogue_port"):
		await ApexJetee.jetty()
		return
	if Game.flag(&"reserve_dite") and not Game.flag(&"epilogue_cabinet"):
		await the_step()
		_watch_jetty()   # (not awaited: walking onto the jetty starts the next morning)


# ------------------------------------------------------------------ 4 a, the tea

static func _fauteuil() -> Vector2:
	return A.spot("CABINET_HELENE", Vector2(60.0, -110.0))


## Hélène in Roc's armchair (not to be talked to while the epilogue goes on).
static func _helene_sitting() -> Node2D:
	var h := A.person(["HeleneAssise"], A.HELENE_SHEETS, _fauteuil(), "down", HELENE)
	A.tint_helene(h)
	if h:
		Stage.sit(h)
	return h


static func _cabinet_cast() -> Dictionary:
	var cast := {"helene": _helene_sitting()}
	var roc = S.actor("Roc")
	if roc == null:
		roc = S.stranger("Roc", "roc", A.spot("CABINET_ROC", Vector2(-90.0, -60.0)), "down", ROC)
	cast["roc"] = roc
	return cast


## 4 a (11 lines, 10 without the mittens): the armchair, the tea for three days; the seal watched
## every night; « Elle trouve tout toute seule. C'est très agaçant. Comme vous. »; the red mittens;
## the notebooks brought back by the lady in grey.
static func tea(cast: Dictionary) -> Array:
	var h = cast.get("helene")
	var roc = cast.get("roc")
	var room := func() -> void:
		if h is Node2D:
			Stage.look_at((h as Node2D).global_position, 1.0)
		var dino := CS.lead()
		if dino:   # (the little one goes straight to the incubator and lies down there)
			await CS.lead_walk(A.spot("CABINET_COUVEUSE", Vector2(220.0, -70.0)), 80.0)
			CS.crouch(dino, 0.22, 0.6)
		if roc:
			Stage.emote(roc, "…")
	var cup := func() -> void:
		if roc and h is Node2D:
			await CS.reach(roc, (h as Node2D).global_position, 8.0, 0.8)
	var mittens := func() -> void:
		if ItemsDB.ITEMS.has(MITTENS):
			Act.pop(A.chloe_px(), MITTENS, 0.9)
		if h is Node2D:
			CS.reach(Stage.chloe(), (h as Node2D).global_position, 10.0, 0.8)
	var puts_on := func() -> void:
		mittens_back()
		if h:
			Stage.hop(h, 1, 3.0)
	var crate := func() -> void:
		var box := V.at_node(["CaisseCarnets"], A.spot("CAISSE_CARNETS", Vector2(-160.0, -110.0)))
		if h:
			Stage.turn_to(h, box)
	var lines: Array = [
		CS.cue({"text": "Le Cabinet. Hélène dans le fauteuil de Roc, une couverture sur les genoux. Roc ne dit rien. Il fait du thé. Il en fait depuis trois jours."}, room),
		{"who": CHLOE, "text": "(Elle a fermé les yeux pendant tout le vol. Je ne l'ai dit à personne.)"},
		{"who": HELENE, "text": "Anselme. Tu as surveillé le sceau. Chaque nuit, pendant un an."},
		{"who": ROC, "text": "Vous aviez dit « pas même à Chloé »."},
		{"who": HELENE, "text": "J'avais tort. Elle a tout trouvé toute seule."},
		CS.cue({"who": ROC, "text": "Elle trouve tout toute seule. C'est très agaçant. Comme vous."}, cup),
		{"who": HELENE, "text": "La dernière fois, il m'a boudée jusqu'à la vallée. Là, il me boude jusqu'au thé. Il progresse."},
	]
	if Game.item_count(MITTENS) > 0 and not Game.flag(&"moufles_rendues"):
		lines.append_array([
			CS.cue({"who": CHLOE, "text": "Bertille a dit que tu les avais laissées pour quelqu'un."}, mittens),
			CS.cue({"who": HELENE, "text": "Pour moi. Elle m'en tricotait chaque hiver ; je les perdais chaque printemps. Parfaites."}, puts_on),
		])
	lines.append_array([
		{"who": ROC, "text": "La dame en gris a rapporté vos carnets. Tous. Elle a dit qu'elle refaisait ses tables. J'ai fait du thé."},
		CS.cue({"who": HELENE, "text": "« Presque », c'est un mot merveilleux. Je les ai presque tous brûlés. On brûlera le reste ensemble, elle et moi. Les bons, on les garde."}, crate),
	])
	return lines


## The red mittens go back to Hélène (ApexBag).
static func mittens_back() -> void:
	ApexBag.take(MITTENS)
	Game.set_flag(&"moufles_rendues")
	Game.party_changed.emit()


## Watched, no line: a knock; Roc looks at the door, at Hélène, at the door; he goes.
static func _knock(cast: Dictionary) -> void:
	var roc = cast.get("roc")
	var door := A.spot("CABINET_SEUIL", Vector2(0.0, 110.0))
	CS.sfx("res://assets/audio/sfx/bump.wav", -6.0)
	await S.wait(0.3)
	CS.sfx("res://assets/audio/sfx/bump.wav", -6.0)
	if roc:
		Stage.turn_to(roc, door)
		await S.wait(0.8)
		var h = cast.get("helene")
		if h is Node2D:
			Stage.turn_to(roc, (h as Node2D).global_position)
			await S.wait(0.8)
		Stage.turn_to(roc, door)
		await S.wait(0.5)
		if roc is Npc:
			await (roc as Npc).walk_to(door + Vector2(40.0, -50.0), "down", 70.0)


# ------------------------------------------------------------------ 4 b, the door

## 4 b (7 lines): Isaure on the doorstep, her hair tied; « Je suis à la porte, Anselme. »; « Il y a du
## thé. »; the blue cup: « Vous l'avez gardée. » « Je garde tout. »
static func the_door(cast: Dictionary) -> Array:
	var roc = cast.get("roc")
	var on_step := func() -> void:
		var isaure := A.person(["IsaureCabinet"], A.ISAURE_SHEETS, A.spot("CABINET_SEUIL", Vector2(0.0, 110.0)) + Vector2(-10.0, 0.0), "up", ISAURE)
		cast["isaure"] = isaure
		if isaure and A.brought(isaure):
			isaure.modulate.a = 0.0
			Stage.fade_in(isaure, 0.5)
		Stage.look_at(A.spot("CABINET_SEUIL", Vector2(0.0, 110.0)) + Vector2(0.0, -40.0), 0.8)
	var aside := func() -> void:
		if roc:
			await Stage.recoil(roc, A.spot("CABINET_SEUIL", Vector2(0.0, 110.0)), 30.0)
	var stops := func() -> void:
		if roc:
			Stage.emote(roc, "…")
	return [
		CS.cue({"text": "Roc ouvre. Isaure, sur le seuil. Les cheveux attachés. Elle n'entre pas."}, on_step),
		{"who": ROC, "text": "… Tu venais prendre le thé, au début. Puis tu venais à la porte. Puis plus du tout."},
		{"who": ISAURE, "text": "Je suis à la porte, Anselme."},
		CS.cue({"who": ROC, "text": "Je vois ça. Il y a du thé."}, aside),
		{"who": HELENE, "text": "Anselme. La tasse bleue."},
		CS.cue({"who": ROC, "text": "Laquelle ? … Vous l'avez gardée."}, stops),
		{"who": HELENE, "text": "Je garde tout. C'est écrit quelque part."},
		{"flag": &"isaure_cabinet"},
	]


## Watched, no line: Roc gets up on a chair, takes a blue cup from the top shelf, chipped, blows the
## dust, fills it; Hélène pushes it to the table's edge with her mitten; Isaure looks at it a long
## time. She sits down. She does not drink.
static func _blue_cup(cast: Dictionary) -> void:
	var roc = cast.get("roc")
	var shelf := A.spot("TASSE_ETAGERE", Vector2(-210.0, -140.0))
	var table := A.spot("CABINET_TABLE", Vector2(60.0, -50.0))
	if roc is Npc:
		await (roc as Npc).walk_to(shelf + Vector2(0.0, 50.0), "up", 80.0)
		Stage.hop(roc, 1, 14.0)
		await S.wait(0.6)
		Act.burst(shelf + Vector2(0.0, -20.0), V.ASH_BITS, 8, 1.2, 0.2)
		await S.wait(0.6)
		await (roc as Npc).walk_to(table + Vector2(-40.0, 10.0), "right", 80.0)
	var cup := Stage.show_thing("tasse_bleue", A.spot("TASSE_BLEUE", table + Vector2(16.0, 3.0)), "TasseBleue")
	cast["cup"] = cup
	var h = cast.get("helene")
	if h:
		await CS.reach(h, table, 8.0, 0.8)
	_isaure_sitting(cast)
	await S.wait(1.6)


## Isaure comes in and sits by the table (her sitting picture when drawn).
static func _isaure_sitting(cast: Dictionary) -> void:
	var isaure = cast.get("isaure")
	if isaure == null:
		isaure = A.person(["IsaureCabinet"], A.ISAURE_SHEETS, A.spot("CABINET_ISAURE", Vector2(130.0, -30.0)), "left", ISAURE)
		cast["isaure"] = isaure
	if isaure is Npc:
		await (isaure as Npc).walk_to(A.spot("CABINET_ISAURE", Vector2(130.0, -30.0)), "left", 70.0)
		Stage.sit(isaure)
		Stage.emote(isaure, "…")


# ------------------------------------------------------------------ 4 c, the blue cup

## The letter, if Chloé still has it (3 lines: Isaure reads it in silence), or if it was given at
## the door (1 line); then, watched: she folds it into her jacket, next to the cardboard mask.
static func _the_letter(cast: Dictionary) -> void:
	var isaure = cast.get("isaure")
	var h = cast.get("helene")
	if VolcanPorte._has_letter():
		await S.say([CS.cue({"who": CHLOE, "text": "Elle est pour vous. Je l'ai gardée jusqu'à ce qu'on soit tous dans la même pièce."}, func() -> void:
			if ItemsDB.ITEMS.has(LETTER):
				Act.pop(A.chloe_px(), LETTER, 0.9)
			VolcanPorte._letter_given())])
		if isaure:
			Stage.emote(isaure, "…")
		if h is Node2D:
			Stage.turn_to(h, A.chloe_px())
		await S.wait(2.4)   # (nobody says anything for a page)
		await S.say([
			{"who": ISAURE, "text": "… Tu écris tout."},
			{"who": HELENE, "text": "Tu ne lis rien. On se complète."},
			{"flag": &"lettre_lue"},
		])
	elif Game.flag(&"lettre_isaure_donnee"):
		await S.say([{"who": ISAURE, "text": "Je l'ai lue. Au bord du cratère, pendant qu'elles te descendaient. Tu écris tout."}, {"flag": &"lettre_lue"}])
	else:
		return
	if isaure:
		await CS.reach(isaure, A.px_of(isaure) + Vector2(6.0, 10.0), 6.0, 1.0)
	await S.wait(0.8)


## 4 c (10 lines): « Je ne te pardonne pas aujourd'hui »; the forges with her own hands, Anselme holds
## the ladder; people by boat, « Ton port vivra de ça »; « Une réserve. »; « Je n'avais que toi. Je n'ai
## toujours que toi. » She drinks.
static func blue_cup(cast: Dictionary) -> Array:
	var roc = cast.get("roc")
	var dizzy := func() -> void:
		if roc:
			Stage.tremble(roc, 0.6, 1.5)
	var drinks := func() -> void:
		var isaure = cast.get("isaure")
		var cup = cast.get("cup")
		if isaure:
			await CS.reach(isaure, A.spot("CABINET_TABLE", Vector2(60.0, -50.0)), 8.0, 1.2)
			Stage.bow(isaure, 1.0)
		if cup:
			Stage.take_thing(cup)
	return [
		{"who": HELENE, "text": "Tu as fait peur à des bêtes qui dormaient. Pendant douze ans. Et tu m'as pris mes carnets, et un œuf, et vingt ans."},
		{"who": ISAURE, "text": "Oui."},
		{"who": HELENE, "text": "Je ne te pardonne pas aujourd'hui. Je ne sais pas quel jour. Mais je sais ce que tu vas faire d'ici là."},
		{"who": ISAURE, "text": "Dis."},
		{"who": HELENE, "text": "Tu démontes les forges. Toi, avec tes mains, pas avec des gens payés. Anselme tient l'échelle : il a le vertige."},
		CS.cue({"who": ROC, "text": "Je n'ai pas… Si. J'ai le vertige."}, dizzy),
		{"who": HELENE, "text": "Et après, tu me ramènes des gens. En barque. Des gens qui viennent voir, et qui repartent le soir. Vivants, et avec rien dans les poches qui brille. Ton port vivra de ça. Pas de ce qu'il vend : de ce qu'il montre."},
		{"who": ISAURE, "text": "… Une réserve."},
		{"who": HELENE, "text": "La Réserve d'Ambrelune. J'y pense depuis vingt ans. Il fallait quelqu'un qui connaisse la mer. Je n'avais que toi. Je n'ai toujours que toi."},
		CS.cue({"text": "Isaure prend la tasse bleue. Elle boit. C'est tout. C'est beaucoup."}, drinks),
		{"flag": &"tasse_bleue"},
		{"flag": &"reserve_dite"},
	]


## After the choice (« Reste. » / « Les laisse. »): one line, and Chloé goes out.
static func leaving(stays: bool) -> Array:
	if stays:
		return [{"who": HELENE, "text": "Reste, oui. … Non. Va voir Maïa. Elle est sur la marche depuis une heure, elle compte les Compsognathus."}]
	return [{"who": CHLOE, "text": "(Vingt ans à rattraper. Dont la moitié est de la faute d'Hélène : c'est écrit, page 37.)"}]


# ------------------------------------------------------------------ 4 d, the step

## 4 d (4 lines), outside: Maïa on the Cabinet's step, Moustique on her shoulder, Caillou lying across
## the lane. « Hélène dit non pas fort. » « C'est pire. » Caillou sneezes. « Il reste une page. »
static func the_step() -> void:
	S.lock(true)
	await S.wait(0.5)
	var cast := _step_cast()
	await S.say(step_lines(cast))
	CS.lead_back()
	Stage.look_back()
	Save.save_game()
	S.lock(false)


static func _step_cast() -> Dictionary:
	var step := A.spot("MARCHE_MAIA", Vector2(-70.0, -20.0))
	var maia := A.person(["MaiaMarche"], ["maia_arche", "maia_manteau", "maia"], step, "down", MAIA)
	if maia:
		Stage.sit(maia)
	var bird: DinoNpc = A.stand_in(&"dimorphodon", step + V.SHOULDER, "MoustiqueMarche", V.MOUSTIQUE_LEVEL, 0.8)
	if bird:
		var sprite := Stage.sprite_of(bird)
		if sprite:
			sprite.position.y = -V.SHOULDER_UP + 10.0
			sprite.set_meta(&"stage_rest", sprite.position)
		bird.modulate.a = 1.0
	var caillou := A.dino(["CaillouRuelle"], &"triceratops", A.spot("RUELLE_CAILLOU", Vector2(110.0, 20.0)))
	if caillou:
		CS.crouch(caillou, 0.25, 0.1)
	return {"maia": maia, "moustique": bird, "caillou": caillou}


static func step_lines(cast: Dictionary) -> Array:
	var sneezes := func() -> void:
		var caillou = cast.get("caillou")
		if caillou:
			Stage.rear(caillou, 0.6)
			Stage.cry(caillou, &"neutre")
			Act.burst((caillou as Node2D).global_position + Vector2(0.0, -10.0), V.ASH_BITS, 8, 0.4, 0.4)
	return [
		{"who": MAIA, "text": "Elles vont parler jusqu'à la nuit. Maman ne parle jamais autant. … Enfin, je crois. Je ne l'ai jamais vue avec quelqu'un qui dit non."},
		{"who": CHLOE, "text": "Hélène dit non pas fort."},
		CS.cue({"who": MAIA, "text": "C'est pire. Il éternue toujours quand c'est toi. On ne saura jamais pourquoi. C'est stylé, je trouve."}, sneezes),
		{"who": CHLOE, "text": "(Roc fait du thé. Isaure boit dans la tasse bleue. Le Souverain dort les yeux ouverts, sans peur. … Il reste une page. Elle a toujours laissé une page. Celle-là, elle va l'écrire.)"},
		{"flag": &"epilogue_cabinet"},
	]


## While Chloé is still in the port after the step: walking onto the jetty is the next morning.
static func _watch_jetty() -> void:
	var w = S.world()
	if w == null or w.get("region") == null:
		return
	var region: Node = w.region
	var jetty := A.spot("JETEE_CHLOE", Vector2(0.0, -60.0))
	while is_instance_valid(region) and region.is_inside_tree() and not Game.flag(&"epilogue_port"):
		await S.wait(0.5)
		if not is_instance_valid(region) or S.world() == null or S.world().get("region") != region:
			return
		var chloe := Stage.chloe() as Player
		if chloe and chloe.can_move() and S.playing == 0 and chloe.global_position.distance_to(jetty) < 4.0 * S.CELL:
			S.playing += 1
			await ApexJetee.jetty()
			S.playing -= 1
			return


## After the epilogue, in Port-Ambre: Isaure at her boat, Dame Suie on the quay, to be talked to.
static func port_residents() -> void:
	A.resident(["IsaureJetee", "IsaureBarque"], A.ISAURE_SHEETS, A.spot("JETEE_ISAURE", Vector2(200.0, 30.0)), ISAURE, &"isaure_barque", "left")
	A.resident(["SuieJetee", "SuiePort"], ["dame_suie_sans_lunettes", "dame_suie"], A.spot("JETEE_SUIE", Vector2(-180.0, -240.0)), "Dame Suie", &"suie_port")


# ------------------------------------------------------------------ the people of the epilogue, talked to

## Someone of the jetty (the CARTE agent's nodes, events « <who>_jetee »): before the jetty's scene,
## talking to them starts it (the next morning); after it, Isaure at her boat and Dame Suie on the
## quay have their lines (ApexAutour); Brac's dinos cry.
static func jetty_event(event: StringName, who: Node) -> void:
	if Game.flag(&"epilogue_cabinet") and not Game.flag(&"epilogue_port"):
		await ApexJetee.jetty()
		return
	if not Game.flag(&"epilogue_fini"):
		return
	match event:
		&"isaure_jetee":
			await ApexAutour.isaure(who)
		&"suie_jetee":
			await ApexAutour.suie(who)
		_:
			if who is DinoNpc:
				(who as DinoNpc).cry(&"neutre")
			Stage.emote(who, "…")
			await S.wait(0.8)


## Maïa on the Cabinet's step and Caillou across the lane (events « maia_marche », « caillou_ruelle »):
## the step's scene if it is still to play; Caillou sneezes.
static func step_event(event: StringName, who: Node) -> void:
	if event == &"maia_marche" and Game.flag(&"reserve_dite") and not Game.flag(&"epilogue_cabinet"):
		await the_step()
		_watch_jetty()
		return
	if who is DinoNpc:
		Stage.rear(who, 0.6)
		(who as DinoNpc).cry(&"neutre")
		Act.burst((who as Node2D).global_position + Vector2(0.0, -10.0), V.ASH_BITS, 8, 0.4, 0.4)
	else:
		Stage.emote(who, "…")
	await S.wait(0.8)


## The blue cup, the case of notebooks, Isaure at the table (no line written for them: a look).
static func cabinet_event(_event: StringName, who: Node) -> void:
	if who is Npc and Stage.chloe():
		(who as Npc).face(Stage.chloe().global_position)
	Stage.emote(who, "…")
	await S.wait(0.8)


# ------------------------------------------------------------------ the title cards

## A title card over the black (« Trois jours plus tard », « Ambrelune »…): the words fade in, stay
## `secs`, fade out. The screen should already be black (Router.fade_out). Awaitable.
static func card(text: String, secs := CARD_SECS) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 101   # (above the Router's curtain)
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 120.0
	label.offset_right = -120.0
	label.add_theme_font_size_override("font_size", 44 if text.length() < 24 else 30)
	label.add_theme_color_override("font_color", Color(0.98, 0.9, 0.72))
	label.modulate.a = 0.0
	layer.add_child(label)
	tree.root.add_child(layer)
	var t := label.create_tween()
	t.tween_property(label, "modulate:a", 1.0, CARD_FADE)
	t.tween_interval(secs)
	t.tween_property(label, "modulate:a", 0.0, CARD_FADE)
	await t.finished
	layer.queue_free()


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): the Cabinet three days later on any zone (Hélène and
## Roc brought on round Chloé): the tea, the knock, the door, the cup, the letter, the choice (the
## test picks), without going out.
static func static_cabinet() -> void:
	S.playing += 1
	Game.set_flag(&"apex_fini")
	if ItemsDB.ITEMS.has(MITTENS) and Game.item_count(MITTENS) == 0:
		Game.give_item(MITTENS)
	S.lock(true)
	var cast := _cabinet_cast()   # (in the Cabinet: its own Roc; elsewhere, brought on round Chloé)
	await S.say(tea(cast))
	await _knock(cast)
	await S.say(the_door(cast))
	await _blue_cup(cast)
	await _the_letter(cast)
	await S.say(blue_cup(cast))
	var pick := await Dialogue.choose("", "Elles se regardent. Chloé…", ["Reste.", "Les laisse."])
	await S.say(leaving(pick == 0))
	await S.say(step_lines(_step_cast()))
	A.clean_up(cast)
	S.lock(false)
	S.playing -= 1

