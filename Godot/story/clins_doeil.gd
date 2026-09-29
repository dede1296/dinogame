extends RefCounted
## Winks at a famous dinosaur film (docs/histoire.md « Clins d'œil ») that are not part of a
## chapter's scenes: homages, never copies — a gesture, an object, a short line said another way;
## no logo, no name from the film, nothing frightening. Roc's walking stick and the mosquito in
## amber (the pebble hidden in the Forêt, shown to Roc), the old expedition car in a tree of the
## Forêt (Roc knows it), the raptor that opens the Cabinet's door,
## the Anurognathus on Ferréol's chest, the two Compsognathus in Mémé Pervenche's kitchen, Tante
## Sirocco and a Dilophosaurus. (Elsewhere: the water that trembles before the Titan,
## story/monts_sanctuaire.gd; Brac's « Petite futée… », story/desert_sanctuaire.gd; « La vie trouve
## toujours un chemin », page 26, data/dialogue_monts.gd; the scenery's lines, world/examine.gd.)
## Flags: canne_vue, canne_n (lines), ambre_moustique_trouve (the pebble: its Pickup),
## roc_moustique, voiture_vue, voiture_n (lines), roc_voiture, raptor_porte_vu, anuro_vu, anuro_n (lines), compsos_cuisine (the day of the last
## visit), sirocco_dilo. No class_name: loaded by Story.clins() when they play.

const S := preload("res://story/story.gd")
const D := preload("res://story/desert.gd")
const CS := preload("res://story/cote_stage.gd")
const GESTES := preload("res://story/foret_gestes.gd")
const CHLOE := "Chloé"
const ROC := "Prof. Roc"
const FERREOL := "Maître Ferréol"
const PERVENCHE := "Mémé Pervenche"
const SIROCCO := "Tante Sirocco"
const ANURO := "Anurognathus"
const LATCH := preload("res://assets/audio/sfx/latch.wav")
## Roc going pale, then back to his colour.
const PALE: Array[Color] = [Color(0.86, 0.9, 0.95), Color(0.8, 0.86, 0.94)]
## The raptors that can open a door (jumping on its handle), if they fit through it.
const DOOR_RAPTORS: Array[StringName] = [&"velociraptor", &"velociraptor_sables", &"deinonychus", &"microraptor", &"utahraptor"]
## None of Chloé's dinos is one: a young Velociraptor of the Plaines, curled up by the warm incubator.
const WILD_RAPTOR := &"velociraptor"
const WILD_RAPTOR_LEVEL := 6
## Mémé Pervenche's kitchen table, in the little lane behind her shop, between it and the
## haberdashery (tiles; tools/zones/havre_dore.gd places it): where Chloé crouches (south of it, a
## little aside: the camera sees the table over her), where the two thieves come from (the forest at
## the lane's end) and where they stand at the table's west end, where Pervenche peeps round her corner.
const TABLE := Vector2(9.75, 4.9)
const HIDE := Vector2(10.15, 5.75)
const COMPSO_FROM: Array[Vector2] = [Vector2(9.4, 1.9), Vector2(10.1, 1.3)]
const COMPSO_AT: Array[Vector2] = [Vector2(9.2, 4.8), Vector2(9.1, 5.4)]
const PERVENCHE_PEEK := Vector2(9.4, 7.8)
const PERVENCHE_CORNER := Vector2(9.4, 9.5)
const PERVENCHE_HOME := Vector2(6.0, 9.5)
const CANNE_AGAIN := [
	"Dans l'œuf d'ambre du pommeau, le moustique a les pattes repliées, comme pour une sieste. Une sieste de cent millions d'années.",
	"Roc ne s'appuie jamais sur sa canne. Il la fait tourner en marchant, et il salue les gens avec.",
	"Le bout de la canne est tout usé d'un côté. Roc tape toujours du même pied quand il réfléchit.",
]
## Where the car sits in its tree, as the camera sees it: this share of the tree's height (m), in tiles
## north of the trunk's foot (measured on the picture: 8.5 tiles for a 12.8 m tree).
const CAR_UP_SHARE := 0.66
const VOITURE_AGAIN := [
	"La vieille voiture est toujours là-haut. Un petit ptérosaure a fait son nid sur le volant.",
	"Le « 04 » de la portière a presque disparu sous la mousse. Les coulures rouges, elles, n'ont pas bougé.",
	"Crr… crr… La portière dit bonjour, comme la dernière fois. Elle est très polie, pour une voiture.",
]
const ANURO_AGAIN := [
	"L'Anurognathus gonfle ses plumes et bat des ailes : « T'as pas dit le mot magique ! »",
	"« T'as pas dit le mot magique ! » Il ne sait dire que ça. Mais il le dit avec beaucoup de conviction.",
	"L'Anurognathus fait semblant de dormir. Chloé fait un pas vers le coffre. Un œil s'ouvre : « T'as pas dit le mot magique ! »",
]


