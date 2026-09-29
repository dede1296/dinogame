class_name Monts
## Chapter 6, the Monts Gelés (docs/histoire.md, ch. 6), out in the big zone: arriving from the
## Côte (the first snowflakes, the cold, the herds in the valley, a thread of smoke); Bertille,
## the herds' keeper, by her fire under the rock (she knew Hélène, « la dame aux mains
## abîmées », knitted her mittens; she saw the lady in grey go up the glacier with a sled; her
## smallest, Grelot, followed it); Grelot at the foot of the ice walls, too small for them; the
## glacier (the sled's tracks, an empty vial, the wall that grew back overnight); the first clear
## night: the forges' red lights at the foot of the volcano (page 30 shows). The caves are in
## story/monts_grottes.gd, the col and the frost door in monts_col.gd, the sanctuary in
## monts_sanctuaire.gd, Maïa and the end in monts_fin.gd.
## Flags: monts_arrivee, bertille_vue, grelot_vu, grelot_rentre, moufles_helene,
## glacier_arrivee, forges_vues; bertille_n, grelot_n (lines).

const S := preload("res://story/story.gd")
const P := preload("res://story/monts_places.gd")
const MS := preload("res://story/monts_stage.gd")
const CS := preload("res://story/cote_stage.gd")
const A := preload("res://story/monts_ask.gd")
const CHLOE := "Chloé"
const BERTILLE := "Bertille"
## The warm coat without which nobody goes up into the snow (ItemsDB « manteau_duvet »).
const COAT := "manteau_duvet"
const XP_ARRIVEE := 30
const XP_BERTILLE := 30
const XP_GRELOT := 40
const XP_GLACIER := 30
const XP_NUIT := 30
## Coming back out of the sanctuary with the fourth Cœur, Chloé sees Maïa waiting within this many
## tiles (then her scene plays at once; from further away, she goes and talks to her).
const MAIA_SEES := 14.0
## The herd shown from the pass (stand-ins, gone after the scene): [species, offset in tiles].
const HERD := [[&"edmontosaurus", Vector2(-3.0, -1.0)], [&"edmontosaurus", Vector2(0.5, 0.5)], [&"edmontosaurus", Vector2(-1.5, 2.0)],
	[&"pachyrhinosaurus", Vector2(3.0, -0.5)], [&"pachyrhinosaurus", Vector2(4.5, 1.5)]]
## Grelot's level: a little one (DinoSize.GROWN_LEVEL is grown), as in the zone's plan.
const GRELOT_LEVEL := 5
## Where Chloé's lead dino waits while Bertille gives the mittens (px from Chloé): on the side
## away from the fire, a little behind her.
const LEAD_BY_FIRE := Vector2(110.0, -30.0)
## How far the herd ambles while the scene lasts (px), and how slowly (px/s).
const HERD_WALK := Vector2(90.0, 20.0)
const HERD_SPEED := 22.0
const SMOKE: Array[Color] = [Color(0.62, 0.62, 0.64), Color(0.72, 0.72, 0.74), Color(0.5, 0.5, 0.53)]
const FORGE_RED := Color(1.0, 0.35, 0.15)
## Grelot's bell, as the zone has no bell yet (a thin glassy tinkle).
const BELL := "res://assets/audio/sfx/glass.wav"
## Bertille afterwards (the next one each time): what she says before her questions.
const BERTILLE_AGAIN := [
	"Cent douze… cent treize ? Non. Cent douze. C'est toi qui me déconcentres.",
	"Assieds-toi près du feu. Tu as le nez rouge comme une baie. Moi aussi, mais moi, c'est de naissance.",
	"Les Edmontosaurus chantent quand la neige arrive. Pas bien. Mais ils y mettent du cœur.",
	"Hélène disait que les troupeaux se souviennent de tout. Moi, je ne me souviens même plus de mon âge. Soixante ? Soixante et quelque. Les troupeaux le savent.",
]


# ------------------------------------------------------------------ the way up (a warm coat)

## Rule of the island's cold regions (docs/mecaniques.md, « Les régions froides »): no going up
## without a warm coat (Rosalie's, sold at her Mercerie and by Joss on the Côte).
static func has_coat() -> bool:
	return Game.item_count(COAT) > 0


## The way from the Côte up to the Monts (its exit's flag, monts_ouverts) opens once chapter 5 is
## over (Maïa has run away) and Chloé has her coat. Called on entering a zone, after a shop.
static func update_access() -> void:
	if Game.flag(&"maia_enfuie") and has_coat() and not Game.flag(&"monts_ouverts"):
		Game.set_flag(&"monts_ouverts")


