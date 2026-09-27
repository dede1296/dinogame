class_name Grotte
## Chapter 1, the Grotte des Échos (docs/histoire.md, ch. 1, step 3): two henchmen of the
## Ombre Noire tear amber from the walls — the first battles against them —, and at the far
## end, the first corrupted dino: a Protoceratops they fed black amber to make it dig, then
## left behind, mad with fear. The game teaches Apaiser; the second amber scale was under it.
## Flags: sbire_grotte_1, sbire_grotte_2, apaiser_appris, proto_apaise, proto_suit.

const S := preload("res://story/story.gd")
const CHLOE := "Chloé"
const GUSTAVE := "Sbire masqué"
const CHEF := "Sbire à la pioche"
const TEAM_1 := [[&"compsognathus", 6], [&"troodon", 7]]
const TEAM_2 := [[&"troodon", 7], [&"velociraptor", 8]]
const PROTO_LEVEL := 9
## Where the henchmen run to (the way out, at the bottom of the cave).
const WAY_OUT := Vector2(11.9, 17.2)
## The second scale, under the corrupted Protoceratops.
const SCALE_SPOT := Vector2(18.6, 2.9)
## Said in the battle the first time: how to calm a corrupted dino.
const LESSON := [
	"Ce Protoceratops est corrompu : l'ambre noir le rend fou de peur. Impossible de le capturer, et il ne tombera pas.",
	"Choisis « Apaiser » : ton dino s'approche, et Chloé lui parle tout bas. Chaque réussite remplit sa jauge de Calme.",
	"Plus il est fatigué, plus il écoute. Un dino de sa famille l'apaise plus vite. Mais chaque coup l'affole à nouveau !",
]


## Entering the cave: pickaxes in the dark, then the first henchman comes to see who is there.
static func arrival() -> void:
	if Game.flag(&"sbire_grotte_1"):
		return
	var sbire = S.actor("Sbire1")
	var w = S.world()
	if sbire == null or w == null:
		return
	S.lock(true)
	await S.wait(0.8)
	await S.say([
		{"text": "Tac… tac… tac… Des coups de pioche résonnent dans le noir. Puis des voix."},
		{"who": "Une voix", "text": "Plus vite ! Le Masque veut ses caisses avant la pleine lune."},
		{"who": CHLOE, "text": "(Le Masque… ?)"},
	])
	await sbire.walk_to(w.player.global_position + Vector2(0, -80), "down", 150.0)
	await S.say([
		{"who": GUSTAVE, "text": "Hé ! Une gamine ! Qu'est-ce que tu fiches ici ? Cette grotte est à l'Ombre Noire, maintenant."},
		{"who": CHLOE, "text": "Cette grotte, c'est ma grand-mère qui l'a trouvée. Et l'ambre appartient à l'île."},
		{"who": GUSTAVE, "text": "Ha ! Alors viens le reprendre."},
	])
	S.lock(false)
	await _fight_gustave(sbire)


## Talking to the first henchman again (after a defeat).
static func gustave(who: Node) -> void:
	await S.say([{"who": GUSTAVE, "text": "Tu reviens ? T'as pas compris la première fois ?"}])
	await _fight_gustave(who)


static func _fight_gustave(who: Node) -> void:
	if not await S.duel(GUSTAVE, TEAM_1):
		return
	S.lock(true)
	await S.say([
		{"who": GUSTAVE, "text": "Aïe, aïe, aïe… Le chef va me tuer. Enfin, il va me faire porter les caisses. C'est pire."},
		{"who": GUSTAVE, "text": "Tu sais quoi ? Je démissionne. Je retourne pêcher. Au moins, les poissons ne mordent pas. Enfin, pas fort."},
		{"flag": &"sbire_grotte_1"},
	])
	if is_instance_valid(who):
		await who.walk_to(S.at(WAY_OUT.x, WAY_OUT.y), "down", 200.0)
		who.queue_free()
	await S.say([{"who": CHLOE, "text": "Un pêcheur de Port-Ambre ? Sous un masque d'os ?… Il y en a un autre, au fond. J'entends encore sa pioche."}])
	Game.award_team_xp(30)
	Save.save_game()
	S.lock(false)