# ------------------------------------------------------------------ Roc's walking stick

## Roc's walking stick against the armchair (StoryProp « CanneRoc », event « canne_roc »): the
## mosquito in its amber knob; the first time Roc is there, he tells where it comes from.
static func canne(who: Node) -> void:
	var prof = _roc_home()
	if Game.flag(&"canne_vue") or prof == null:
		var line: String = ForetCamp.next_line(&"canne_n", CANNE_AGAIN) if Game.flag(&"canne_vue") \
			else "La canne de Roc, appuyée contre le fauteuil. Le pommeau est un œuf d'ambre orange, tout transparent… et dedans, figé depuis des millions d'années, un moustique."
		await S.say([{"text": line}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else chloe.global_position
	var home: Vector2 = prof.global_position
	var hurries := func() -> void:   # (over to her side, from his desk)
		Stage.emote(prof, "!")
		await prof.walk_to(chloe.global_position + Vector2(-80.0, 6.0), "right", 150.0)
		if is_instance_valid(prof):
			prof.face(at)
	await S.say([
		_cue({"text": "La canne de Roc, appuyée contre le fauteuil. Le pommeau est un œuf d'ambre orange, tout transparent… et dedans, figé depuis des millions d'années, un moustique."},
			func() -> void: Stage.bow(chloe, 1.2)),
		_cue({"who": ROC, "text": "Doucement avec le pommeau ! Il a cent millions d'années. À cet âge-là, on a le droit d'être fragile."}, hurries),
		{"who": CHLOE, "text": "Il est tout petit, ce moustique."},
		_cue({"who": ROC, "text": "C'est Hélène qui me l'a offerte, cette canne. Elle disait que ce moustique et moi, on se ressemblait : coincés dans nos vieilles habitudes."},
			func() -> void: prof.face(chloe.global_position)),
		_cue({"text": "Roc fait semblant d'être vexé. Mais il sourit dans sa moustache."}, func() -> void: Stage.emote(prof, "~")),
		{"flag": &"canne_vue"},
	])
	if is_instance_valid(prof):
		prof.walk_to(home, "down", 110.0)   # (back to his desk)
	S.lock(false)


# ------------------------------------------------------------------ the mosquito in amber

## Talking to Roc: the old expedition car seen in the Forêt (_roc_voiture); with the amber pebble
## of the Forêt in the bag, he looks at it very closely, and does not believe a word of Chloé's idea.
## True if he said something.
static func roc() -> bool:
	var said: bool = await _roc_voiture()
	return await _roc_moustique() or said


static func _roc_moustique() -> bool:
	var prof = _roc_home()
	if Game.item_count("ambre_moustique") == 0 or Game.flag(&"roc_moustique") or prof == null:
		return false
	S.lock(true)
	var chloe := Stage.chloe()
	await D._step_aside(prof, 70.0)   # (beside him, not in front: the camera sees what she shows)
	var cast := {}
	var shows := func() -> void:
		Stage.turn_to(chloe, prof.global_position)
		prof.face(chloe.global_position)
		cast["pebble"] = _held_up("ambre_moustique", chloe.global_position.lerp(prof.global_position, 0.5) + Vector2(0.0, 10.0), "AmbreMoustiqueMontre")
	var peers := func() -> void:
		var pebble = cast.get("pebble")
		if pebble is Node2D:
			await GESTES.lean(prof, (pebble as Node2D).global_position, 12.0, 1.8)
	var thinks := func() -> void:
		Stage.emote(prof, "?")
		await Stage.rear(prof, 0.9)
	await S.say([
		_cue({"who": CHLOE, "text": "Professeur ! Regardez ce que j'ai trouvé dans la Forêt !"}, shows),
		_cue({"text": "Roc se penche sur le galet d'ambre, tout près, un œil fermé. Dedans, un moustique, les ailes bien à plat."}, peers),
		{"who": ROC, "text": "Un moustique… Il dort là-dedans depuis cent millions d'années, au moins."},
		{"who": CHLOE, "text": "Et s'il avait piqué un dinosaure, juste avant ? Il y aurait encore un peu de son sang, dedans !"},
		_cue({"text": "Roc se redresse. Il réfléchit. Longtemps."}, thinks),
		{"who": ROC, "text": "Un moustique qui a bu le sang d'un dino… Non. Même moi, je n'y crois pas."},
		_cue({"who": ROC, "text": "Et puis regarde autour de toi : des dinos, l'île en est pleine. On a déjà bien assez de mal à les nourrir."},
			func() -> void: Stage.emote(prof, "~")),
		{"who": ROC, "text": "Garde-le bien. C'est un très joli trésor. Et lui, au moins, il ne pique plus."},
		{"flag": &"roc_moustique"},
	])
	await Stage.take_thing(cast.get("pebble"))
	S.lock(false)
	return true


## Roc in his Cabinet (null when he is out, or somewhere else).
static func _roc_home():
	var prof = S.actor("Roc")
	if prof == null or not is_instance_valid(prof) or Game.flag(&"roc_dehors"):
		return null
	return prof


## A small thing a scene shows, held up at hand's height (Stage.show_thing, raised); null while
## its picture is not drawn.
static func _held_up(kind: String, at_px: Vector2, node_name: String, height_m := 0.8) -> Node2D:
	var thing := Stage.show_thing(kind, at_px, node_name)
	var sprite := Stage.sprite_of(thing)
	if sprite:
		sprite.position.y -= height_m * HeightMap.PX / WorldView.STRETCH
	return thing


# ------------------------------------------------------------------ the car in the tree

## The old expedition car stuck high in a tree of the Forêt (StoryProp « VoitureArbre », event
## « voiture_arbre »): the first time, what Chloé sees (and her lead dino); then a line each time.
static func voiture(who: Node) -> void:
	if Game.flag(&"voiture_vue"):
		await S.say([{"text": ForetCamp.next_line(&"voiture_n", VOITURE_AGAIN)}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else chloe.global_position
	var lead := Game.lead_dino()
	var looks_up := func() -> void:
		Stage.look_at(at + Vector2(0.0, -_car_up(who) * S.CELL), 1.6)   # (up at the car, high in the branches)
		Stage.emote(chloe, "!")
		Stage.recoil(chloe, at, 10.0)
	var tilts := func() -> void:   # its head one way, then the other
		Stage.look_back(0.8)
		var dino := D._companion()
		if dino == null:
			return
		Stage.turn_to(dino, at)
		for i in 2:
			await GESTES.lean(dino, dino.global_position + Vector2(-30.0 if i == 0 else 30.0, -20.0), 8.0, 0.9)
	var creaks := func() -> void:
		Stage.look_at(at + Vector2(0.0, -_car_up(who) * S.CELL), 1.2)
		Stage.shake(1.2, 0.3)
		Stage.emote(chloe, "?")
	var lines: Array = [
		_cue({"text": "Tout en haut d'un grand arbre, coincée dans les branches, il y a… une voiture. Une vieille voiture, verte et jaune, avec de grandes coulures rouges sur le capot. Sur la portière, un gros « 04 »."},
			looks_up),
	]
	if lead:
		lines.append(_cue({"text": "%s la regarde, penche la tête d'un côté, puis de l'autre." % lead.nickname}, tilts))
	lines.append_array([
		{"who": CHLOE, "text": "(Une voiture. Dans un arbre. Sur une île où il n'y a même pas de routes.)"},
		_cue({"text": "Une portière grince dans le vent. Crr… crr… Elle a l'air de dire bonjour."}, creaks),
		_cue({"who": CHLOE, "text": "(Il faudra que je demande au professeur. Il sait toujours tout sur les trucs bizarres.)"},
			func() -> void: Stage.look_back(0.8)),
		{"flag": &"voiture_vue"},
	])
	await S.say(lines)
	Stage.look_back()
	S.lock(false)


## How far north of the tree's foot the camera looks to show the car (tiles), from its picture's height.
static func _car_up(tree: Node) -> float:
	var sprite := Stage.sprite_of(tree) as Sprite2D
	if sprite == null or sprite.texture == null:
		return 4.0
	var height_m: float = sprite.texture.get_height() * absf(sprite.global_scale.y) / HeightMap.PX * WorldView.STRETCH
	return CAR_UP_SHARE * height_m


## Roc, when Chloé tells him about the car in the tree: « Notre vieille voiture ! » True if said.
static func _roc_voiture() -> bool:
	var prof = _roc_home()
	if not Game.flag(&"voiture_vue") or Game.flag(&"roc_voiture") or prof == null:
		return false
	S.lock(true)
	var chloe := Stage.chloe()
	prof.face(chloe.global_position)
	await S.say([
		{"who": CHLOE, "text": "Professeur ! Dans la Forêt, il y a une voiture dans un arbre. Verte et jaune, avec un « 04 » sur la portière."},
		_cue({"who": ROC, "text": "Verte et jaune ? Avec un 04 ?"}, func() -> void: Stage.emote(prof, "!")),
		_cue({"who": ROC, "text": "Notre vieille voiture ! Je me demandais où elle était passée."}, func() -> void: Stage.hop(prof, 2, 7.0)),
		{"who": ROC, "text": "Hélène et moi, on l'avait fait venir par bateau, il y a trente ans, pour l'expédition. On se trouvait très modernes."},
		{"who": ROC, "text": "La première semaine, un Tricératops l'a trouvée à son goût. Il l'a poussée, poussée, poussée… Et un matin, plus de voiture."},
		_cue({"who": ROC, "text": "Dans un arbre, tu dis ? Hélène avait raison : il avait beaucoup plus de force qu'il n'en avait l'air, ce Tricératops."},
			func() -> void: Stage.emote(prof, "~")),
		{"flag": &"roc_voiture"},
	])
	S.lock(false)
	return true


# ------------------------------------------------------------------ the raptor at the door

## Coming out of the Cabinet into Port-Ambre, once, in the daytime after the Sceau de la Forêt: Roc
## follows Chloé out to show her his new lock, shuts the door very proudly… and a raptor opens it
## again from inside, jumping on the handle. « Ils savent ouvrir les portes, maintenant ? »
static func porte_cabinet() -> void:
	if not Game.flag(&"sceau_foret") or Game.flag(&"raptor_porte_vu") or Game.flag(&"roc_dehors") or Game.phase() == &"night":
		return
	var w = S.world()
	var house = S.actor("Cabinet")
	var view := Stage._view()
	if w == null or house == null or view == null:
		return
	var d: Dictionary = view.door(house)
	if d.is_empty() or w.player.global_position.distance_to(d["front"]) > 3.0 * S.CELL:
		return   # (only just out of its door)
	S.lock(true)
	var chloe := Stage.chloe()
	var raptor := _door_raptor(d)
	var actor := _raptor_actor(raptor, d)
	# Chloé makes way; Roc comes out after her (the door stays open behind him).
	await D._chloe_walk((d["front"] as Vector2) + Vector2(-1.5 * S.CELL, 0.9 * S.CELL), 100.0, 1.6)
	var prof := S.stranger("RocPorte", "roc", d["inside"], "down")
	Stage.look_at((d["front"] as Vector2).lerp(chloe.global_position, 0.4) + Vector2(0.0, -20.0))
	if not await Doorway.npc_out(house, prof, 90.0):
		prof.global_position = d["front"]
	await prof.walk_to((d["front"] as Vector2) + Vector2(1.4 * S.CELL, 0.25 * S.CELL), "left", 90.0)   # (the doorway clear)
	prof.face(chloe.global_position)
	Stage.turn_to(chloe, prof.global_position)
	await S.say(_lock_lines(prof, house, d, raptor, actor))
	await S.wait(0.8)
	await S.say(_opens_lines(prof, house, d, raptor, actor))
	await _after_door(prof, house, raptor, actor)
	Game.set_flag(&"raptor_porte_vu")
	Save.save_game()
	S.lock(false)


## Roc shows his lock and shuts the door; behind his back, a raptor of Chloé's slips in.
static func _lock_lines(prof: Npc, house: Node2D, d: Dictionary, raptor: Dictionary, actor: DinoNpc) -> Array:
	var lines: Array = [
		_cue({"who": ROC, "text": "Chloé ! Attends. Regarde : une serrure toute neuve. Trois tours de clé ! Depuis la nuit du vol, plus rien n'entre au Cabinet sans ma permission."},
			func() -> void:
				prof.face(d["front"] - Vector2(0.0, 30.0))
				Stage.emote(prof, "!")),
	]
	var slipped := {}   # (the door shuts once the raptor is in)
	if not raptor["inside"]:
		lines.append(_cue({"text": "Derrière son dos, %s se faufile par la porte ouverte, sans un bruit." % raptor["name"]},
			func() -> void:
				await Doorway.dino_in(house, actor, 150.0, false)
				slipped["in"] = true))
	else:
		slipped["in"] = true
	lines.append_array([
		_cue({"text": "Roc referme la porte d'un geste très fier. Clac."},
			func() -> void:
				await _until(slipped, 3.0)
				prof.face(d["front"])
				GESTES.lean(prof, d["front"], 10.0, 0.8)
				await S.wait(0.3)
				Stage._view().open_door(house, false)
				await S.wait(0.5)
				if is_instance_valid(prof):
					prof.face(Stage.chloe().global_position)),
		{"who": ROC, "text": "Voilà. Rien n'entre, rien ne sort."},
	])
	return lines


## The handle goes down by itself, the door opens again: the raptor comes out, very pleased with
## itself; Roc goes pale.
static func _opens_lines(prof: Npc, house: Node2D, d: Dictionary, raptor: Dictionary, actor: DinoNpc) -> Array:
	var comes_out := func() -> void:
		Audio.play_sfx(LATCH, -4.0)
		Stage.emote(prof, "!")
		Stage.look_at(d["front"], 0.6)
		await S.wait(0.5)
		if await Doorway.dino_out(house, actor, 60.0, 1.4):
			GESTES.stand_in_cry(actor, &"neutre")
			Stage.hop(actor, 2, 8.0)
	var trots := func() -> void:
		Stage.look_back(0.8)
		if is_instance_valid(actor):
			await actor.walk_to(GESTES.beside_chloe(actor, 1.0, 10.0), 110.0)
			Stage.emote(actor, "♥")
	var pale := func() -> void:
		prof.face(actor.global_position if is_instance_valid(actor) else d["front"])
		GESTES.colours(prof, PALE, 1.2)
		Stage.recoil(prof, actor.global_position if is_instance_valid(actor) else d["front"], 10.0)
	var lines: Array = [
		_cue({"text": "Clic. La poignée s'abaisse toute seule… et la porte se rouvre, tout doucement."}, comes_out),
		_cue({"text": ("%s passe la tête dehors, très content de lui, et trottine jusqu'à Chloé." % raptor["name"]) if raptor["dino"]
			else "Un jeune Velociraptor passe la tête dehors, très content de lui, et trottine jusqu'à Chloé."}, trots),
		_cue({"who": ROC, "text": "… Ils savent ouvrir les portes, maintenant ?"}, pale),
	]
	if raptor["dino"]:
		lines.append({"who": CHLOE, "text": "Il a juste sauté sur la poignée, professeur. Elle est très bien, votre poignée."})
	else:
		lines.append_array([
			{"who": CHLOE, "text": "Il n'est pas à nous, celui-là ! Il a dû venir dormir contre la couveuse. C'est tout chaud, là-dedans."},
		])
	lines.append(_cue({"who": ROC, "text": "Je vais la mettre plus haut, cette poignée. Beaucoup plus haut."},
		func() -> void: Stage.emote(prof, "…")))
	return lines


## Roc goes back in (the door shuts); the raptor goes back where it came from.
static func _after_door(prof: Npc, house: Node2D, raptor: Dictionary, actor: DinoNpc) -> void:
	if raptor["from"] == "wild" and is_instance_valid(actor):   # off to the Plaines, north
		actor.walk_to(actor.global_position + Vector2(-2.0 * S.CELL, -3.0 * S.CELL), 150.0)
		Stage.fade_out(actor, 1.2, true)
	elif raptor["from"] == "cabinet" and is_instance_valid(actor):   # (back in before Roc)
		await Doorway.dino_in(house, actor, 120.0, false)
	if not await Doorway.npc_in(house, prof, 90.0):
		await Stage.fade_out(prof, 0.5)
	if is_instance_valid(prof):
		prof.queue_free()
	if raptor["from"] == "cabinet" and is_instance_valid(actor):
		actor.queue_free()
	elif raptor["from"] == "party":
		await GESTES.stand_in_back(actor)
	Stage.look_back(0.5)


## The raptor that opens the door: {"dino" (null: a wild one), "name", "inside" (already in the
## Cabinet, waiting there), "from": "party" (the lead dino, or another of the party: it slips in
## behind Roc's back), "cabinet" (one of the reserve), "wild"}.
static func _door_raptor(d: Dictionary) -> Dictionary:
	var lead := Game.lead_dino()
	var mine: Array = ([lead] if lead else []) + Game.party
	for dino: Dino in mine:
		if _opens_doors(dino, d):
			return {"dino": dino, "name": dino.nickname, "inside": false, "from": "party"}
	for dino: Dino in Game.box:
		if _opens_doors(dino, d):
			return {"dino": dino, "name": dino.nickname, "inside": true, "from": "cabinet"}
	return {"dino": null, "name": "Un jeune Velociraptor", "inside": true, "from": "wild"}


## A raptor that fits through the door (door `d`'s height, with a little room).
static func _opens_doors(dino: Dino, d: Dictionary) -> bool:
	if dino == null or not dino.species().id in DOOR_RAPTORS:
		return false
	return DinoSize.height_m(dino.species(), DinoSize.world_scale(dino)) <= float(d["height"]) - Doorway.HEADROOM


## The raptor as an actor: one of the party stands in beside Chloé (GESTES.stand_in: the lead
## in its very place); one of the reserve, or the wild one, waits inside, out of sight.
static func _raptor_actor(raptor: Dictionary, d: Dictionary) -> DinoNpc:
	if raptor["from"] == "party":
		return GESTES.stand_in(raptor["dino"])
	var dino: Dino = raptor["dino"]
	var actor := CS.stand_in(dino.species().id if dino else WILD_RAPTOR, d["inside"], "RaptorPorte",
		dino.level if dino else WILD_RAPTOR_LEVEL)
	if actor:
		actor.modulate = Doorway.DARK
	return actor


# ------------------------------------------------------------------ the magic word

## The Anurognathus perched on Ferréol's chest (DinoNpc « Anurognathus », event
## « anurognathus_coffre »): whatever Chloé says, « T'as pas dit le mot magique ! », wings
## flapping; Ferréol explains. Afterwards, a line each time.
static func anuro(who: Node) -> void:
	if Game.flag(&"anuro_vu"):
		_flaps(who, 2)
		await S.say([{"text": ForetCamp.next_line(&"anuro_n", ANURO_AGAIN)}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var ferreol = S.actor("Ferreol")
	await D._step_aside(who, 58.0, -1.0)   # (beside the chest, away from Ferréol: the camera sees it)
	await S.say([
		_cue({"text": "Sur le coffre du Comptoir, cerclé de fer et fermé par un cadenas plus gros que la tête de Chloé, un Anurognathus monte la garde. Pas plus gros qu'une pomme."},
			func() -> void:
				Stage.look_at((who as Node2D).global_position)
				Stage.emote(who, "!")),
		{"who": CHLOE, "text": "Bonjour, toi. Qu'est-ce que tu gardes, dans ce gros coffre ?"},
		_cue({"who": ANURO, "text": "T'as pas dit le mot magique !"}, func() -> void: _flaps(who, 2)),
		{"who": CHLOE, "text": "… S'il te plaît ?"},
		_cue({"who": ANURO, "text": "T'as pas dit le mot magique !"}, func() -> void: _flaps(who, 3)),
		{"who": CHLOE, "text": "S'il te plaît, s'il te plaît, avec une baie dessus ?"},
		_cue({"who": ANURO, "text": "T'as pas dit le mot magique ! T'as pas dit le mot magique !"}, func() -> void: _flaps(who, 5)),
		_cue({"who": FERREOL, "text": "Ne vous fatiguez pas, mademoiselle Varenne. Chez moi, le mot magique, c'est « pièces ». Il n'en connaît pas d'autre."},
			func() -> void:
				Stage.look_back()
				if ferreol:
					ferreol.face(chloe.global_position)
				Stage.turn_to(chloe, ferreol.global_position if ferreol else chloe.global_position)),
		{"who": CHLOE, "text": "(Pauvre petit. Il ne sait même pas ce qu'il garde.)"},
		{"flag": &"anuro_vu"},
	])
	S.lock(false)


## It flaps its wings, hopping on the chest's lid, with its cry (`times` hops).
static func _flaps(who: Node, times: int) -> void:
	if not is_instance_valid(who):
		return
	Stage.cry(who, &"neutre")
	var sprite := Stage.sprite_of(who) as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(&"attack"):
		sprite.play(&"attack")   # (its wings spread)
	await Stage.hop(who, times, 7.0)
	if is_instance_valid(sprite):
		sprite.play(&"idle")


# ------------------------------------------------------------------ Mémé Pervenche's kitchen

## Near Mémé Pervenche's kitchen table (StoryTrigger « CuisinePervenche », event
## « cuisine_compsos »), once a day, not at night: a clicking of little claws, Chloé crouches
## behind the table, two Compsognathus come out of the ferns, sniff, steal a biscuit each and run;
## Pervenche peeps round her shop's corner (the first time: her tender word about her two thieves).
static func cuisine(_trigger: Node) -> void:
	if int(Game.flag(&"compsos_cuisine")) == Game.day or Game.phase() == &"night" or not Game.flag(&"havre_arrive"):
		return
	S.lock(true)
	Game.set_flag(&"compsos_cuisine", Game.day)
	var chloe := Stage.chloe()
	var thieves: Array[DinoNpc] = []
	for i in COMPSO_FROM.size():
		var c := CS.stand_in(&"compsognathus", S.at(COMPSO_FROM[i].x, COMPSO_FROM[i].y), "CompsoCuisine%d" % (i + 1))
		if c:
			thieves.append(c)
	await S.say(_thieves_lines(chloe, thieves))
	await S.say(_pervenche_lines(chloe))
	for c in thieves:
		if is_instance_valid(c):
			c.queue_free()
	Save.save_game()
	S.lock(false)


static func _thieves_lines(chloe: Player, thieves: Array[DinoNpc]) -> Array:
	var lead := Game.lead_dino()
	var hides := func() -> void:
		await D._chloe_walk(S.at(HIDE.x, HIDE.y), 110.0, 1.4)
		Stage.turn_to(chloe, S.at(TABLE.x, TABLE.y - 1.0))
		if not Stage.pose(chloe, &"accroupi"):
			Stage.bow(chloe, 1.2)
		if lead and D._companion():
			Stage.bow(D._companion(), 1.2)
	var come_in := func() -> void:
		Stage.look_at(S.at(TABLE.x, TABLE.y + 0.4))
		for i in thieves.size():
			var c := thieves[i]
			Stage.fade_in(c, 0.4)
			c.walk_to(S.at(COMPSO_AT[i].x, COMPSO_AT[i].y), 70.0)
			await S.wait(0.5)
		await S.wait(1.2)
		for c in thieves:
			D._sniff(c)
	var steal := func() -> void:
		if thieves.is_empty():
			return
		if thieves.size() > 1:
			D._look_around(thieves[1])
		await Stage.hop(thieves[0], 2, 26.0)   # (up against the table)
		GESTES.lean(thieves[0], S.at(TABLE.x, TABLE.y), 12.0, 1.2)
	var run_off := func() -> void:
		for i in thieves.size():
			var c := thieves[i]
			c.walk_to(S.at(COMPSO_FROM[i].x - 1.0, COMPSO_FROM[i].y - 0.6), 190.0)
			Stage.fade_out(c, 1.0)
	return [
		_cue({"text": "Clic, clic, clic… Un petit cliquetis de griffes, au bout de la ruelle, du côté des arbres."},
			func() -> void:
				Stage.emote(chloe, "!")
				Stage.turn_to(chloe, S.at(COMPSO_FROM[0].x, COMPSO_FROM[0].y))),
		_cue({"text": "Chloé s'accroupit derrière la table de cuisine, sans un bruit." if lead == null
			else "Chloé s'accroupit derrière la table de cuisine, sans un bruit. %s se fait tout petit, lui aussi." % lead.nickname}, hides),
		_cue({"text": "Deux Compsognathus sortent des fougères. Ils s'arrêtent. Ils reniflent l'air, à droite, à gauche…"}, come_in),
		_cue({"text": "Hop ! Le premier saute contre la table et plonge le museau dans le bocal. L'autre fait le guet."}, steal),
		_cue({"text": "Et les voilà qui filent dans les fougères, un biscuit entre les dents, ravis."}, run_off),
	]


static func _pervenche_lines(chloe: Player) -> Array:
	var keeper = S.actor("Pervenche")
	var peeps := func() -> void:
		Stage.look_back()
		if keeper:   # (round the flower box at her shop's corner)
			keeper.walk_path([S.at(PERVENCHE_CORNER.x, PERVENCHE_CORNER.y), S.at(PERVENCHE_PEEK.x, PERVENCHE_PEEK.y)], "up", 130.0)
	var gets_up := func() -> void:
		Stage.pose(chloe, &"")
		if keeper:
			Stage.turn_to(chloe, (keeper as Node2D).global_position)
	var goes_back := func() -> void:
		if keeper:
			keeper.walk_path([S.at(PERVENCHE_CORNER.x, PERVENCHE_CORNER.y), S.at(PERVENCHE_HOME.x, PERVENCHE_HOME.y)], "down", 130.0)
	if Game.flag(&"compsos_pervenche"):
		return [
			_cue({"who": PERVENCHE, "text": "À demain, mes voleurs ! Et essuyez vos pattes, la prochaine fois !"}, peeps),
			_cue({"text": "Chloé se relève en souriant. Dans le bocal, il manque exactement deux biscuits. Comme tous les jours."}, gets_up),
		]
	return [
		_cue({"text": "Mémé Pervenche passe la tête au coin de sa boutique."}, peeps),
		{"who": PERVENCHE, "text": "Ah, mes deux petits voleurs. Tous les jours à la même heure, ils viennent chiper un biscuit."},
		_cue({"who": CHLOE, "text": "Vous ne les chassez pas ?"}, gets_up),
		{"who": PERVENCHE, "text": "Je fais semblant de ne pas les voir. Eux font semblant de ne pas être vus. Et tout le monde est content."},
		_cue({"who": PERVENCHE, "text": "Allez, relève-toi, ma grande. Et prends-en un, toi aussi : toi, au moins, tu dis merci."}, goes_back),
		{"flag": &"compsos_pervenche"},
	]


# ------------------------------------------------------------------ Tante Sirocco and the Dilophosaurus

## Talking to Tante Sirocco with a Dilophosaurus in the party (once, in the daytime): the real ones
## had neither frill nor venom, she says… and it opens its frill. True if the scene played.
static func sirocco_dilo(who: Node) -> bool:
	if Game.flag(&"sirocco_dilo") or Game.phase() == &"night":
		return false
	var dilo: Dino = null
	for d: Dino in Game.party:
		if d.species().id == &"dilophosaurus":
			dilo = d
			break
	if dilo == null:
		return false
	S.lock(true)
	await D._step_aside(who)   # (beside her, not in front: the camera sees them both)
	var actor = D._little_on_stage(dilo)
	var looks := func() -> void:
		Stage.emote(who, "!")
		if actor:
			Stage.turn_to(who, (actor as Node2D).global_position)
			GESTES.lean(who, (actor as Node2D).global_position, 10.0, 1.6)
	var frill := func() -> void:
		await S.wait(0.3)
		_frill(actor)
		Stage.shake(1.5, 0.2)
	await S.say([
		_cue({"who": SIROCCO, "text": "Par les dents du soleil ! Un Dilophosaurus ! Approche, %s, que je te regarde." % dilo.nickname}, looks),
		{"who": SIROCCO, "text": "Tu sais ce qu'on raconte sur eux, ma caille ? Qu'ils crachent du venin, et qu'ils ouvrent une grande collerette pour faire peur."},
		{"who": SIROCCO, "text": "Balivernes ! Dans les fossiles, pas de collerette, pas de venin. Juste deux jolies crêtes sur la tête, fines comme des coquilles d'œuf."},
		_cue({"text": "%s choisit ce moment pour ouvrir une grande collerette orange, avec un petit cri très fier." % dilo.nickname}, frill),
		_cue({"who": SIROCCO, "text": "…"}, func() -> void: Stage.emote(who, "…")),
		{"who": SIROCCO, "text": "Bon. Les os ne disent pas tout. Et sur cette île, les dinos n'en font qu'à leur tête."},
		{"who": CHLOE, "text": "Et le venin ?"},
		{"who": SIROCCO, "text": "Ça, il n'en a pas. J'en mettrais ma truelle au feu. … Mais méfie-toi quand même : il a l'air d'adorer me contredire."},
		{"flag": &"sirocco_dilo"},
	])
	if actor is Companion:
		D._companion_back()
	else:
		await D._little_back(actor)
	S.lock(false)
	return true


## Its frill wide open (its attack picture) for a moment, with its cry, then as before.
static func _frill(actor) -> void:
	var sprite := Stage.sprite_of(actor) as AnimatedSprite2D
	if sprite == null:
		return
	if actor is Companion:
		(actor as Companion).set_physics_process(false)   # (its own walk would take the picture back)
	Stage.cry(actor, &"attaque")
	sprite.play(&"attack")
	await S.wait(1.6)
	if is_instance_valid(sprite):
		sprite.play(&"idle")


# ------------------------------------------------------------------ staging

## Waits until `token["in"]` is set by a move started under the lines, `max_s` seconds at most.
static func _until(token: Dictionary, max_s: float) -> void:
	var waited := 0.0
	while not token.get("in", false) and waited < max_s:
		await S.wait(0.05)
		waited += 0.05


## A line whose staging starts the moment it shows: `act` is called then (not awaited), so the
## move goes with its bubble, without cutting the dialogue in two.
static func _cue(line: Dictionary, act: Callable) -> Dictionary:
	var cued := line.duplicate()
	var text: String = cued["text"]
	cued.erase("text")
	cued["text_fn"] = func() -> String:
		act.call()
		return text
	return cued
