class_name CieuxArche
## Chapter 7, the Cieux Éternels, the Arche du Vent (zone arche_du_vent; docs/histoire.md, ch. 7,
## points 4 to 6, and « La scène du masque »): the landing on the summit, the whole island below,
## the volcano smoking; under the arch, the Masque d'Obsidienne, who was waiting. Its corrupted
## pterosaurs bear sailors' names for the winds (Noroît, Suroît, Grain); calmed, all three. While
## Chloé calmed the last one, two shadows dived on her bag: the four Cœurs are in the Masque's
## hands. A cry: the Roi lands with Maïa on its neck. « Maman. Arrête. » The mask falls. Isaure
## explains without raising her voice, and leaves with the Cœurs, down towards the volcano, on
## foot. The mask stays in the grass. No music: the wind, then no wind.
## Flags: arche_arrivee, arche_piege, masque_arche_battu, coeurs_voles, masque_tombe,
## roc_sceau_cieux, roc_masque_tombe.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const C := preload("res://story/cieux.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const MASQUE := "Le Masque"
const ISAURE := "Isaure"
const ROC := "Prof. Roc"
const MASQUE_NODES := ["MasqueArche", "Masque"]
const MASQUE_SHEET := "masque"
## Isaure once the mask is off: her own sheet without the mask when it is drawn, else her usual one.
const ISAURE_SHEETS := ["isaure_sans_masque", "isaure"]
## (maia_arche: her coat of the Cieux, drawn for this scene by the IMAGES agent.)
const MAIA_SHEETS := ["maia_arche", "maia_manteau", "maia"]
const FALLEN_MASK := "masque_obsidienne"
const OMBRE_MUSIC := MS.OMBRE_MUSIC
## The Masque's pterosaurs (levels 38-44 of the bestiary; to be simulated by the MÉCANIQUES agent).
const TEAM_LEVELS := {"noroit": 42, "suroit": 42, "grain": 43}
const XP_ARRIVEE := 30
const XP_MASQUE := 140
## How far the Roi comes down from (px above the terrace's edge), its size; where Maïa stands
## between them (share of the way from the Masque to Chloé); where Isaure turns up the path of
## cinders (tiles east of it), how fast she walks (px/s), how long her fading takes (s).
const ROI_FROM := Vector2(60.0, -520.0)
const ROI_SIZE := 1.3
const BETWEEN := 0.5
const ISAURE_TURN := 1.0
const ISAURE_SPEED := 48.0
const ISAURE_LEAVES := 9.0
## How far north of the terrace's middle the camera aims to show the whole arch (tiles).
const ARCH_FRAME_UP := 4.5
## How high the birds perch on the arch's crown (px of picture lift: seen in game, 11/10, their feet
## on its top stones; 230 left them floating above it).
const ARCH_PERCH_PX := 195.0
## Where Chloé stops on the terrace, coming up from the landing platform (tiles south of its
## middle), how fast she walks up the ramp (px/s) and for how long at most (s).
const TERRACE_STAND := 4.5
const CLIMB_SPEED := 150.0
const CLIMB_MAX_S := 7.0
## The music is held back for the mask scene (dB), and comes back after.
const HUSH_DB := -40.0
const ROC_CIEUX := [
	"Hélène décollait de nuit. Elle disait que les étoiles sont plus près. Je lui disais que le sol aussi.",
	"Le Roi des Cieux… Elle l'appelait « le Roi », tout court. Comme s'il n'y en avait qu'un. Il n'y en a qu'un.",
]


# ------------------------------------------------------------------ arriving

## The first time on the summit: the landing, the island below, the volcano, the wind in the arch;
## then the Masque, who was waiting (the trap follows at once).
static func arrival() -> void:
	if Game.flag(&"arche_arrivee"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.5)
	var chloe := Stage.chloe()
	var mask = _masque_npc()
	await S.say([CS.cue({"text": _landing_line(chloe)}, func() -> void: Stage.hop(chloe, 1, 8.0))])
	await _up_to_the_terrace(chloe)
	await S.say(_summit(chloe, mask))
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)
	if mask:
		await masque(mask)