## The second henchman, at the far end, beside the dino they broke.
static func chef(who: Node) -> void:
	await S.say([
		{"who": CHEF, "text": "T'as battu Gustave ? Pas difficile, Gustave a peur des poules."},
		{"who": CHEF, "text": "Tu vois ce Protoceratops ? On lui a fait avaler de l'ambre noir, pour qu'il creuse plus fort. Il a creusé, oui. Et puis il a mordu tout le monde."},
		{"who": CHLOE, "text": "Vous lui avez fait du mal !"},
		{"who": CHEF, "text": "On lui a rendu service : il est plus fort qu'avant. Allez, dégage, ou je te montre ce que valent les dinos de l'Ombre Noire."},
	])
	if not await S.duel(CHEF, TEAM_2):
		return
	S.lock(true)
	await S.say([
		{"who": CHEF, "text": "Grr… Garde-le, ton bestiau ! De toute façon, il est fichu. L'ambre noir, ça ne s'en va jamais."},
		{"flag": &"sbire_grotte_2"},
	])
	if is_instance_valid(who):
		await who.walk_to(S.at(WAY_OUT.x, WAY_OUT.y), "down", 210.0)
		who.queue_free()
	await S.say([{"who": CHLOE, "text": "Ce n'est pas vrai. Il a juste peur… Hélène disait qu'un dino ne se dresse pas : il se rencontre."}])
	Game.award_team_xp(40)
	Save.save_game()
	S.lock(false)


## The corrupted Protoceratops: calming it (a battle, with the lesson the first time).
static func proto(who: Node) -> void:
	if not Game.flag(&"sbire_grotte_2"):
		var chef_npc = S.actor("Sbire2")
		await S.say([{"who": CHEF, "text": "Touche pas à notre bestiole, la gamine !"}])
		if chef_npc:
			await chef(chef_npc)
		return
	var pick := await Dialogue.choose("", "Le Protoceratops tremble dans le noir. Des veines violettes pulsent sous sa peau, et ses yeux brillent d'une lueur qui n'est pas la sienne.",
		["L'approcher doucement", "Pas maintenant"])
	if pick != 0:
		return
	var foe := Dino.create(&"protoceratops", PROTO_LEVEL)
	foe.corrupted = true
	var result: String = await S.world().call(&"_battle", foe, {
		"catch": false, "intro": "Le Protoceratops corrompu charge, fou de peur !",
		"lesson": [] if Game.flag(&"apaiser_appris") else LESSON,
	})
	Game.set_flag(&"apaiser_appris")
	if result != "calmed":
		return
	S.lock(true)
	if is_instance_valid(who):
		await who.cleanse()
	await S.say([
		{"text": "Le Protoceratops cligne des yeux, longtemps. Puis il regarde Chloé comme s'il la voyait pour la première fois."},
		{"text": "Il fait un pas de côté. Sous lui, coincée entre deux cristaux, une écaille d'ambre pulse doucement."},
		{"flag": &"proto_apaise"},
	])
	_drop_scale()
	var join := await Dialogue.choose("", "Le Protoceratops se frotte contre la jambe de Chloé. Il ne veut plus rester seul dans le noir.",
		["Viens avec moi !", "Retourne aux Plaines"])
	if join == 0:
		var d := Dino.create(&"protoceratops", PROTO_LEVEL)
		var in_party := Game.add_caught(d)
		Game.set_flag(&"proto_suit")
		if is_instance_valid(who):
			who.queue_free()
		await S.say([{"text": "%s rejoint ton équipe !" % d.nickname if in_party else "%s part attendre au Cabinet." % d.nickname}])
	else:
		await S.say([{"text": "Le Protoceratops pousse un petit cri, presque un merci, et trottine vers la sortie. Vers le soleil."}])
		if is_instance_valid(who):
			await who.walk_to(S.at(WAY_OUT.x, WAY_OUT.y), 150.0)
			who.queue_free()
	Save.save_game()
	S.lock(false)


## The scale it was lying on (also placed by the zone once calmed, see tools/zones).
static func _drop_scale() -> void:
	var w = S.world()
	if w == null or S.actor("Ecaille") != null or Game.flag(&"ecaille_grotte"):
		return
	var scale := Pickup.new()
	scale.name = "Ecaille"
	scale.kind = "ecaille"
	scale.taken_flag = &"ecaille_grotte"
	scale.dialogue_id = &"ecaille_grotte"
	scale.position = S.at(SCALE_SPOT.x, SCALE_SPOT.y)
	w.region.entities.add_child(scale)