## Where to get the coat, and whether Chloé has enough coins (for the lines and the objectives).
static func coat_step() -> String:
	var price: int = ItemsDB.item(COAT)["price"]
	var where := "Joss en vend au bord du lagon (Rosalie lui en a confié « pour ceux qui montent »), et Rosalie à sa Mercerie de Havre-Doré."
	if Game.coins() >= price:
		return "Il te faut un manteau de duvet (%d pièces). %s" % [price, where]
	return "Il te faut un manteau de duvet : %d pièces, et tu en as %d. %s Pour les pièces : les revanches du Relais, et Joss comme Ferréol te reprennent ce qui ne te sert plus (Ferréol rachète aussi les larmes d'ambre en trop)." % [price, Game.coins(), where]


# ------------------------------------------------------------------ arriving

## The first time in the Monts (up from the Côte): snow, the cold, the lead dino meets the snow,
## the herds in the valley below, a thread of smoke under a rock. Afterwards: Maïa waiting in
## front of the sanctuary (once the fourth Cœur is Chloé's), or the first clear night.
static func arrival() -> void:
	if Game.flag(&"monts_arrivee"):
		var maia = S.actor("MaiaMonts")
		if Game.flag(&"coeur_4") and not Game.flag(&"maia_monts_vue") and maia is Node2D \
				and (maia as Node2D).global_position.distance_to(Stage.chloe().global_position) < MAIA_SEES * S.CELL:
			await MontsFin.maia(maia)   # out of the sanctuary, Maïa is waiting there
			return
		if Game.phase() == &"night":
			await night()
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.5)
	var chloe := Stage.chloe()
	var dark: bool = Game.phase() == &"night"
	var ahead: Vector2 = chloe.global_position + Vector2(5.0 * S.CELL, -1.0 * S.CELL)
	var valley := S.at(P.TROUPEAU.x, P.TROUPEAU.y)
	var shelter := S.at(P.ABRI.x, P.ABRI.y)
	var herd := {}
	var white := func() -> void:
		CS.chloe_walk(chloe.global_position + Vector2(40.0, 0.0), 60.0, 0.8)
		Stage.look_at(ahead, 1.4)
	var flakes := func() -> void:
		Game.set_weather(&"snow")
		chloe.face_towards(chloe.global_position + Vector2(0.0, -80.0))
		await S.wait(0.6)
		Stage.emote(chloe, "!")
	var breathes := func() -> void:
		for i in 3:
			MS.breath(chloe, 7)
			await S.wait(0.9)
	var lines: Array = [
		CS.cue({"text": "Le sentier des falaises monte, monte… et d'un coup, le vert s'arrête. Devant Chloé, tout est blanc." if not dark
			else "Le sentier des falaises monte, monte… et d'un coup, sous la lune, tout devient blanc."}, white),
		CS.cue({"text": "Un flocon se pose sur son nez. Puis un autre. Puis mille."}, flakes),
		{"who": CHLOE, "text": "(De la neige… sur une île !)"},
		CS.cue({"text": "Son souffle fait de petits nuages blancs. Le froid pique les joues, les oreilles, le bout des doigts."}, breathes),
	]
	var lead := Game.lead_dino()
	if lead:
		lines.append_array(_meets_the_snow(lead))
	lines.append_array([
		CS.cue({"text": "En bas, dans la vallée, des troupeaux avancent lentement dans la neige : de gros dinos au nez bosselé, et d'autres au bec de canard, qui soufflent de la vapeur par les naseaux."},
			func() -> void: _herd_ambles(herd, valley)),
		{"who": CHLOE, "text": "(Des troupeaux entiers… Ils n'ont pas froid, eux ?)"},
		CS.cue({"text": "Près d'un grand rocher, un filet de fumée monte dans le ciel blanc. Quelqu'un a fait du feu." if not dark
			else "Sous un grand rocher, une petite lueur orange danse dans le noir. Quelqu'un a fait du feu."},
			func() -> void: _smoke(shelter)),
		CS.cue({"text": "Chloé frissonne, et remonte la capuche de son manteau de duvet jusqu'au nez."}, func() -> void:
			Stage.look_back(1.0)
			Stage.tremble(chloe, 1.2, 1.6)),
		{"who": CHLOE, "text": "(Le quatrième Cœur m'attend quelque part là-haut. Heureusement que Rosalie coud chaud.)"},
	])
	if MS.hearts_count() > 0:
		lines.append_array([
			CS.cue({"text": "Dans la sacoche, les Cœurs sont tièdes. Chloé y glisse les mains, et ils battent un peu plus fort, comme pour les réchauffer."},
				func() -> void:
					Stage.bow(chloe, 1.0)
					MS.hearts(2, 1.0)),
			{"who": CHLOE, "text": "(Merci.)"},
		])
	lines.append({"flag": &"monts_arrivee"})
	await S.say(lines)
	for k in herd:
		var n = herd[k]
		if is_instance_valid(n):
			Stage.fade_out(n, 1.2, true)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)
	if dark:
		await night()