## The first line on the summit: the Arche is reached in flight over the needle, or on foot along
## its ridge once the wind lets her by (Vol.came_flying: she crossed the nests' edge in the air).
static func _landing_line(chloe: Node) -> String:
	if Vol.came_flying(chloe):
		return "Le ptérosaure se pose sur la plateforme, tout en haut, et Chloé glisse de son dos. Ses jambes tremblent encore du vol."
	return "Cette fois, le vent de l'aiguille la laisse passer. Chloé grimpe les dernières marches taillées dans la roche, jusqu'à la plateforme. Tout en haut."


## From the landing platform (the zone's way in, at its south edge) up the ramp onto the terrace, a
## few steps south of the arch: the scene plays there, the Masque speaks to her from close by.
static func _up_to_the_terrace(chloe: Node2D) -> void:
	var dest := S.ground_near(C.px("ARCHE") + Vector2(0.0, TERRACE_STAND * S.CELL), 3)
	if chloe.global_position.distance_to(dest) < S.CELL:
		return
	await CS.chloe_walk(dest, CLIMB_SPEED, CLIMB_MAX_S)


## On the terrace: the island below, the volcano, the arch that sings, the Cœurs, the Masque.
static func _summit(chloe: Node2D, mask) -> Array:
	var arch := C.px("ARCHE")
	var below: Vector2 = chloe.global_position + Vector2(0.0, 5.0 * S.CELL)
	var island := func() -> void:
		Stage.look_at(below, 1.8)
	var volcano := func() -> void:
		CS.pulse(below + Vector2(-120.0, 40.0), Color(1.0, 0.45, 0.2), 3, 1.2, 1.6, 6.0)
		Stage.shake(0.8, 0.5)
	var sings := func() -> void:
		# (Aimed above the terrace's middle: the arch stands at its north edge, ~6 m high, so its top
		# shows; aimed at the middle, only its feet did.)
		await CS.pan(arch + Vector2(0.0, -ARCH_FRAME_UP * S.CELL), 2.0)
		CS.sfx("res://assets/audio/sfx/rafale-grave.ogg", -10.0)
	var beats := func() -> void:
		MS.hearts(3, 0.7)
	var there := func() -> void:
		if mask:
			Stage.look_at((mask as Node2D).global_position + Vector2(0.0, 1.0 * S.CELL), 1.2)
			await Stage.fade_in(mask, 1.4)
			Stage.turn_to(mask, chloe.global_position)
		Stage.turn_to(chloe, arch)
		var dino := CS.lead()
		if dino:
			Stage.turn_to(dino, arch)
	return [
		CS.cue({"text": "Depuis ici, on voit l'île entière. Les Monts blancs, la Côte, le Désert rouge, le Marais dans sa brume, la Forêt, la Prairie… en spirale, autour du volcan."}, island),
		CS.cue({"text": "Et le volcan est tout proche. Il fume. À son pied, de petits feux rouges : les forges. Il y en a beaucoup."}, volcano),
		CS.cue({"text": "Au-dessus de la terrasse, une arche de pierre, haute comme une église. Le vent y chante, comme dans la roche du sanctuaire des Vents. Puis, d'un coup, il se tait."}, sings),
		CS.cue({"text": "Dans la sacoche, les quatre Cœurs battent. Vite. Comme avant un orage."}, beats),
		CS.cue({"text": "Et sous l'arche, immobile, une longue cape sombre. Un masque noir, lisse et brillant comme du verre. Il attendait."}, there),
		{"who": CHLOE, "text": "(Le Masque. « Tous les Cœurs d'un coup, au même endroit. » Il savait que je viendrais ici.)" if Game.flag(&"suie_indice")
			else "(Le Masque. Il savait que je viendrais ici.)"},
		{"flag": &"arche_arrivee"},
	]


# ------------------------------------------------------------------ the trap

## The Masque under the arch (Npc « MasqueArche », event « masque_arche »): « Tu es montée. Comme
## elle. »; its three corrupted pterosaurs (calmed: a win); the Cœurs stolen; the Roi with Maïa;
## the mask falls; Isaure leaves; the after. Once the mask has fallen, nothing (the Npc is hidden).
static func masque(who: Node) -> void:
	if Game.flag(&"masque_tombe"):
		return
	var theme: AudioStream = MS.music(OMBRE_MUSIC)
	if not Game.flag(&"arche_piege"):
		S.lock(true)
		if theme:
			Audio.push_music(theme, 1.2)
		await S.say(_waits(who))
		Game.set_flag(&"arche_piege")
		Save.save_game()
		S.lock(false)
	if not Game.flag(&"masque_arche_battu"):
		var rules := {"lose_spawn": C.SPAWN_NIDS}
		if theme:
			rules["music"] = theme
		if not await S.duel(MASQUE, _team(), rules):
			await S.say([{"who": MASQUE, "text": "Reviens quand tes dinos tiendront debout. Je ne bouge pas d'ici. Ni les Cœurs."}])
			return
		Game.set_flag(&"masque_arche_battu")
		Save.save_game()
	if theme:
		Audio.pop_music(1.0)
	await _after_the_battle(who)


