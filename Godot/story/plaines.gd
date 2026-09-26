class_name Plaines
## Chapter 1, Plaines des Fougères: the Grand Crâne and its three amber locks, and the
## Tricératops Alpha's battle of honour. Flags: ecaille_bosquet / _grotte / _falaises,
## crane_ouvert, sceau_plaines.

const S := preload("res://story/story.gd")
const ALPHA_LEVEL := 9
## Where the Alpha stands once the skull is open (beside its mouth, facing the path).
const ALPHA_SPOT := Vector2(107.2, 63.8)
## The mouth of its cave, at the back of the mound's notch; and just out of the notch.
const DEN := Vector2(104.0, 58.5)
const MOUTH := Vector2(104.0, 63.2)
## In the cave's darkness: the Alpha comes out of it (and goes back into it) this way.
const IN_SHADOW := Color(0.08, 0.08, 0.1, 0.0)
const SHADOW_S := 1.6


static func grand_crane() -> void:
	if Game.flag(&"sceau_plaines"):
		await S.say([{"text": "Le crâne est silencieux. Quelque part dans l'ombre, le gardien des Plaines veille."}])
		return
	if Game.flag(&"crane_ouvert"):
		var waiting = S.actor("Alpha")
		if waiting:
			await alpha(waiting)
		return
	var n := DialogueDB.ecailles()
	if n < 3:
		await S.say([
			{"text": "La bouche du crâne est fermée par une porte d'ambre. Trois creux en forme d'écaille y sont gravés."},
			{"text": "Il manque encore %d écaille%s d'ambre." % [3 - n, "s" if 3 - n > 1 else ""]},
		])
		return
	S.lock(true)
	await S.say([
		{"text": "Chloé pose les trois écailles d'ambre dans leurs creux. Elles s'y emboîtent parfaitement…"},
		{"text": "L'ambre s'illumine, tiédit… et la porte fond lentement, comme du miel au soleil."},
	])
	var door = S.actor("PorteCrane")
	if door:
		var t: Tween = door.create_tween()
		t.tween_property(door, "modulate", Color(2.2, 1.7, 0.9), 0.6)
		t.tween_property(door, "modulate:a", 0.0, 0.9)
		await t.finished
		door.queue_free()
	Game.set_flag(&"crane_ouvert")
	var alpha = _spawn_alpha()
	if alpha:
		alpha.cry(&"attaque")
		alpha.modulate = IN_SHADOW
		alpha.create_tween().tween_property(alpha, "modulate", Color.WHITE, SHADOW_S)
		await alpha.walk_to(S.at(MOUTH.x, MOUTH.y), 90.0)
		await alpha.walk_to(S.at(ALPHA_SPOT.x, ALPHA_SPOT.y), 90.0)
		S.world().get("player").get_node("Camera").call(&"shake", 7.0, 0.5)
	await S.say([
		{"text": "Un grondement monte du fond de la grotte. Un immense Tricératops sort de l'ombre, les cornes basses."},
		{"text": "C'est le gardien des Plaines : le Tricératops Alpha. Il fixe Chloé, puis son équipe."},
	])
	Save.save_game()
	S.lock(false)


static func _spawn_alpha() -> Node:
	var w = S.world()
	if w == null or S.actor("Alpha") != null:
		return S.actor("Alpha")
	var alpha := DinoNpc.new()
	alpha.name = "Alpha"
	alpha.species_id = &"triceratops"
	alpha.event = &"alpha_plaines"
	alpha.size_scale = 1.35
	alpha.flip = true
	alpha.position = S.at(DEN.x, DEN.y)
	w.region.entities.add_child(alpha)
	return alpha


## Talking to the Alpha: a battle of honour (no collar, no running away).
static func alpha(who: Node) -> void:
	if Game.party.is_empty():
		return
	var pick := await Dialogue.choose("", "Le Tricératops Alpha frappe le sol du sabot. Il veut voir ce que vaut ton équipe.",
		["Relever le défi", "Pas encore"])
	if pick != 0:
		return
	var foe := Dino.create(&"triceratops", ALPHA_LEVEL, "Tricératops Alpha")
	var result: String = await S.world().call(&"_battle", foe, {
		"catch": false, "run": false,
		"intro": "Le Tricératops Alpha se dresse devant toi ! (Combat d'honneur : pas de collier, pas de fuite.)",
	})
	if result != "win":
		return
	S.lock(true)
	await S.say([
		{"text": "Le Tricératops Alpha s'ébroue… puis baisse lentement la tête devant Chloé, comme un salut."},
		{"text": "Il pose le bout de sa corne dans la main de Chloé. Elle est tiède, et il y a quelque chose dessus : un sceau d'ambre."},
		{"text": "Chloé reçoit le Sceau des Plaines !"},
		{"flag": &"sceau_plaines"},
		{"text": "Sous le sceau, une page du journal d'Hélène, soigneusement pliée…"},
	])
	await Dialogue.run(DialogueDB.lines(&"page_5"))
	Game.award_team_xp(60)
	if is_instance_valid(who):
		await who.walk_to(S.at(MOUTH.x, MOUTH.y), 80.0)
		# Into the cave: the darkness swallows it as it reaches the mouth.
		var fade: Tween = who.create_tween()
		fade.tween_interval(0.9)
		fade.tween_property(who, "modulate", IN_SHADOW, SHADOW_S)
		await who.walk_to(S.at(DEN.x, DEN.y), 80.0)
		who.queue_free()
	await S.say([{"text": "Le gardien retourne dans sa grotte, au fond du crâne."},
		{"text": "Sur une pierre, un mot plié en quatre, signé d'une tête de Protoceratops : « Bravo, championne. Rendez-vous au Havre ! Prends la route côtière, à l'est du port. — M. »"}])
	Save.save_game()
	S.lock(false)
