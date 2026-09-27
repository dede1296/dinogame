class_name Havre
## Interlude, Havre-Doré (docs/histoire.md « Interlude — Havre-Doré »): the town at the end of
## the coast road, open once Chloé holds the Sceau des Plaines. Maïa and Joss the saddler; the
## shops; Ferréol and his Comptoir d'Ambre; the Relais des Dresseurs; the saddle (Monture);
## Isaure's boat at the Comptoir's warehouse, one night.
## Flags: havre_arrive, ferreol_rencontre, selle_demandee, cuir_trouve, selle, gaspard_battu,
## lilou_battu, barque_vue, vu_<shop>; revanche_<trainer> = the day of the last rematch.

const S := preload("res://story/story.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const JOSS := "Joss"
const FERREOL := "Maître Ferréol"
const ISAURE := "Isaure"
const WELCOME_COINS := 200
## Joss's work on the saddle, besides the skin and the buckle: more than Ferréol's welcome
## coins leave once the buckle is bought, so the saddle is earned (the Relais, the Comptoir).
const SADDLE_PRICE := 350
## A beaten trainer takes a rematch once a day, for this share of the first prize.
const REMATCH_SHARE := 0.35
const TRAINER_MUSIC := preload("res://assets/audio/music/rivale.ogg")
const COINS_SFX := preload("res://assets/audio/sfx/coins.wav")
const DOOR_SFX := preload("res://assets/audio/sfx/door_open.wav")
## The trainers of the Relais: team (species, level), prize, their lines.
const TRAINERS := {
	&"gaspard": {"name": "Gaspard", "rank": "Bronze", "flag": &"gaspard_battu", "prize": 150,
		"team": [[&"protoceratops", 9], [&"psittacosaurus", 10]],
		"hello": "Une nouvelle tête ! Au Relais, on dit bonjour avec ses dinos. Prête ?",
		"won": "Ha ! Mes cornus ont la tête dure, mais toi, tu l'as encore plus. Bien joué.",
		"after": "Reviens quand tu veux. Enfin… reviens quand j'aurai de meilleurs dinos."},
	&"lilou": {"name": "Lilou", "rank": "Argent", "flag": &"lilou_battu", "prize": 250,
		"team": [[&"dimorphodon", 11], [&"parasaurolophus", 12], [&"velociraptor", 12]],
		"hello": "Rang Argent. Trois dinos, zéro pitié. Tu es sûre de toi ?",
		"won": "… D'accord. Tu es forte. Maïa avait raison, ça m'énerve.",
		"after": "La prochaine fois, je t'attends au Relais de la Forêt. Et je serai prête."},
}


# ------------------------------------------------------------------ arriving

static func arrival() -> void:
	if Game.flag(&"havre_arrive"):
		await night()
		return
	S.lock(true)
	await S.wait(0.6)
	var maia = S.actor("Maia")
	var w = S.world()
	if maia and w:
		await maia.walk_to(w.player.global_position + Vector2(70, 0), "left", 170.0)
	await S.say([
		{"who": MAIA, "text": "Te voilà ! Bienvenue au Havre. Regarde-moi ça : des toits neufs, des lanternes partout… et personne qui compte ses poissons."},
		{"who": MAIA, "text": "Ici, tout le monde a des dinos, et tout le monde les équipe. Le Relais, là-haut, c'est là que les dresseurs se mesurent."},
		{"who": CHLOE, "text": "Tout ça, c'est grâce à quoi ?"},
		{"who": MAIA, "text": "À l'ambre. Le Comptoir de Maître Ferréol rachète tout ce qu'on trouve. Maman lui livre des caisses, des fois."},
		{"who": MAIA, "text": "Et je te présente mon meilleur ami : Joss, le sellier, la grande maison à l'est. Il fait des SELLES. Pour DINOS. On peut MONTER dessus, Chloé."},
		{"flag": &"havre_arrive"},
	])
	if maia:
		await maia.walk_to(S.at(24.6, 9.9), "down", 170.0)
	Save.save_game()
	S.lock(false)
	await night()


# ------------------------------------------------------------------ the shops

## A shopkeeper (or its door): a word the first time, then the shop.
static func shop(id: StringName, who: Node) -> void:
	var first: bool = not Game.flag(StringName("vu_%s" % id))
	var shopping := false
	match id:
		&"herboristerie":
			shopping = await Ask.menu(&"pervenche", "Mémé Pervenche", "Des baies, des fougères… Tout ce qui soigne pousse quelque part sur cette île. J'ai soigné les dinos d'Hélène, dans le temps. Elle me devait trois tartes." if first
				else "Entre, entre. Et essuie tes pieds, tu ramènes toute la prairie.", [&"pieces"], "Voir la boutique")
		&"mercerie":
			shopping = await Ask.menu(&"rosalie", "Rosalie", "Des colliers tout neufs ! Et des bottes d'ambre souple : avec ça, tu traverses l'île avant le goûter." if first
				else "Tu reviens déjà ? C'est bien, ça. J'aime les clientes qui reviennent.", [&"pieces", &"selle"], "Voir la boutique")
	Game.set_flag(StringName("vu_%s" % id))
	if not shopping:
		return
	Audio.play_sfx(DOOR_SFX, -6.0)
	var screen := ShopScreen.open(S.world(), id)
	await screen.closed


static func ferreol() -> void:
	if not Game.flag(&"ferreol_rencontre"):
		S.lock(true)
		await S.say([
			{"who": FERREOL, "text": "Ah ! La petite-fille d'Hélène Varenne, en personne. Une grande dame, votre grand-mère. Nous n'avons jamais fait affaire… hélas."},
			{"who": FERREOL, "text": "Le Comptoir d'Ambre offre une prime de bienvenue à chaque dresseur qui porte un Sceau d'Alpha. Considérez cela comme… un investissement."},
		])
		Game.give_item("piece", WELCOME_COINS)
		Audio.play_sfx(COINS_SFX)
		Toast.say(S.world().get_tree(), "+%d pièces" % WELCOME_COINS)
		await S.say([
			{"who": FERREOL, "text": "Et si vous trouvez des larmes de l'île, ces petits galets d'ambre, je vous les rachète. Très cher. Personne ne paie mieux que moi."},
			{"who": FERREOL, "text": "Je vous vends aussi les boucles d'ambre dont ce jeune Joss raffole. Entrez, je vous prie."},
			{"flag": &"ferreol_rencontre"},
		])
		S.lock(false)
	else:
		var prompt: String = ["Que puis-je pour vous, mademoiselle Varenne ?", "L'ambre, voyez-vous, c'est de la lumière qu'on peut mettre en poche.",
			"Votre grand-mère gardait tout pour elle. Moi, je partage. Contre paiement, naturellement."].pick_random()
		if not await Ask.menu(&"ferreol", FERREOL, prompt, [&"pieces"], "Faire affaire"):
			return
	Audio.play_sfx(DOOR_SFX, -6.0)
	var screen := ShopScreen.open(S.world(), &"comptoir")
	await screen.closed


# ------------------------------------------------------------------ the saddle

static func joss() -> void:
	if Game.flag(&"selle"):
		await Ask.menu(&"joss", JOSS, ["Elle tient bien, ta selle ? Si elle grince, c'est normal : elle est contente.",
			"Un jour, je ferai un harnais pour voler. Il me faut juste un ptérosaure assez grand. Et du courage.",
			"Maïa dit qu'elle va gagner la prochaine course. Elle dit ça depuis qu'on a six ans."].pick_random(), [&"monter"])
		return
	if not Game.flag(&"selle_demandee"):
		await S.say([
			{"who": JOSS, "text": "Salut ! Toi, c'est Chloé. Maïa ne parle que de toi. Enfin… de comment elle va te battre."},
			{"who": JOSS, "text": "Une selle ? Je peux te la faire. Mais il me faut du cuir mué de Parasaurolophus : ils perdent leur vieille peau au bord de l'étang des Plaines."},
			{"who": JOSS, "text": "Et une boucle d'ambre pour la sangle. Le Comptoir de Ferréol en vend. Il est cher, mais il est le seul."},
			{"who": JOSS, "text": "Et mon travail : %d pièces. C'est un prix d'ami de Maïa. Pour Ferréol, c'est le double." % SADDLE_PRICE},
			{"who": CHLOE, "text": "%d pièces ?! Je n'en ai même pas la moitié…" % SADDLE_PRICE},
			{"who": JOSS, "text": "Le Relais paie bien les bons dresseurs. Et le Comptoir rachète tout ce qui brille. Tout."},
			{"who": JOSS, "text": "Attention : seul un grand dino adulte peut te porter (niveau %d). Un Tricératops, un Parasaurolophus, un Ankylosaurus… Un raptor ? Il te ferait tomber exprès." % Abilities.ADULT_LEVEL},
			{"flag": &"selle_demandee"},
		])
		return
	var cuir := Game.item_count("cuir") > 0
	var boucle := Game.item_count("boucle") > 0
	var paid := Game.coins() >= SADDLE_PRICE
	if not (cuir and boucle and paid):
		var missing := []
		if not cuir:
			missing.append("le cuir mué (au bord de l'étang des Plaines)")
		if not boucle:
			missing.append("la boucle d'ambre (au Comptoir)")
		if not paid:
			missing.append("mes %d pièces (tu en as %d)" % [SADDLE_PRICE, Game.coins()])
		await Ask.menu(&"joss", JOSS, "Il me manque encore " + ", ".join(missing.slice(0, -1)) + (" et " if missing.size() > 1 else "") + missing[-1] + ".",
			[&"pieces", &"monter"])
		return
	S.lock(true)
	await S.say([{"who": JOSS, "text": "Le cuir, la boucle… et les pièces ! Marché conclu. Ne regarde pas, je suis timide quand je couds."}])
	Game.pay(SADDLE_PRICE)
	Audio.play_sfx(COINS_SFX)
	await S.fade_through(func() -> void: await S.wait(1.0))
	Game.use_item("cuir")
	Game.use_item("boucle")
	Game.give_item("selle")
	Game.set_flag(&"selle")
	await S.say([
		{"who": JOSS, "text": "Voilà. Taillée pour toi. Le cuir de l'étang est le plus souple de l'île."},
		{"text": "Chloé reçoit la selle de Joss ! Un grand dino adulte de l'équipe peut maintenant la porter : touche le bouton selle, à droite de l'écran (ou R)."},
		{"who": JOSS, "text": "Sur une monture, tu vas presque deux fois plus vite, et les dinos des herbes hautes ne te voient même pas passer. La Forêt est immense : tu en auras besoin."},
	])
	Toast.say(S.world().get_tree(), "Objet obtenu : la selle")
	Game.award_team_xp(40)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ the Relais

static func relais() -> void:
	var lines: Array = [{"text": "Le Relais des Dresseurs. Au mur, un grand tableau : « Gaspard, rang Bronze — Lilou, rang Argent. Challengers bienvenus. »"}]
	if Game.flag(&"gaspard_battu") and Game.flag(&"lilou_battu"):
		lines.append({"text": "Quelqu'un a ajouté à la craie, en bas : « Chloé V., rang Argent. » Maïa a barré et écrit « pour l'instant » à côté."})
	await S.say(lines)


static func trainer(id: StringName, who: Node) -> void:
	var t: Dictionary = TRAINERS[id]
	var rematch_flag := StringName("revanche_%s" % id)
	var rematch: bool = Game.flag(t["flag"])
	var prize: int = t["prize"]
	if rematch:
		if int(Game.flag(rematch_flag)) == Game.day:
			await S.say([{"who": t["name"], "text": t["after"]}, {"who": t["name"], "text": "Une revanche par jour, c'est la règle du Relais. Reviens demain."}])
			return
		prize = roundi(prize * REMATCH_SHARE)
		var again := await Dialogue.choose(t["name"], "%s Une revanche ? Mise : %d pièces." % [t["after"], prize], ["Revanche", "Plus tard"])
		if again != 0:
			return
	else:
		var pick := await Dialogue.choose(t["name"], "%s Prime du Relais : %d pièces." % [t["hello"], prize], ["Combattre", "Plus tard"])
		if pick != 0:
			return
	if Game.party.is_empty():
		return
	var w = S.world()
	for member: Array in t["team"]:
		var foe := Dino.create(member[0], member[1])
		var result: String = await w.call(&"_battle", foe, {
			"catch": false, "run": false, "music": TRAINER_MUSIC,
			"intro": "%s envoie %s !" % [t["name"], foe.species_name()],
		})
		if result != "win":
			return
	Game.set_flag(t["flag"])
	if rematch:
		Game.set_flag(rematch_flag, Game.day)
	Game.give_item("piece", prize)
	Audio.play_sfx(COINS_SFX)
	var line: String = "Encore ?! Bon. Demain, je t'aurai." if rematch else t["won"]
	await S.say([{"who": t["name"], "text": line}, {"text": "Tu gagnes %d pièces." % prize}])
	Save.save_game()


# ------------------------------------------------------------------ one night on the quay

## At night, once: Isaure's boat at the Comptoir's warehouse (docs/histoire.md, a clue).
static func night() -> void:
	if Game.flag(&"barque_vue") or not Game.flag(&"havre_arrive") or Game.phase() != &"night":
		return
	var w = S.world()
	if w == null or w.region == null or w.region.region_id != &"havre_dore":
		return
	S.lock(true)
	await S.say([{"text": "Au bout du quai, une barque accoste sans lumière, juste devant l'entrepôt du Comptoir."}])
	await S.fade_through(func() -> void:
		w.player.teleport(S.at(44.3, 21.1))   # behind the crates of the quay
		w.companion.teleport(S.at(43.4, 21.2))
		w.player.face_towards(S.at(48.5, 20.0))
		await S.wait(0.3))
	await S.say([{"text": "Chloé se glisse derrière les caisses, sans un bruit."}])
	var entities: Node = w.region.entities
	var isaure := _stranger(entities, "IsaureNuit", "isaure", Color.WHITE, S.at(47.5, 24.6))
	var ferreol := _stranger(entities, "FerreolNuit", "ferreol", Color.WHITE, S.at(48.5, 18.3))
	await isaure.walk_to(S.at(47.5, 21.4), "up", 110.0)
	await ferreol.walk_to(S.at(48.5, 20.4), "down", 90.0)
	await S.say([
		{"who": FERREOL, "text": "Ponctuelle, Capitaine. Nos amis seront ravis. Même heure, la semaine prochaine ?"},
		{"who": ISAURE, "text": "C'est la dernière fois, Ferréol."},
		{"who": FERREOL, "text": "Vous dites cela chaque semaine."},
		{"who": ISAURE, "text": "… Et chaque semaine, je le pense."},
	])
	await isaure.walk_to(S.at(47.5, 24.6), "down", 110.0)
	isaure.queue_free()
	await ferreol.walk_to(S.at(48.5, 18.3), "up", 90.0)
	ferreol.queue_free()
	await S.say([{"who": CHLOE, "text": "Isaure ? Qu'est-ce qu'elle livre au Comptoir… en pleine nuit ?"}, {"flag": &"barque_vue"}])
	Save.save_game()
	S.lock(false)


static func _stranger(entities: Node, node_name: String, sheet: String, tint: Color, at: Vector2) -> Npc:
	var n: Npc = load("res://actors/npc.tscn").instantiate()
	n.name = node_name
	n.sheet = load("res://assets/art/characters/%s.png" % sheet)
	n.tint = tint
	n.position = at
	entities.add_child(n)
	n.remove_from_group(&"interactable")
	return n