## How the lead dino takes the snow, acted out at Chloé's side.
static func _meets_the_snow(lead: Dino) -> Array:
	var dino := CS.lead()
	var chloe := Stage.chloe()
	match lead.species().family:
		&"raptor":
			return [CS.cue({"text": "%s bondit sur un flocon, l'attrape au vol… et regarde dans sa gueule, vexé : le flocon a disparu." % lead.nickname},
				func() -> void:
					if dino == null:
						return
					await Stage.hop(dino, 1, 16.0)
					CS.reach(dino, chloe.global_position + Vector2(40.0, -30.0), 8.0, 0.5)
					await S.wait(0.6)
					Stage.emote(dino, "?"))]
		&"armored":
			var lines: Array = [CS.cue({"text": "La neige tombe sur le dos de %s. Il ne bouge pas. Au bout d'un moment, on dirait un gros rocher enneigé." % lead.nickname},
				func() -> void:
					if dino == null:
						return
					for i in 4:
						MS.snow_puff(dino.global_position + Vector2(randf_range(-20.0, 20.0), 0.0), 6, 0.7, 0.2)
						await S.wait(0.4)
					dino.create_tween().tween_property(dino, "modulate", Color(1.12, 1.14, 1.2), 1.2))]
			if Game.flag(&"rempart_rencontre"):
				lines.append({"who": CHLOE, "text": "(Je ne m'assois pas dessus. J'ai retenu la leçon, avec sa maman.)"})
			lines.append(CS.cue({"text": "Puis il se secoue d'un coup, et Chloé reçoit toute la neige."}, func() -> void:
				if dino:
					dino.modulate = Color.WHITE
					Stage.tremble(dino, 0.5, 3.0)
					MS.snow_puff(chloe.global_position, 16, 1.0, 0.3)
					Stage.emote(chloe, "!")))
			return lines
		&"hadrosaur":
			return [CS.cue({"text": "%s tire la langue pour attraper les flocons. Il éternue : un petit « tuut » sort de sa crête." % lead.nickname},
				func() -> void:
					if dino == null:
						return
					Stage.turn_to(dino, dino.global_position + Vector2(0.0, -60.0))
					await Stage.rear(dino, 1.0)
					Stage.cry(dino, &"neutre")
					Stage.emote(dino, "♪"))]
	return [CS.cue({"text": "%s secoue la tête : il a de la neige plein les écailles, et il n'avait rien demandé." % lead.nickname},
		func() -> void:
			if dino:
				Stage.tremble(dino, 0.6, 2.5)
				MS.snow_puff(dino.global_position, 10, 0.6, 0.3))]


## A few of the herd, down in the valley, ambling through the snow while the scene lasts.
static func _herd_ambles(herd: Dictionary, valley: Vector2) -> void:
	await CS.pan(valley, 1.8)
	for i in HERD.size():
		var at: Vector2 = valley + (HERD[i][1] as Vector2) * S.CELL
		var d := MS.stand_in(HERD[i][0], S.ground_near(at, 3), "TroupeauArrivee%d" % i)
		if d == null:
			continue
		herd[i] = d
		Stage.fade_in(d, 0.8)
		d.walk_to(d.global_position + HERD_WALK + Vector2(0.0, randf_range(-12.0, 12.0)), HERD_SPEED)
		MS.breath(d, 6)
	await S.wait(1.2)
	for k in herd:
		if is_instance_valid(herd[k]) and randf() < 0.6:
			MS.breath(herd[k], 6)


## A thread of smoke rising from the shelter (grey puffs going up).
static func _smoke(at: Vector2) -> void:
	Stage.look_at(at, 1.2)
	for i in 6:
		CS.Act.burst(at + Vector2(randf_range(-8.0, 8.0), -10.0), SMOKE, 6, 1.4 + 0.35 * i, 0.12)
		await S.wait(0.4)


# ------------------------------------------------------------------ the first clear night

## The time of day changed in zone `zone` (Story.on_phase_changed): the forges' night.
static func on_phase(zone: StringName) -> void:
	if zone != &"monts" or Game.phase() != &"night":
		return
	await night()