## From the stolen Cœurs to the end of the scene (also the test's entry: tools/scenarios).
static func _after_the_battle(who: Node) -> void:
	S.lock(true)
	var cast := {}
	Audio.duck(HUSH_DB, 1.5)
	await S.say(_stolen(who))
	await S.say(_maia_comes(who, cast))
	await S.say(_unmasked(who, cast))
	await S.say(_leaves(cast))
	await S.say(_after(cast))
	Audio.duck(0.0, 2.5)
	_clean_up(who, cast)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_MASQUE)
	Save.save_game()
	S.lock(false)


## « Tu es montée. Comme elle. » Pose la sacoche. No.
static func _waits(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var frame: Vector2 = at.lerp(chloe.global_position, 0.4)
	var looks := func() -> void:
		Stage.look_at(frame, 1.0)
		await CS.chloe_walk(at + Vector2(0.0, 110.0), 80.0, 2.0)
		Stage.turn_to(chloe, at)
	var compass := func() -> void:
		CS.reach(who, at + Vector2(0.0, 20.0), 6.0, 1.2)
		var light := Stage.light_at(at + Vector2(10.0, 0.0), Color(1.0, 0.72, 0.32), 2.0)
		if light:
			var t := light.create_tween()
			t.tween_property(light, "light_energy", 1.8, 0.4)
			t.tween_interval(1.2)
			t.tween_property(light, "light_energy", 0.0, 0.3)
			t.tween_callback(light.queue_free)
	var wings := func() -> void:
		var top: Vector2 = C.px("ARCHE") + Vector2(0.0, -3.0 * S.CELL)
		Stage.look_at(top + Vector2(0.0, -ARCH_FRAME_UP * S.CELL), 1.0)   # (the crown, where they perch)
		for i in 2:
			var side := -1.0 if i == 0 else 1.0
			var bird := C.stand_in(&"hatzegopteryx", top + Vector2(side * 110.0, 0.0), "Vent%d" % i, 0, 1.2)
			if bird:
				_perch(bird)
				bird.modulate = Color(0.75, 0.6, 0.95, 0.0)
				bird.create_tween().tween_property(bird, "modulate:a", 1.0, 0.8)
				Stage.rear(bird, 1.2)
				Stage.cry(bird, &"attaque")
				CS.later(2.6, func() -> void: Stage.fade_out(bird, 0.8, true))
	var lead := Game.lead_dino()
	var lines: Array = [
		CS.cue({"who": MASQUE, "text": "Tu es montée. Comme elle."}, looks),
		{"text": "La voix est grave, étouffée par le masque. Mais moins loin, cette fois. Comme si Chloé l'avait déjà entendue de près."},
		{"who": MASQUE, "text": "Quatre Cœurs dans une sacoche d'écolière. Elle les avait mis à quatre coins de l'île pour que personne ne les réunisse. Et c'est toi qui l'as fait. Pour moi."},
		CS.cue({"text": "Il sort de sa cape le petit boîtier rond, l'ouvre, le regarde. Le referme. Il ne le range pas tout de suite."}, compass),
		{"who": MASQUE, "text": "Pose la sacoche, Chloé. Je ne te ferai rien. Je n'ai jamais rien fait, à toi."},
		{"who": CHLOE, "text": "Non."},
		CS.cue({"text": "Sur l'arche, deux ombres se déplient. Des ptérosaures, immenses, aux veines violettes, qui crient sans s'arrêter."}, wings),
		{"who": MASQUE, "text": "Noroît. Suroît. … Et Grain, qui attend son tour. Ils ont peur de tout, ces trois-là. C'est ce qui les rend rapides."},
		{"who": CHLOE, "text": "(Des noms de vents. Des noms de marin.)"},
	]
	if lead:
		lines.append(CS.cue({"text": "%s se place devant Chloé, et gronde. Il n'a pas peur, lui. Ou il ne le montre pas." % lead.nickname},
			func() -> void:
				var dino := CS.lead()
				if dino:
					CS.lead_walk(chloe.global_position + Vector2(0.0, -40.0), 160.0)
					Stage.rear(dino, 1.0)))
	lines.append({"who": CHLOE, "text": "(Apaiser. Comme les autres. Ils ont peur : c'est tout ce qu'on leur a appris.)"})
	return lines


## Noroît, Suroît (Hatzegopteryx), then Grain (Tupandactylus): fed black amber, they are calmed.
static func _team() -> Array:
	var big := C.species_or(&"hatzegopteryx")
	var small := C.species_or(&"tupandactylus")
	return [
		[big, TEAM_LEVELS["noroit"], "Noroît", {"corrupted": true, "intro": "Le Masque envoie Noroît ! Ses veines violettes luisent dans le vent.",
			"lesson": ["Un dino corrompu ne tombe pas : il s'apaise. Parle-lui, fais confiance à ton dino de départ."]}],
		[big, TEAM_LEVELS["suroit"], "Suroît", {"corrupted": true, "intro": "Le Masque envoie Suroît ! Il crie comme s'il appelait quelqu'un."}],
		[small, TEAM_LEVELS["grain"], "Grain", {"corrupted": true, "long_calm": true,
			"before": [{"who": MASQUE, "text": "Grain. Le dernier. Il est petit, et il a plus peur que les deux autres réunis."}],
			"intro": "Le Masque envoie Grain, qui tremble de partout !"}],
	]


## Calmed, the three of them rest on the arch; the bag is open, light: the four Cœurs against the
## Masque's cape, « comme on tient quelque chose qui a froid ».
static func _stolen(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var rest := func() -> void:
		var top: Vector2 = C.px("ARCHE") + Vector2(0.0, -3.0 * S.CELL)
		Stage.look_at(top + Vector2(0.0, -ARCH_FRAME_UP * S.CELL), 1.0)   # (the crown; « light » looks back)
		for i in 3:
			var bird := C.stand_in(&"hatzegopteryx" if i < 2 else &"tupandactylus", top + Vector2(-120.0 + 120.0 * i, 10.0), "Apaise%d" % i, 0, 1.1 if i < 2 else 0.8)
			if bird:
				_perch(bird)
				Stage.fade_in(bird, 1.0)
				Stage.bow(bird, 1.4)
				CS.later(5.0, func() -> void: Stage.fade_out(bird, 1.5, true))
	var light := func() -> void:
		Stage.look_back(0.8)
		await Stage.bow(chloe, 0.8)
		Stage.emote(chloe, "!")
		Stage.turn_to(chloe, at)
	var holds := func() -> void:
		Stage.look_at(at.lerp(chloe.global_position, 0.35), 1.0)
		Stage.glow(who, MS.HEART_GLOW, 2, 1.0)
		CS.sparkle(at + Vector2(0.0, -10.0), 0.9, 12, 0.2)
		for i in range(1, 5):
			Game.items.erase("coeur_%d" % i)
		Game.party_changed.emit()
	return [
		CS.cue({"text": "Les trois ptérosaures se posent sur l'arche, les ailes pendantes. Leurs veines s'éteignent une à une. Ils ont l'air de dormir debout."}, rest),
		CS.cue({"text": "Chloé reprend son souffle… et sa sacoche est légère. Ouverte. Pendant qu'elle apaisait Grain, deux ombres ont plongé."}, light),
		CS.cue({"text": "Le Masque tient les quatre Cœurs contre sa cape, comme on tient quelque chose qui a froid. Ils battent entre ses mains. Le vent est tombé."}, holds),
		{"who": CHLOE, "text": "Rendez-les."},
		{"who": MASQUE, "text": "Non."},
		{"flag": &"coeurs_voles"},
	]


## A cry above the arch: the Roi comes down, Maïa on its neck, eyes shut, screaming. She slides
## down, falls on her knees, gets up, runs, and stands between them, facing her mother.
static func _maia_comes(who: Node, cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var edge := S.ground_near(C.px("BORD_ROI"), 3)
	if edge.distance_to(chloe.global_position) > 10.0 * S.CELL:
		edge = S.ground_near(chloe.global_position + Vector2(170.0, 20.0), 3)
	var comes := func() -> void:
		Stage.look_at(edge + Vector2(0.0, -120.0), 1.0)
		CS.far_cry("pteranodon", "attaque", -4.0, 0.7)
		var roi := C.stand_in(&"quetzalcoatlus", edge + ROI_FROM, "RoiArche", 0, ROI_SIZE)
		cast["roi"] = roi
		if roi == null:
			return
		C.keep_rest(roi)
		roi.modulate.a = 1.0
		await CS.fly(roi, edge, 2.6, CS.FLY_HEIGHT + 120.0)
		C.land(roi)   # (on the ground, wings folded, still: it waits there for Maïa)
		MS.snow_puff(edge, 14, 0.2, 0.6)
		Stage.shake(2.0, 0.6)
	var slides := func() -> void:
		var maia := S.stranger("MaiaArche", _sheet(MAIA_SHEETS), edge + Vector2(-16.0, 22.0), "down", MAIA)
		cast["maia"] = maia
		if maia == null:
			return
		maia.modulate.a = 0.0
		Stage.fade_in(maia, 0.4)
		await CS.crouch(maia, 0.2, 0.4)
		await S.wait(0.5)
		await CS.get_up(maia, 0.4)
		var between: Vector2 = at.lerp(chloe.global_position, BETWEEN) + Vector2(-20.0, 0.0)
		Stage.look_at(between, 1.0)
		await maia.walk_to(S.ground_near(between, 2), "up", 190.0)
		maia.face(at)
		Stage.turn_to(chloe, maia.global_position)
		if who is Npc:
			(who as Npc).face(maia.global_position)
	return [
		CS.cue({"text": "Un cri, au-dessus de l'arche. Le Quetzalcoatlus Roi descend, les ailes grandes ouvertes… et sur son cou, agrippée, les yeux fermés, quelqu'un hurle."}, comes),
		CS.cue({"text": "Il se pose au bord de la terrasse. Maïa glisse le long de son cou, tombe à genoux, se relève, et court. Elle se plante entre le Masque et Chloé, face au Masque."}, slides),
		{"who": MAIA, "text": "Maman."},
		{"who": MAIA, "text": "Arrête."},
	]


## The mask falls. Isaure. What she says, without raising her voice; what Maïa says; what Chloé
## says (two things, and the cup only if she read page 25).
static func _unmasked(who: Node, cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var falls := func() -> void:
		await S.wait(1.2)
		CS.reach(who, at + Vector2(0.0, -30.0), 6.0, 1.4)
		await S.wait(1.4)
		var isaure := S.stranger("IsaureArche", _sheet(ISAURE_SHEETS), at, "down", ISAURE)
		cast["isaure"] = isaure
		if isaure:
			isaure.modulate.a = 0.0
			Stage.fade_in(isaure, 0.6)
		Stage.fade_out(who, 0.6, false)
		var fallen := Stage.show_thing(FALLEN_MASK, at + Vector2(-36.0, 26.0), "MasqueTombe")
		cast["fallen"] = fallen
	var looks_chloe := func() -> void:
		var isaure = cast.get("isaure")
		if isaure is Npc:
			(isaure as Npc).face(chloe.global_position)
	var looks_down := func() -> void:
		var isaure = cast.get("isaure")
		if isaure:
			Stage.bow(isaure, 1.6)
		await S.wait(1.6)
	var holds_out := func() -> void:
		var maia = cast.get("maia")
		if maia and ItemsDB.ITEMS.has("masque_carton"):
			CS.Act.pop((maia as Node2D).global_position, "masque_carton", 0.9)
		if maia:
			CS.reach(maia, at, 14.0, 2.4)
	var lines: Array = [
		CS.cue({"text": "Le Masque ne bouge pas. Puis une main monte vers le visage. Le masque d'obsidienne glisse, et tombe dans l'herbe rase, sans bruit."}, falls),
		{"text": "Isaure. Les cheveux défaits par le vent. Les yeux de Maïa."},
		{"who": ISAURE, "text": "Tu n'aurais pas dû monter, ma tornade."},
		{"who": MAIA, "text": "Toi non plus."},
		{"who": ISAURE, "text": "… Non. Moi non plus."},
		CS.cue({"text": "Elle regarde Chloé. Pas comme le Masque. Comme sur la barque, le premier jour."}, looks_chloe),
		{"who": ISAURE, "text": "Tu veux savoir pourquoi, moussaillon. Ça tient en une phrase. Et ça ne tient pas du tout."},
		{"who": ISAURE, "text": "Il y a vingt ans, le port a commencé à mourir. Les filets remontaient vides. Les maisons se fermaient une par une. J'ai demandé à Hélène un peu d'ambre. Juste un peu : un bateau, des filets, un hiver."},
		{"who": ISAURE, "text": "Elle a dit non. Pas fort. Elle ne disait jamais rien fort. Elle a dit : « Chacun chez soi, Isaure. » Et elle est retournée à ses œufs."},
		{"who": ISAURE, "text": "Je n'ai pas claqué la porte. Je suis rentrée au port, et j'ai regardé les volets se fermer. Pendant vingt ans. Et puis j'ai fait sans elle. Avec ses notes, puisqu'elle n'en voulait plus. Avec ceux qui payaient. Avec ceux qui avaient faim."},
		{"who": CHLOE, "text": "Avec des dinos qui ont peur."},
		{"who": ISAURE, "text": "Oui. … Oui, moussaillon. Je ne vais pas te dire que non."},
		{"who": ISAURE, "text": "Cette île pourrait tout changer. Pour le port. Pour tous les ports qui meurent. Elle le savait mieux que moi, et elle a préféré l'enfermer. Ce qui dort là-dessous n'est pas un monstre, Chloé : c'est une force. Il suffirait que quelqu'un ait le courage de la tenir."},
		{"who": ISAURE, "text": "Elle a eu peur."},
		{"who": MAIA, "text": "Toi aussi. Tu as reposé ta tasse."},
		CS.cue({"text": "Silence. Isaure regarde les Cœurs, dans ses mains."}, looks_down),
		{"who": ISAURE, "text": "… Oui. Je ne sais plus si je l'ai, ce courage. Mais je suis déjà trop haut pour redescendre, Maïa. Plus on monte…"},
		{"who": MAIA, "text": "Tu me l'as dit pour les falaises."},
		{"who": ISAURE, "text": "C'était pour les falaises."},
	]
	if Game.flag(&"masque_rendu"):
		lines.append_array([
			CS.cue({"text": "Maïa sort de sa poche le masque en carton, plié en deux. Elle le déplie. Elle le tend."}, holds_out),
			{"who": MAIA, "text": "Tu as enlevé le tien. J'avais promis de te rendre celui-là."},
			{"text": "Isaure le regarde longtemps. Elle ne le prend pas."},
			{"who": ISAURE, "text": "Pas aujourd'hui."},
		])
	else:
		lines.append_array([
			{"text": "Maïa ouvre la bouche, et la referme. Elle n'a plus rien à tendre : son masque en carton est resté quelque part sur une falaise."},
			{"who": ISAURE, "text": "Pas aujourd'hui, Maïa. Quoi que ce soit, pas aujourd'hui."},
		])
	return lines


## She leaves by the Descente de Cendre, the Cœurs against her; she does not turn round; she does
## not run. (The cup, if Chloé read page 25: she stops; « Elle écrivait tout. »)
static func _leaves(cast: Dictionary) -> Array:
	var isaure = cast.get("isaure")
	var away := C.px("DESCENTE_CENDRE")
	var goes := func() -> void:
		if not is_instance_valid(isaure):
			return
		var at: Vector2 = (isaure as Node2D).global_position
		# (West along the terrace first, in front of the arch, then up the path of cinders: seen
		# leaving all the way, never behind a pillar of the arch.)
		var turn := Vector2(away.x + ISAURE_TURN * S.CELL, at.y + S.CELL)
		Stage.look_at(turn, 1.6)
		await (isaure as Npc).walk_to(turn, "", ISAURE_SPEED)
		if not is_instance_valid(isaure):
			return
		Stage.fade_out(isaure, ISAURE_LEAVES, false)
		(isaure as Npc).walk_to(away, "", ISAURE_SPEED)
	var stops := func() -> void:
		if is_instance_valid(isaure):
			Stage.emote(isaure, "…")
	var lines: Array = []
	if Game.flag(&"found_journal_25"):
		lines.append_array([
			CS.cue({"text": "Isaure se détourne. Elle fait un pas."}, func() -> void:
				if is_instance_valid(isaure):
					(isaure as Npc).face((isaure as Node2D).global_position + Vector2(-10.0, -40.0))),
			{"who": CHLOE, "text": "Elle a gardé votre tasse."},
			CS.cue({"text": "Isaure s'arrête."}, stops),
			{"who": CHLOE, "text": "Elle l'a écrit. Dans une lettre qu'elle ne vous a jamais envoyée. « Tu n'as pas tort pour le port. Tu as tort sur le moyen. Je garde ta tasse. »"},
			{"text": "Isaure ne se retourne pas. Longtemps."},
			{"who": ISAURE, "text": "… Elle écrivait tout."},
		])
	lines.append_array([
		CS.cue({"text": "Elle s'en va par la Descente de Cendre, vers le volcan, les Cœurs contre elle. Elle ne se retourne pas. Elle ne court pas."}, goes),
		{"who": MAIA, "text": "Elle ne court jamais. Elle dit que ça fait peur aux gens."},
		{"flag": &"masque_tombe"},
	])
	return lines


## The mask in the grass: nobody picks it up. What Maïa keeps; the fifth Cœur; Maïa goes back
## down with the Roi, « les yeux ouverts, cette fois ».
static func _after(cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var maia = cast.get("maia")
	var fallen = cast.get("fallen")
	var looks := func() -> void:
		Stage.look_back(1.2)
		if is_instance_valid(fallen):
			Stage.look_at((fallen as Node2D).global_position, 1.0)
			if is_instance_valid(maia):
				(maia as Npc).face((fallen as Node2D).global_position)
			Stage.turn_to(chloe, (fallen as Node2D).global_position)
			await S.wait(2.0)
		Stage.look_back(1.0)
		if is_instance_valid(maia):
			(maia as Npc).face(chloe.global_position)
	var leaves := func() -> void:
		var roi = cast.get("roi")
		if is_instance_valid(maia) and is_instance_valid(roi):
			await (maia as Npc).walk_to((roi as Node2D).global_position + Vector2(-16.0, 22.0), "up", 120.0)
			Stage.fade_out(maia, 0.6, false)
			await S.wait(0.5)
			CS.fly(roi, (roi as Node2D).global_position + Vector2(60.0, 520.0), 3.0, CS.FLY_HEIGHT + 140.0)
			Stage.fade_out(roi, 2.6, false)
	return [
		CS.cue({"text": "Le masque d'obsidienne reste dans l'herbe. Maïa le regarde. Elle ne le ramasse pas. Chloé non plus."}, looks),
		{"who": MAIA, "text": "Elle l'a enlevé, Chloé. Elle ne l'a pas remis."},
		{"who": MAIA, "text": "Il reste un Cœur. Sous le volcan. Elle sait où il dort. … Nous aussi, maintenant."},
		{"who": CHLOE, "text": "(Les quatre Cœurs… Et la Descente de Cendre, qui mène au volcan. Là où tout a commencé pour Hélène.)"},
		CS.cue({"who": MAIA, "text": "Je redescends avec lui. Les yeux ouverts, cette fois. … Enfin, un. On se retrouve en bas."}, leaves),
		{"who": CHLOE, "text": "(Il y a une page, ici, quelque part. Elle a toujours laissé une page.)"},
	]


## The scene's actors gone; the zone's mask prop, if any, shown from now on (its show_flag).
static func _clean_up(who: Node, cast: Dictionary) -> void:
	for k in ["maia", "roi", "isaure"]:
		var n = cast.get(k)
		if is_instance_valid(n):
			(n as Node).queue_free()
	if is_instance_valid(who):
		(who as Node).queue_free()
	var fallen = cast.get("fallen")
	if is_instance_valid(fallen) and S.actor("MasqueObsidienne") != null:
		(fallen as Node).queue_free()


# ------------------------------------------------------------------ the fallen mask, Roc

## The mask in the grass (StoryProp « MasqueObsidienne », event « masque_obsidienne »).
static func masque_obsidienne(_who: Node) -> void:
	await S.say([
		{"text": "Le masque d'obsidienne, dans l'herbe rase. Lisse, noir, brillant comme du verre. Vu de près, il est tout petit."},
		{"who": CHLOE, "text": "(Personne ne l'a ramassé. Personne ne le ramassera.)"},
	])


## Roc at the Cabinet (Story.run « roc »): the Sceau des Cieux and the Vol; then Isaure and the
## Cœurs. True if he said something.
static func roc() -> bool:
	var todo: Array = []
	if Game.flag(&"sceau_cieux") and not Game.flag(&"roc_sceau_cieux"):
		todo.append(_roc_sceau())
	if Game.flag(&"masque_tombe") and not Game.flag(&"roc_masque_tombe"):
		todo.append(_roc_isaure())
	if todo.is_empty():
		return false
	var prof = S.actor("Roc")
	if prof is Node2D:
		await CS.step_aside(prof, 66.0)
		Stage.turn_to(prof, Stage.chloe().global_position)
	for lines: Array in todo:
		await S.say(lines)
	return true


static func _roc_sceau() -> Array:
	return [
		{"who": ROC, "text": "Le Sceau des Cieux… Et tu voles, maintenant ? Comme elle ?"},
		{"who": ROC, "text": ROC_CIEUX[0]},
		{"who": ROC, "text": ROC_CIEUX[1]},
		{"flag": &"roc_sceau_cieux"},
	]


static func _roc_isaure() -> Array:
	var prof = S.actor("Roc")
	var slumps := func() -> void:   # (his sitting picture is drawn for a chair: here he only sags)
		if prof:
			await Stage.bow(prof, 2.0)
			Stage.emote(prof, "…")
	var straightens := func() -> void:
		if prof:
			Stage.hop(prof, 1, 3.0)
	return [
		CS.cue({"text": "Chloé raconte. L'Arche, les Cœurs, le masque dans l'herbe. Roc pose les deux mains sur le bureau. Il ne dit rien."}, slumps),
		{"text": "Il ne dit rien longtemps."},
		{"who": ROC, "text": "Vingt ans. Elle venait prendre le thé, Isaure, au début. Puis elle venait à la porte. Puis elle ne venait plus. Je n'ai rien demandé. On ne demande jamais."},
		CS.cue({"who": ROC, "text": "Les Kerval reviennent toujours au port, Chloé. … Même elle. Surtout elle."}, straightens),
		{"who": ROC, "text": "Le cinquième Cœur dort sous le volcan, au sanctuaire de Magma. Elle le sait. Toi aussi. Alors ne la laisse pas arriver la première."},
		{"flag": &"roc_masque_tombe"},
	]


# ------------------------------------------------------------------ helpers

## The Masque under the arch: the zone's Npc when it is there, else one made here. Invisible at
## first when the arrival fades it in.
static func _masque_npc():
	for n: String in MASQUE_NODES:
		var mask = S.actor(n)
		if mask != null:
			mask.remove_from_group(&"interactable")
			mask.modulate.a = 0.0
			return mask
	var at := S.ground_near(C.px("ARCHE") + Vector2(0.0, -2.0 * S.CELL), 4)
	var made := S.stranger("MasqueArche", MASQUE_SHEET, at, "down", MASQUE)
	if made:
		made.modulate.a = 0.0
	return made


## A stand-in up on the arch's crown: its picture lifted (and kept there by the moves that put a
## picture back where it rests), standing just behind the arch's front.
static func _perch(bird: Node) -> void:
	var sprite := Stage.sprite_of(bird)
	if sprite == null:
		return
	sprite.position.y = -ARCH_PERCH_PX
	sprite.set_meta(&"stage_rest", sprite.position)


## The first of `sheets` that is drawn (assets/art/characters/<sheet>.png).
static func _sheet(sheets: Array) -> String:
	for s: String in sheets:
		if ResourceLoader.exists("res://assets/art/characters/%s.png" % s):
			return s
	return sheets[-1]


## For the tests (tools/capture.gd « static »): the Masque brought on next to Chloé, on any zone,
## and the scene from the stolen Cœurs on (no battle, no zone of the Cieux needed).
static func static_scene() -> void:
	var chloe := Stage.chloe()
	var at := S.ground_near(chloe.global_position + Vector2(0.0, -110.0), 4)
	var mask := S.stranger("MasqueArche", MASQUE_SHEET, at, "down", MASQUE)
	if mask == null:
		return
	mask.remove_from_group(&"interactable")
	await _after_the_battle(mask)
