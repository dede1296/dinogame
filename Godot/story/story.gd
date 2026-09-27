class_name Story
## The story's scenes: what plays when entering a zone (on_zone_entered), and the scenes
## characters start when Chloé talks to them (run, from Npc.event / DinoNpc.event).
## Each scene checks the story flags, so it resumes correctly after a reload.
## Lines are in DialogueDB when they are plain; here, the choreography around them.

const CELL := 48.0
const VOICES := "res://assets/audio/voices/%s.mp3"
const TRAINER_MUSIC := preload("res://assets/audio/music/rivale.ogg")


static func on_zone_entered(zone: StringName) -> void:
	match zone:
		&"port_ambre":
			if not Game.flag(&"prologue_arrived") and not Game.flag(&"prologue_done"):
				await Prologue.arrival()
			else:
				await Plaines.back_to_port()
		&"cabinet":
			await Prologue.cabinet()
			await Plaines.empty_cabinet()
		&"havre_dore":
			await Havre.arrival()
		&"grotte_echos":
			await Grotte.arrival()
		&"foret":
			await Foret.arrival()


## The time of day changed while in zone `zone` (a scene that only happens at night…).
static func on_phase_changed(zone: StringName) -> void:
	Plaines.morning()
	if zone == &"havre_dore":
		await Havre.night()


## A scene started by talking to someone (`who` = the Npc or DinoNpc).
static func run(event: StringName, who: Node) -> void:
	match event:
		&"choose_starter":
			await Prologue.choose_starter(who)
		&"roc":
			if await Plaines.roc_denies():
				return
			var healed: bool = await Prologue.talk_roc()
			var said: bool = await PlainesAnnexes.roc()
			if not said and not healed and Game.flag(&"prologue_done"):
				await Dialogue.run(DialogueDB.chatter(&"roc"))
		&"maia":
			await PlainesAnnexes.maia(who)
		&"nid_chipie":
			await PlainesAnnexes.nest(who)
		&"dormeur":
			await PlainesAnnexes.sleeper()
		&"grand_crane":
			await Plaines.grand_crane()
		&"alpha_plaines":
			await Plaines.alpha(who)
		&"maia_defi":
			await Plaines.maia_duel(who)
		&"shop_herboristerie":
			await Havre.shop(&"herboristerie", who)
		&"shop_mercerie":
			await Havre.shop(&"mercerie", who)
		&"ferreol":
			await Havre.ferreol()
		&"joss":
			await Havre.joss()
		&"relais":
			await Havre.relais()
		&"dresseur_gaspard":
			await Havre.trainer(&"gaspard", who)
		&"dresseur_lilou":
			await Havre.trainer(&"lilou", who)
		&"maia_havre":
			await Ask.menu(&"maia", "Maïa", DialogueDB.chatter(&"maia_havre")[0]["text"], [&"pieces", &"selle", &"monter"])
		&"marchande":
			await Ask.menu(&"marchande", "La marchande", DialogueDB.lines(&"marchande")[0]["text"], [&"pieces", &"selle"])
		&"sbire_grotte_1":
			await Grotte.gustave(who)
		&"sbire_grotte_2":
			await Grotte.chef(who)
		&"proto_corrompu":
			await Grotte.proto(who)
		&"entrepot":
			await Dialogue.run(DialogueDB.lines(&"entrepot"))
		&"griffe_grise":
			await Foret.griffe_grise(who)
		&"clairiere_vide":
			await Foret.clairiere_vide(who)
		_:
			push_error("Scène inconnue : %s" % event)


# ------------------------------------------------------------------ helpers for scenes

## The exploration screen (world.gd), untyped for its player, companion, region.
static func world():
	return Engine.get_main_loop().current_scene


## A character or dino of the current zone, by node name (null when absent). Untyped, so
## scenes can call its own methods (walk_to, face, cry…).
static func actor(node_name: String):
	var w = world()
	if w == null or w.get("region") == null:
		return null
	return w.region.entities.get_node_or_null(node_name)


static func at(x: float, y: float) -> Vector2:
	return Vector2(x, y) * CELL


## Takes control away from the player during a scene (or gives it back).
static func lock(on: bool) -> void:
	var w = world()
	if w and w.get("player"):
		if on:
			w.dismount()   # a scene plays: Chloé on her feet
		w.player.busy = on
		w.player.velocity = Vector2.ZERO


static func say(steps: Array) -> void:
	await Dialogue.run(steps)


static func voice(id: String) -> Dictionary:
	return {"voice": VOICES % id}


static func wait(seconds: float) -> void:
	await Engine.get_main_loop().create_timer(seconds).timeout


## A battle against a trainer (a henchman, Maïa, a trainer of the Relais): their dinos one
## after the other, [species, level, name?] each; no collar, no running away. True if Chloé
## beats them all (on a defeat, the world has already taken her back to the zone's entry).
static func duel(trainer: String, team: Array) -> bool:
	var w = world()
	if w == null or Game.party.is_empty():
		return false
	for member: Array in team:
		var foe := Dino.create(member[0], member[1], member[2] if member.size() > 2 else "")
		var result: String = await w.call(&"_battle", foe, {
			"catch": false, "run": false, "music": TRAINER_MUSIC,
			"intro": "%s envoie %s !" % [trainer, foe.nickname],
		})
		if result != "win":
			return false
	return true


## A character only a scene needs (a passer-by, someone at night): added to the zone, not
## to be talked to.
static func stranger(node_name: String, sheet: String, at_px: Vector2, facing := "down") -> Npc:
	var w = world()
	var n: Npc = load("res://actors/npc.tscn").instantiate()
	n.name = node_name
	n.sheet = load("res://assets/art/characters/%s.png" % sheet)
	n.facing = facing
	n.position = at_px
	w.region.entities.add_child(n)
	n.remove_from_group(&"interactable")
	return n


## Fades the screen out and back in around `between` (a Callable, may be a coroutine).
static func fade_through(between: Callable, time := 0.6) -> void:
	await Router.fade_out(time)
	await between.call()
	await Router.fade_in(time)