## The first night in the Monts (once arrived): far to the south-west, red lights blink at the
## foot of the volcano — forges; down in the valley, a corner of paper catches the starlight
## (page 30 shows: forges_vues).
static func night() -> void:
	if not Game.flag(&"monts_arrivee") or Game.flag(&"forges_vues"):
		return
	var w = S.world()
	if w == null or w.get("region") == null or w.region.region_id != &"monts":
		return
	if w.player.busy or Dialogue.active:
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var far: Vector2 = chloe.global_position + Vector2(-7.0, 6.0) * S.CELL   # (south-west: the volcano)
	var page := S.at(P.PAGE_30.x, P.PAGE_30.y)
	var snowing: bool = Game.is_snowing()
	var forges := func() -> void:
		await CS.pan(far, 2.0)
		for i in 3:
			CS.pulse(far + Vector2(randf_range(-90.0, 90.0), randf_range(-30.0, 30.0)), FORGE_RED, 3, 1.2, 2.4, 3.5)
			await S.wait(0.5)
	var lines: Array = [
		CS.cue({"text": "La nuit est tombée sur les Monts. La neige tombe encore, tout doucement, sans bruit." if snowing
			else "La nuit est tombée sur les Monts. Le ciel est si clair qu'on voit toutes les étoiles, et la neige brille sous la lune."},
			func() -> void: Stage.look_at(chloe.global_position + Vector2(0.0, -2.0 * S.CELL), 1.0)),
		CS.cue({"text": "Au sud-ouest, très loin, derrière les crêtes, des lueurs rouges clignotent au pied du volcan. Une, deux… sept. Comme des yeux qui ne dorment pas."}, forges),
		{"who": CHLOE, "text": "(Des feux, en pleine nuit, au pied du volcan… Qui travaille là-bas à cette heure-ci ?)"},
	]
	if not Game.flag(&"found_journal_30"):
		lines.append(CS.cue({"text": "Au sud-ouest de la vallée, sur une petite butte, quelque chose accroche la lumière : un coin de boîte en fer, qui dépasse de la neige."},
			func() -> void:
				Stage.look_at(page, 1.4)
				await S.wait(1.0)
				CS.sparkle(page, 0.3, 14, 0.2)))
	lines.append({"flag": &"forges_vues"})
	await S.say(lines)
	Stage.look_back()
	Game.award_team_xp(XP_NUIT)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Bertille

## Bertille by her fire under the rock (Npc « Bertille », event « bertille »): the meeting (she
## counts her herd; Chloé makes her lose count; she knew Hélène; the lady in grey; Grelot gone;
## the ice walls); Hélène's mittens once Grelot is home; then a line and her questions.
static func bertille(who: Node) -> void:
	if not Game.flag(&"bertille_vue"):
		S.lock(true)
		await S.say(_counting(who))
		await S.say(_knew_her(who))
		await S.say(_the_lady(who))
		Game.award_team_xp(XP_BERTILLE)
		Save.save_game()
		S.lock(false)
		return
	if Game.flag(&"grelot_rentre") and not Game.flag(&"moufles_helene"):
		S.lock(true)
		await S.say(_mittens(who))
		CS.lead_back()
		Save.save_game()
		S.lock(false)
		return
	await A.menu(&"bertille", BERTILLE, _again(), A.bertille_topics())


## What she says now, before her questions: what changed, else the next of her pool.
static func _again() -> String:
	if Game.is_snowing() and Game.weather == &"blizzard":
		return "Par ce temps, on ne compte plus rien. On attend. Assieds-toi, et mets tes mains près du feu."
	if Game.flag(&"maia_alliee") and not Game.flag(&"bertille_maia"):
		Game.set_flag(&"bertille_maia")
		return "Ton amie aux cheveux en bataille est passée avec son gros Tricératops. Il a mangé mon tas de bois. Elle s'est excusée quatre fois. Elle me plaît."
	if Game.flag(&"coeur_4") and not Game.flag(&"bertille_coeur"):
		Game.set_flag(&"bertille_coeur")
		return "Ce matin, toute la montagne a grondé, et mes troupeaux se sont tous tournés vers le col, sans un bruit. Ils savaient, eux."
	if Game.flag(&"roc_col_vu") and not Game.flag(&"bertille_roc"):
		Game.set_flag(&"bertille_roc")
		return "Anselme est passé, gelé comme une truite. Il a mangé trois bols de soupe et il s'est endormi assis. Il ronfle comme un Edmontosaurus enrhumé."
	if Game.flag(&"suie_monts_partie") and not Game.flag(&"bertille_suie"):
		Game.set_flag(&"bertille_suie")
		return "La dame en gris est redescendue. Elle est passée devant mon feu sans me voir. Elle n'a même pas dit pardon pour mes cailloux. Elle avait l'air… ailleurs."
	if Game.phase() == &"night":
		return "Les lueurs rouges, en bas, vers le volcan… Ça fait deux ans qu'elles sont là. Avant, la nuit, le volcan dormait tout noir."
	if not Game.flag(&"grelot_rentre"):
		return "Grelot n'est pas rentré. S'il n'était pas si têtu, je m'inquiéterais. … Je m'inquiète quand même."
	return ForetCamp.next_line(&"bertille_n", BERTILLE_AGAIN)


## She counts her herd aloud, pointing her crook; Chloé's « bonjour » makes her lose count.
static func _counting(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var herd := S.at(P.TROUPEAU.x, P.TROUPEAU.y)
	var shows := func() -> void:
		CS.step_aside(who, 70.0)
		Stage.turn_to(who, herd)
		Stage.look_at(at, 1.0)
	var counts := func() -> void:
		Stage.look_at(at.lerp(herd, 0.4), 1.2)
		for i in 3:
			CS.reach(who, herd, 10.0, 0.6)
			await S.wait(0.8)
	var startled := func() -> void:
		Stage.look_back(0.6)
		Stage.hop(who, 1, 8.0)
		Stage.turn_to(who, chloe.global_position)
		Stage.emote(who, "!")
	return [
		CS.cue({"text": "Sous un grand rocher en surplomb, une femme se tient près d'un feu, emmitouflée jusqu'au nez : une grosse parka doublée de duvet, un bonnet tricoté, un grand bâton de berger posé contre l'épaule."}, shows),
		CS.cue({"who": BERTILLE, "text": "Cent neuf… cent dix… cent onze…"}, counts),
		{"who": CHLOE, "text": "Bonjour !"},
		CS.cue({"who": BERTILLE, "text": "Chut ! … Voilà. Tu m'as fait perdre le compte."}, startled),
		CS.cue({"who": BERTILLE, "text": "Cent douze Edmontosaurus, quarante et un Pachyrhinosaurus, et un têtu. Tous les soirs, je compte. Tous les soirs, quelqu'un me dérange. D'habitude, c'est le têtu."},
			func() -> void: Stage.bow(who, 1.0)),
	]


## She looks at Chloé closer: those eyes. The lady with the damaged hands, her winters by the
## fire, the mittens; last winter, nobody came to spoil her count.
static func _knew_her(who: Node) -> Array:
	var chloe := Stage.chloe()
	var fire := _fire_near(who)
	var leans := func() -> void:
		await CS.reach(who, chloe.global_position, 14.0, 1.6)
		Stage.emote(who, "…")
	var to_the_fire := func() -> void:
		Stage.turn_to(who, fire)
		Stage.bow(who, 1.4)
		CS.Act.burst(fire, CS.Act.SPARKS, 8, 0.5, 0.15)
	var lines: Array = [
		CS.cue({"who": BERTILLE, "text": "Attends. Approche un peu. … Ces yeux-là, je les connais."}, leans),
		{"who": BERTILLE, "text": "Tu es de la famille de la dame aux mains abîmées. Hélène."},
		{"who": CHLOE, "text": "C'est ma grand-mère. Je m'appelle Chloé."},
		{"who": BERTILLE, "text": "Moi, c'est Bertille. Je garde les troupeaux de la vallée. Enfin… ce sont plutôt eux qui me gardent : ils savent où est l'herbe sous la neige. Moi, je sais seulement compter. Presque."},
		{"who": BERTILLE, "text": "Ta grand-mère montait chaque hiver. Elle comptait les troupeaux avec moi, et elle se trompait toujours exprès, pour que je recommence. Comme ça, elle restait plus longtemps près du feu."},
		{"who": BERTILLE, "text": "Elle avait froid aux mains. Toujours. De vieilles brûlures, qu'elle disait. Alors je lui tricotais des moufles. Elle les perdait. Je lui en tricotais d'autres."},
		CS.cue({"who": BERTILLE, "text": "L'hiver dernier, elle n'est pas venue. Personne n'a dérangé mon compte."}, to_the_fire),
		{"who": CHLOE, "text": "(Elle l'attend encore, elle aussi.)"},
	]
	if Game.flag(&"grelot_rentre"):
		lines.append({"who": BERTILLE, "text": "Et ce matin, mon têtu est rentré tout seul, avec le nez plein de neige. Il sentait la petite fille. C'était toi ?"})
	return lines


## The lady in grey and her sled, up the glacier; the herds afraid; Grelot gone after her
## (unless he is home already); the ice walls and who breaks them.
static func _the_lady(who: Node) -> Array:
	var chloe := Stage.chloe()
	var up_north := S.at(P.GLACIER.x, P.GLACIER.y)
	var points := func() -> void:
		Stage.turn_to(who, up_north)
		CS.reach(who, up_north, 12.0, 1.0)
		Stage.look_at(up_north, 1.4)
	var lines: Array = [
		{"who": BERTILLE, "text": "Mais cette semaine, quelqu'un est monté. Une dame en gris, polie comme une vitre. Elle m'a dit bonjour, bonsoir, et pardon d'avoir marché sur mes cailloux."},
	]
	if Game.flag(&"dame_suie_battue"):
		lines.append({"who": CHLOE, "text": "(Dame Suie ! « Nous nous reverrons, là où il fait plus froid »… Elle l'avait dit.)"})
	lines.append_array([
		CS.cue({"who": BERTILLE, "text": "Elle avait un traîneau plein de caisses qui tintaient. Enfin, c'est un grand dino aux griffes comme des faux qui le tirait. Elle est montée au glacier, là-haut, au nord."}, points),
		{"who": BERTILLE, "text": "Mes troupeaux ont eu peur toute la nuit. Ça sentait la cheminée froide."},
	])
	if not Game.flag(&"grelot_rentre"):
		lines.append_array([
			CS.cue({"who": BERTILLE, "text": "Et depuis, mon têtu a disparu. Grelot. Mon plus petit Pachyrhinosaurus. Il suit tout ce qui sent bizarre : il a dû suivre le traîneau."},
				func() -> void:
					Stage.look_back(0.8)
					Stage.turn_to(who, chloe.global_position)),
			{"who": CHLOE, "text": "Je vais le chercher !"},
			{"who": BERTILLE, "text": "Tu le reconnaîtras : il a un grelot autour du cou. Je le lui ai mis pour le retrouver dans les tempêtes. Ça marche une fois sur deux. L'autre fois, il fait exprès de ne pas bouger."},
		])
	else:
		lines.append(CS.cue({"who": BERTILLE, "text": "Même Grelot est rentré en tremblant. Pourtant, il n'a peur de rien. Sauf des flocons trop gros."},
			func() -> void:
				Stage.look_back(0.8)
				Stage.turn_to(who, chloe.global_position)))
	var charge := MS.charger()
	lines.append({"who": BERTILLE, "text": "Pour monter au glacier, il y a des murs de glace. Mes grands Pachyrhinosaurus cassent la glace du lac tous les matins, d'un coup de nez, pour boire."})
	if charge:
		lines.append({"who": BERTILLE, "text": "Ton %s a l'air d'avoir la tête dure. Ça ira." % charge.nickname})
	else:
		lines.append({"who": BERTILLE, "text": "Toi, il te faudrait un dino qui charge. " + MS.charge_step()})
	lines.append_array([
		{"who": BERTILLE, "text": "Et reviens avant la nuit. Ou après. Mais reviens. Il y a de la soupe."},
		{"flag": &"bertille_vue"},
	])
	return lines


## Once Grelot is home: Hélène's mittens, left here the winter before last. « Elle n'oubliait
## jamais rien. Alors je crois qu'elle les a laissées pour quelqu'un. »
static func _mittens(who: Node) -> Array:
	var chloe := Stage.chloe()
	var little = S.actor("GrelotVallee")
	if little == null:   # (home since the zone was loaded: the zone's own is not there yet)
		little = MS.stand_in(&"pachyrhinosaurus", S.ground_near(chloe.global_position + Vector2(-170.0, 50.0), 3), "GrelotScene", GRELOT_LEVEL)
	var rushes := func() -> void:
		await CS.step_aside(who, 70.0)   # (beside Bertille, not in front of her)
		# Her lead dino out of the fire's way: on her other side, a little behind (Grelot comes in front).
		CS.lead_walk(S.ground_near(chloe.global_position + LEAD_BY_FIRE, 2), 150.0)
		if little is DinoNpc:
			Stage.fade_in(little, 0.3)
			await (little as DinoNpc).walk_to(chloe.global_position + Vector2(46.0, 18.0), 120.0)
			Stage.turn_to(little, chloe.global_position)
			CS.reach(little, chloe.global_position, 10.0, 0.6)
			Stage.emote(little, "♥")
			CS.sfx(BELL, -10.0)
	var takes_out := func() -> void:
		Stage.turn_to(who, chloe.global_position)
		await Stage.bow(who, 1.0)
		await CS.reach(who, chloe.global_position, 12.0, 0.9)
		if ItemsDB.ITEMS.has("moufles_helene"):
			CS.Act.pop(chloe.global_position, "moufles_helene", 0.9)
	var puts_on := func() -> void:
		await CS.reach(chloe, chloe.global_position + Vector2(0.0, -20.0), 6.0, 0.8)
		Stage.hop(chloe, 1, 6.0)
		Stage.emote(chloe, "♥")
	var lines: Array = [
		CS.cue({"text": "Grelot déboule dans la neige, son grelot tintant à chaque pas, et pousse la jambe de Chloé du bout du nez."}, rushes),
		{"who": BERTILLE, "text": "Il dit merci. Ou alors il réclame un biscuit. Chez lui, c'est souvent pareil."},
		{"who": BERTILLE, "text": "Attends, j'ai quelque chose pour toi."},
		CS.cue({"text": "Bertille fouille dans un vieux sac, sous le rocher, et en sort une paire de moufles rouges, tricotées main, un peu feutrées, reprisées au pouce."}, takes_out),
		{"who": BERTILLE, "text": "Celles d'Hélène. Elle les a laissées ici, l'avant-dernier hiver. Elle n'oubliait jamais rien, ta grand-mère. Alors je crois qu'elle les a laissées pour quelqu'un."},
		CS.cue({"text": "Chloé enfile les moufles. Elles sont trop grandes. Elles sont parfaites."}, puts_on),
		{"who": CHLOE, "text": "Merci, Bertille."},
		{"who": BERTILLE, "text": "Ne me remercie pas. Garde les mains au chaud. C'est tout ce qu'elle voulait, je crois, pour les gens qu'elle aimait."},
		{"flag": &"moufles_helene"},
	]
	if ItemsDB.ITEMS.has("moufles_helene"):
		Game.give_item("moufles_helene")
	return lines


## The fire by Bertille (a « feu_camp » prop within a few tiles), else just in front of her.
static func _fire_near(who: Node) -> Vector2:
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else Vector2.ZERO
	var w = S.world()
	if w and w.get("region"):
		for n in w.region.entities.get_children():
			if n is Prop and n.get("kind") == "feu_camp" and (n as Node2D).global_position.distance_to(at) < 5.0 * S.CELL:
				return (n as Node2D).global_position
	return S.at(P.FEU_BERTILLE.x, P.FEU_BERTILLE.y)


# ------------------------------------------------------------------ Grelot

## Grelot, Bertille's smallest Pachyrhinosaurus (DinoNpc « Grelot » at the foot of the ice walls,
## event « grelot »): he charges the wall, BONG, bounces off, again; Chloé sends him home. At
## home (« GrelotVallee »): a line each time.
static func grelot(who: Node) -> void:
	if Game.flag(&"grelot_rentre"):
		var pool := ["Grelot fonce sur Chloé, s'arrête juste avant, et lui pousse la jambe du nez. Son grelot tinte.",
			"Grelot mâchonne un brin d'herbe sorti de sous la neige. Il le recrache. Il le remâchonne.",
			"Grelot essaie de charger un flocon. Il rate. Il fait comme si c'était exprès."]
		var line := ForetCamp.next_line(&"grelot_n", pool)
		await S.say([CS.cue({"text": line}, func() -> void:
			CS.reach(who, Stage.chloe().global_position, 10.0, 0.6)
			CS.sfx(BELL, -12.0))])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var wall := _wall_near(at)
	var charges := func() -> void:
		CS.step_aside(who, 80.0)
		Stage.look_at(at.lerp(wall, 0.5), 0.8)
		Stage.turn_to(who, wall)
		await S.wait(0.4)
		await Stage.lunge(who, wall, 1.4)
		MS.snow_puff(at.lerp(wall, 0.6), 12, 0.4)
		CS.sfx(BELL, -8.0)
	var bounces := func() -> void:
		await Stage.recoil(who, wall, 16.0)
		await S.wait(0.4)
		Stage.tremble(who, 0.5, 2.5)
		Stage.emote(who, "~")
	var again := func() -> void:
		Stage.turn_to(who, wall)
		await Stage.lunge(who, wall, 1.2)
		MS.snow_puff(at.lerp(wall, 0.6), 10, 0.4)
		CS.sfx(BELL, -8.0)
		Stage.recoil(who, wall, 10.0)
	var sniffs := func() -> void:
		await MS.kneel()
		Stage.turn_to(who, chloe.global_position)
		await CS.reach(who, chloe.global_position, 12.0, 1.2)
	var home := S.at(P.BERTILLE.x, P.BERTILLE.y)
	var leaves := func() -> void:
		MS.stand_up(chloe)
		Stage.turn_to(who, home)
		if who is DinoNpc:
			(who as DinoNpc).walk_to(at + (home - at).normalized() * 5.0 * S.CELL, 110.0)
		for i in 4:
			CS.sfx(BELL, -10.0 - 3.0 * i)
			await S.wait(0.5)
		Stage.fade_out(who, 0.8, false)
	var lines: Array = [
		CS.cue({"text": "Au pied du mur de glace, un petit Pachyrhinosaurus prend son élan… et fonce, tête baissée."}, charges),
		CS.cue({"text": "BONG. Il rebondit en arrière, les pattes écartées, et secoue la tête. Le mur n'a pas une égratignure."}, bounces),
		CS.cue({"text": "Il recule, gratte la neige, reprend son élan… BONG."}, again),
	]
	if Game.flag(&"bertille_vue"):
		lines.append_array([
			{"who": CHLOE, "text": "Tu dois être Grelot. (Il veut suivre le traîneau. Mais il est bien trop petit pour ce mur.)"},
			CS.cue({"text": "Chloé s'agenouille. Grelot vient la renifler : ses mains sentent encore la fumée du feu de Bertille. Il tend sa petite collerette."}, sniffs),
			{"who": CHLOE, "text": "Bertille dit que la soupe refroidit."},
		])
	else:
		lines.append_array([
			{"who": CHLOE, "text": "(Un grelot autour du cou, noué d'un ruban rouge… Quelqu'un tient beaucoup à lui.)"},
			CS.cue({"text": "Chloé s'agenouille. Le petit vient la renifler, longtemps, puis il regarde vers la vallée, là où monte un filet de fumée."}, sniffs),
			{"who": CHLOE, "text": "Rentre chez toi, petit. Quelqu'un doit t'attendre, là-bas."},
		])
	lines.append_array([
		CS.cue({"text": "Grelot regarde le mur. Il regarde Chloé. Il regarde la vallée. Puis il part au petit trot, et son grelot tinte jusqu'en bas."}, leaves),
		{"flag": &"grelot_vu"},
		{"flag": &"grelot_rentre"},
	])
	if MS.charger() == null:
		lines.append({"who": CHLOE, "text": "(Pour ce mur-là, il faudrait un Pachyrhinosaurus. Un grand. Ou un dino qui charge aussi fort.)"})
	await S.say(lines)
	if is_instance_valid(who):
		who.queue_free()
	Stage.look_back()
	Game.award_team_xp(XP_GRELOT)
	Save.save_game()
	S.lock(false)


## The ice wall nearest to `px` (an Obstacle « MurGlace… » of the zone), else a little north.
static func _wall_near(px: Vector2) -> Vector2:
	var best := px + Vector2(0.0, -2.0 * S.CELL)
	var best_d := 8.0 * S.CELL
	var w = S.world()
	if w == null or w.get("region") == null:
		return best
	for n in w.region.entities.get_children():
		if n is Node2D and String(n.name).begins_with("MurGlace") and (n as Node2D).global_position.distance_to(px) < best_d:
			best_d = (n as Node2D).global_position.distance_to(px)
			best = (n as Node2D).global_position
	return best


# ------------------------------------------------------------------ the glacier

## The glacier (StoryTrigger « GlacierArrivee », event « glacier_arrivee »): blue ice that
## creaks far below; the sled's runners and huge clawed prints; an empty vial (« Givre, n° 3 »);
## the ice wall scored by claws, the hole already grown back overnight.
static func glacier(_trigger: Node) -> void:
	if Game.flag(&"glacier_arrivee"):
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at := chloe.global_position
	var wall := _wall_near(at + Vector2(0.0, -3.0 * S.CELL))
	var creaks := func() -> void:
		Stage.look_at(at + Vector2(0.0, -3.0 * S.CELL), 1.2)
		await S.wait(0.6)
		MS.crack(2.5)
		Stage.emote(chloe, "!")
	var tracks := func() -> void:
		Stage.look_back(0.8)
		var dino := CS.lead()
		if dino:
			CS.D._sniff(dino)
		for i in 6:   # the runners' two lines, towards the wall
			var p: Vector2 = at.lerp(wall, (i + 1.0) / 7.0)
			MS.snow_puff(p + Vector2(-14.0, 0.0), 4, 0.05, 0.08)
			MS.snow_puff(p + Vector2(14.0, 0.0), 4, 0.05, 0.08)
			await S.wait(0.25)
	var vial := {}
	var finds := func() -> void:
		var spot: Vector2 = at + Vector2(34.0, 22.0)
		vial["thing"] = Stage.show_thing("fiole_vide", spot, "FioleVide")
		await MS.kneel()
		await CS.reach(chloe, spot, 10.0, 0.8)
	var reads := func() -> void:
		MS.stand_up(chloe)
		Stage.take_thing(vial.get("thing"))
	var the_wall := func() -> void:
		Stage.look_at(wall, 1.2)
		await S.wait(1.0)
		CS.sparkle(wall, 1.0, 6, 0.4)
	var lines: Array = [
		CS.cue({"text": "Le glacier. Une rivière de glace bleue, figée entre deux montagnes. Sous les pieds de Chloé, elle craque, très loin dessous, comme une vieille maison."}, creaks),
		CS.cue({"text": "Dans la neige, deux longues traces bien droites : les patins d'un traîneau. Et à côté, des empreintes énormes, avec de longues griffes, comme des faux."}, tracks),
		{"who": CHLOE, "text": "(Le traîneau de la dame en gris… et le dino qui le tirait.)"},
		CS.cue({"text": "À moitié enfoncée dans la neige, une petite fiole vide. Sur l'étiquette, d'une écriture fine et droite : « Givre, n° 3. Deux gouttes. Pas une de plus. »"}, finds),
	]
	if Game.flag(&"dame_suie_battue"):
		lines.append(CS.cue({"who": CHLOE, "text": "(Dame Suie. Elle mesure, elle dose, elle note… Qu'est-ce qu'elle vient doser, ici, dans la glace ?)"}, reads))
	else:
		lines.append(CS.cue({"who": CHLOE, "text": "(Quelqu'un qui compte ses gouttes… Qu'est-ce qu'on vient doser, ici, dans la glace ?)"}, reads))
	lines.append(CS.cue({"text": "Devant, un mur de glace barre le passage. Des marques de griffes géantes le rayent de haut en bas… et le trou qu'elles avaient creusé est déjà refermé. La glace a repoussé pendant la nuit."}, the_wall))
	var charge := MS.charger()
	if charge:
		lines.append({"who": CHLOE, "text": "(%s pourrait l'enfoncer d'un bon coup de tête.)" % charge.nickname})
	else:
		lines.append({"who": CHLOE, "text": "(Il faudrait une tête bien dure pour passer…)"})
		lines.append({"text": MS.charge_step()})
	lines.append({"flag": &"glacier_arrivee"})
	await S.say(lines)
	Stage.look_back()
	Game.award_team_xp(XP_GLACIER)
	Save.save_game()
	S.lock(false)
