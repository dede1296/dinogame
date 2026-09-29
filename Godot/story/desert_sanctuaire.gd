class_name DesertSanctuaire
## Chapter 4, the Désert Aride, the sanctuary des Vents (docs/histoire.md, ch. 4, points 4 and 5):
## Brac in front of its door, making the corrupted Carnotaurus Rouge roar (a cry of fear: the
## door does not move); the sandstorm rises and Brac flees into the canyon des Vents; three
## moments of the chase in the storm (the tracks, a wheel rolling by itself, a lost henchman),
## never blocking; Brac cornered in the dead end, beaten, flees over the rock and leaves the
## Alpha; the long calming; freed, the Carnotaurus goes home and roars — a true roar — and the
## door opens: the Sceau du Désert. Brac's cart (a note from « M. »). Inside the sanctuary (zone
## sanctuaire_vents), the second Cœur, and the first one answers it.
## Flags: porte_vents_vue, brac_desert_vu, poursuite_1_ok … _3_ok, brac_desert_parle,
## brac_desert_battu, carno_lecon, carnotaurus_apaise, sanctuaire_ouvert, sceau_desert,
## chariot_fouille, sanctuaire_entre, coeur_2; chariot_n, gardien_n (lines). (Page 18: a Pickup.)

const S := preload("res://story/story.gd")
const P := preload("res://story/desert_places.gd")
const D := preload("res://story/desert.gd")
const CHLOE := "Chloé"
const BRAC := "Brac"
const FIRMIN := "Firmin"
const OMBRE_MUSIC := "res://assets/audio/music/ombre.ogg"
const ALPHA_MUSIC := "res://assets/audio/music/alpha.ogg"
const CRY := "res://assets/audio/cries/%s-%s.mp3"
const ROCK := preload("res://assets/audio/sfx/rock_heavy.wav")
const LATCH := preload("res://assets/audio/sfx/latch.wav")
## Brac's lost wheel (the chase, moment 2), drawn by _wheel_picture: its size and colours.
const WHEEL_PX := 64
const WHEEL_SCALE := 0.72
const WHEEL_IRON := Color(0.36, 0.34, 0.33)
const WHEEL_WOOD := Color(0.52, 0.32, 0.15)
const PAINTED_WHEEL := "res://assets/art/props/roue_chariot.png"   # (its painted picture, turned by _turned)
## The Cœurs' warm light, on Chloé (her bag) and on the altar.
const HEART_GLOW := Color(1.8, 1.45, 0.8)
## The Carnotaurus's eyes once calm, the colour of embers (a glow).
const EMBER := Color(1.0, 0.74, 0.52)
## Brac's team in the Désert, one after the other (checked by simulation, scratchpad/
## sim_desert.gd: about 90 % won by a party of four at levels 22–24 with good moves).
const BRAC_TEAM := [
	[&"stygimoloch", 24, "Cabosse"],
	[&"majungasaurus", 24, "Grognon", {"before": [{"who": BRAC, "text": "Cabosse ! Relève-toi ! … Bon. Grognon, à toi. Et ne boude pas, pour une fois."}]}],
	[&"allosaurus", 25, "Mastoc", {"before": [{"who": BRAC, "text": "Tu te souviens de Mastoc, moucheron ? Il a grandi. Et il est de très mauvaise humeur : il a du sable entre les dents."}]}],
]
## The Carnotaurus Rouge, the Désert's Alpha, corrupted (a long calming: the hardest so far).
const CARNO_LEVEL := 27
## Its size in the world (DinoNpc.size_scale), as the zone's own, and in its battle.
const CARNO_SIZE := 1.2
const XP_PORTE := 30
const XP_POURSUITE := 15
const XP_BRAC := 80
const XP_CARNO := 90
const XP_CHARIOT := 30
const XP_COEUR := 60
## Said in the Carnotaurus's battle the first time.
const LONG_LESSON := [
	"Le Carnotaurus Rouge n'est pas méchant : il a peur. Peur de l'ambre noir qu'on lui a fait avaler, peur de la cage, peur de tout.",
	"L'ambre noir le tient plus fort qu'aucun autre : sa jauge de Calme est très longue. Choisis « Apaiser » et ne tape plus : chaque coup l'affole à nouveau.",
	"Ton dino de départ, en tête, se met entre vous deux : chaque tentative compte davantage, et chaque cœur de Lien aide aussi. Si ton équipe s'épuise, tu pourras revenir.",
]
## The Carnotaurus by the open door, afterwards (the next one each time).
const GARDIEN_AGAIN := [
	"Le Carnotaurus somnole près de la porte. Quand Chloé passe, il ouvre un œil couleur de braise… et le referme. Tout va bien.",
	"Chloé lui gratte la base des cornes. Il ronronne. Le sable vibre sous ses pieds.",
	"Le Carnotaurus renifle la sacoche de Chloé, là où battent les Cœurs. Il souffle doucement : un souffle chaud, qui sent le soleil.",
	"Un Oviraptor passe trop près du Carnotaurus. Il ne bouge pas. L'Oviraptor, lui, court encore.",
]
const CHARIOT_AGAIN := [
	"Le chariot de Brac. Le pot de moutarde est toujours là. Chloé préfère ne pas savoir pourquoi.",
	"Chloé relit le mot de « M. » : « D'autres ouvriront les portes pour nous. » Elle le range avec les pages d'Hélène.",
	"La cage est vide, les barreaux tordus. Pour de bon.",
]


# ------------------------------------------------------------------ Brac at the door

## On the square in front of the sanctuary (StoryTrigger « brac_sanctuaire »): Brac makes the
## chained Carnotaurus roar at the door; a cry of fear, and the door does not move. He sees
## Chloé; the sky turns yellow, the sandstorm rises, and he flees into the canyon des Vents.
static func brac_sanctuaire(_trigger: Node) -> void:
	if Game.flag(&"brac_desert_vu"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var theme: AudioStream = ForetCamp.music_at(OMBRE_MUSIC)
	if theme:
		Audio.push_music(theme, 1.0)
	var door := _door_px()
	var boss := S.stranger("BracPorte", "brac", door + P.BRAC_PORTE * S.CELL, "up")
	var carno := _scene_carno("CarnoPorte", door + P.CARNO_PORTE * S.CELL, true)
	for n: Node2D in [boss, carno]:   # out of the blowing sand
		n.modulate.a = 0.0
		n.create_tween().tween_property(n, "modulate:a", 1.0, 0.8)
	w.player.face_towards(boss.global_position)
	var chloe := Stage.chloe()
	var chain := {}   # the chain, pulled both ways until the roar
	var pulls := func() -> void:
		Stage.look_at(door + Vector2(0.0, 2.2 * S.CELL))
		chain["carno"] = D._tug(carno, boss.global_position, 0.7, 10.0)
		# She comes onto the square, drawn in (and near enough for what follows).
		D._chloe_walk(S.at(P.PLACE_SANCTUAIRE.x, P.PLACE_SANCTUAIRE.y + 0.6), 70.0, 3.0)
	var pulls_back := func() -> void:   # Brac, facing it, leaning back
		boss.face(carno.global_position)
		chain["brac"] = D._tug(boss, carno.global_position, 0.6, 7.0)
	var roars := func() -> void:
		Stage.stop(carno, chain.get("carno"))
		Stage.stop(boss, chain.get("brac"))
		carno.cry(&"attaque")
		Stage.shake(5.0, 0.5)
		await Stage.rear(carno, 1.0)
		Stage.tremble(carno, 1.4, 2.0)   # it breaks, like a sob
	var stamps := func() -> void:
		boss.face(carno.global_position)   # (at it, not at Chloé: he has not seen her yet)
		Stage.hop(boss, 2, 8.0)
		Stage.tremble(carno, 1.0, 2.0)
	await S.say([
		D._cue({"text": "Devant la grande porte de pierre du sanctuaire, un dino immense tire sur une chaîne. Rouge sombre, deux cornes au-dessus des yeux, de tout petits bras… et sous la peau, des veines violettes."}, pulls),
		D._cue({"text": "Au bout de la chaîne, arc-bouté dans le sable : Brac."}, pulls_back),
		D._cue({"who": BRAC, "text": "ALLEZ ! RUGIS ! Rugis devant la porte, gros tas d'écailles ! Le Masque a dit que tu l'ouvrirais !"},
			func() -> void: boss.face(carno.global_position)),
		D._cue({"text": "Le Carnotaurus rugit. Un cri terrible… qui monte, qui monte, et se casse d'un coup, comme un sanglot."}, roars),
		{"text": "La porte ne bouge pas d'un millimètre."},
		{"who": CHLOE, "text": "(Ce n'est pas un rugissement de colère. C'est un cri de peur.)"},
		{"text": "Sous l'empreinte géante gravée au milieu de la porte, Chloé lit : « Au gardien sans peur, la porte s'ouvre. »"},
		{"flag": &"porte_vents_vue"},
		D._cue({"who": BRAC, "text": "Encore ! ENCORE ! … Crotte de Stégosaure, pourquoi ça ne marche pas ?!"}, stamps),
	])
	var lead := Game.lead_dino()
	await S.say(_brac_at_the_door(lead, boss))
	Game.set_weather(&"sandstorm")
	w.player.get_node("Camera").call(&"shake", 3.0, 1.0)
	var storm: Array = [D._cue({"text": "Soudain, le ciel devient jaune. Le vent se lève d'un coup, et le sable se met à voler dans tous les sens."},
		func() -> void: Stage.emote(chloe, "!"))]
	if Game.flag(&"sirocco_vue"):
		storm.append({"who": CHLOE, "text": "(« Quand le ciel devient jaune… » Tante Sirocco avait prévenu !)"})
	storm.append(D._cue({"who": BRAC, "text": "HA ! La tempête ! Parfait ! Bonne chance pour me suivre là-dedans, moucheron !"}, func() -> void: Stage.hop(boss, 2, 10.0)))
	await S.say(storm)
	var canyon := S.at(P.CANYON_VENTS.x, P.CANYON_VENTS.y)
	var flee := func() -> void:
		Stage.look_at(canyon.lerp(door, 0.35), 1.2)
		ForetCamp._leave(boss, P.CANYON_VENTS, 170.0)
		await S.wait(0.5)
		Stage.cry(carno, &"degat")
		D._crouch(carno, 0.08, 0.5)   # its head low
		ForetCamp._leave(carno, P.CANYON_VENTS + Vector2(0.0, 1.0), 150.0)
	await S.say([
		D._cue({"text": "Brac tire sur la chaîne et s'enfonce dans le canyon des Vents, à l'ouest. Le Carnotaurus le suit en gémissant, la tête basse."}, flee),
		D._cue({"who": CHLOE, "text": "(Il fuit dans le canyon, en pleine tempête… Je ne vais pas le laisser emmener le gardien du Désert !)"},
			func() -> void: Stage.look_back()),
		{"flag": &"brac_desert_vu"},
	])
	_brac_npc()   # waiting for her at the end of the canyon
	if theme:
		Audio.pop_music(1.5)
	Game.award_team_xp(XP_PORTE)
	Save.save_game()
	S.lock(false)


static func _brac_at_the_door(lead: Dino, boss: Npc) -> Array:
	var chloe := Stage.chloe()
	var turns := func() -> void:
		var dino := D._companion()
		if dino:
			Stage.lunge(dino, boss.global_position, 0.5)
			await S.wait(0.5)
		boss.face(chloe.global_position)
		Stage.emote(boss, "!")
		Stage.look_at(chloe.global_position.lerp(boss.global_position, 0.42))
	var lines: Array = [D._cue({"text": "%s gronde. Brac se retourne d'un bloc." % lead.nickname if lead else "Brac se retourne d'un bloc."}, turns)]
	lines.append_array([
		{"who": BRAC, "text": "TOI ?! Le moucheron de la Forêt ! Dans MON désert ?! Tu me suis, ou quoi ?"},
		{"who": CHLOE, "text": "C'est vous qui êtes partout où il y a un Alpha à attraper !"},
		{"who": BRAC, "text": "Parce que c'est mon MÉTIER ! Chasseur d'Alphas ! C'est écrit sur ma carte de visite ! … Enfin, ça le sera, quand j'aurai des cartes de visite."},
		{"who": BRAC, "text": "Je t'avais prévenue, moucheron : ici, j'ai des amis. Des amis avec des DENTS !"},
		{"who": CHLOE, "text": "Ce n'est pas votre ami. Il a peur de vous. Il a peur de tout !"},
		{"who": BRAC, "text": "Peur, obéir… c'est pareil, gamine."},
		{"who": CHLOE, "text": "Non. Et la porte, elle, le sait."},
	])
	if Game.flag(&"dame_suie_battue"):
		lines.append_array([
			{"who": BRAC, "text": "Pfff. La Suie m'avait prévenu que sa nouvelle fournée d'ambre noir était « trop forte ». La Suie dit toujours « trop ». Moi, j'aime quand c'est trop."},
			{"who": CHLOE, "text": "(L'ambre noir de Dame Suie… Même elle trouvait ça trop fort.)"},
		])
	return lines


# ------------------------------------------------------------------ the chase

## The three moments of the chase in the canyon des Vents (StoryTriggers « poursuite_1 » … 3),
## in the storm: funny and a little thrilling, never blocking. Once Brac is beaten, they stay
## quiet.
static func poursuite(n: int, _trigger: Node) -> void:
	var done := StringName("poursuite_%d_ok" % n)
	if Game.flag(done):
		return
	if Game.flag(&"brac_desert_battu"):
		Game.set_flag(done)
		return
	S.lock(true)
	if Game.weather != &"sandstorm":
		Game.set_weather(&"sandstorm")
	match n:
		1:
			await _tracks()
		2:
			await _wheel()
		_:
			await _lost_henchman()
	Game.set_flag(done)
	Game.award_team_xp(XP_POURSUITE)
	Save.save_game()
	S.lock(false)


## 1. The tracks vanish in the wind: follow the wheels (Brac went round in circles) or the
## nose of a dino (straight on). Both lead the right way.
static func _tracks() -> void:
	var guide: Dino = Game.ability_user(&"flair")
	if guide == null:
		guide = Game.lead_dino()
	var chloe := Stage.chloe()
	var dino := D._companion() if guide and guide == Game.lead_dino() else null   # the guide, when at her side
	var ahead := _towards(P.POURSUITES[1])
	var gust := func() -> void:
		Stage.shake(2.0, 0.6)
		Stage.tremble(chloe, 1.2, 1.5)
	var lines: Array = [
		D._cue({"text": "Dans le canyon des Vents, la tempête hurle. Le sable fouette les joues de Chloé : elle voit à peine ses pieds."}, gust),
		D._cue({"text": "Par terre, deux sillons de roues s'enfoncent dans la poussière… et s'effacent à vue d'œil. Le vent les mange."},
			func() -> void: Stage.bow(chloe, 1.3)),
	]
	if guide:
		lines.append(D._cue({"text": "%s plisse les yeux, le museau au ras du sol." % guide.nickname}, func() -> void: D._sniff(dino)))
	await S.say(lines)
	var nose := "Suivre le nez %s" % French.de(guide.nickname) if guide else "Marcher le vent dans le dos"
	var pick := await Dialogue.choose("", "Par où aller ?", ["Suivre les traces de roues", nose])
	var follows := func() -> void:   # the guide first, straight on; Chloé after it
		if dino:
			D._companion_walk(chloe.global_position + ahead * 120.0, 90.0)
			await S.wait(0.6)
		await D._chloe_walk(chloe.global_position + ahead * 80.0, 100.0, 1.6)
	var circles := func() -> void:   # left, left again, left again… the same rock
		for i in 2:
			var step := ahead * 36.0
			for k in 4:
				await D._chloe_walk(chloe.global_position + step, 110.0, 0.9)
				step = step.rotated(-PI / 2.0)
	var after: Array = []
	if pick == 0:
		after.append_array([
			D._cue({"text": "Chloé suit les sillons. Ils tournent à gauche. Puis encore à gauche. Puis encore à gauche… et Chloé se retrouve devant le même rocher. Trois fois."}, circles),
			{"text": "Sur le rocher, quelqu'un a gravé au couteau, en grosses lettres maladroites : « PAR OÙ ?! »"},
			{"who": CHLOE, "text": "(Brac s'est perdu. Il a tourné en rond… et moi, je l'ai suivi.)"},
			D._cue({"text": "Heureusement, %s n'a jamais quitté le bon chemin du museau. Il repart tout droit, sans hésiter, et Chloé le suit." % guide.nickname if guide
				else "Chloé tourne le dos au rocher et avance, le vent dans le dos. Au bout d'un moment, les sillons reviennent, bien droits."}, follows),
		])
	elif guide:
		var sniffs_off := func() -> void:
			await D._sniff(dino)
			Stage.cry(dino, &"neutre")   # atchoum
			await D._sniff(dino)
			follows.call()
		after.append_array([
			D._cue({"text": "%s renifle, éternue (le sable !), renifle encore… et part tout droit, sans hésiter." % guide.nickname}, sniffs_off),
			D._cue({"text": "Un peu plus loin, les sillons reviennent. Autour d'un rocher, ils ont tourné trois fois en rond. Sur la pierre, gravé au couteau : « PAR OÙ ?! »"},
				func() -> void: Stage.bow(chloe, 1.2)),
			{"who": CHLOE, "text": "(Brac s'est perdu. Pas %s.)" % guide.nickname},
		])
	else:
		after.append(D._cue({"text": "Chloé avance le vent dans le dos, les yeux plissés. Un peu plus loin, les sillons reviennent : autour d'un rocher, ils ont tourné trois fois en rond. Brac s'est perdu, lui."}, follows))
	var far_voice := func() -> void:
		Stage.turn_to(chloe, chloe.global_position + ahead * 300.0)
		Stage.emote(chloe, "!")
	after.append_array([
		D._cue({"text": "Au loin, dans le hurlement du vent, une grosse voix : « PAR LÀ ! NON, PAR LÀ ! CROTTE DE STÉGOSAURE, OÙ EST LE NORD ?! »"}, far_voice),
		{"who": CHLOE, "text": "(Il n'est pas loin.)"},
	])
	await S.say(after)
	D._companion_back()
	if guide and guide == Game.lead_dino():
		S.world().companion.rejoice()


## Along the canyon, towards the dead end: the way from Chloé to `to` (tiles).
static func _towards(to: Vector2) -> Vector2:
	var chloe := Stage.chloe()
	return (S.at(to.x, to.y) - chloe.global_position).normalized() if chloe else Vector2.LEFT


## 2. A wheel of the cart comes out of the storm by itself and rolls straight at Chloé: the lead
## dino stops it, its own way (or Chloé jumps aside). Far away, Brac shouts for his wheel.
static func _wheel() -> void:
	var w = S.world()
	var chloe := Stage.chloe()
	var ahead := _towards(P.POURSUITES[2])
	var stop_at := chloe.global_position + ahead * 84.0
	var wheel := _make_wheel(S.ground_near(chloe.global_position + ahead * 340.0, 3))
	wheel.modulate.a = 0.0
	Audio.play_sfx(ROCK, -12.0)
	var listens := func() -> void:
		Stage.turn_to(chloe, stop_at)
		Stage.emote(chloe, "?")
		Stage.look_at(chloe.global_position + ahead * 110.0, 1.2)
	await S.say([D._cue({"text": "Un grincement dans la tempête. Puis un bruit sourd, qui roule, qui roule… et qui grossit."}, listens)])
	w.player.get_node("Camera").call(&"shake", 3.0, 0.5)
	var bursts := func() -> void:
		Stage.emote(chloe, "!")
		Stage.fade_in(wheel, 0.4)
		_roll(wheel, stop_at + ahead * 60.0, 2.4)
	await S.say([D._cue({"text": "Une roue de chariot surgit du sable, toute seule, et fonce droit sur Chloé !"}, bursts)])
	var lead := Game.lead_dino()
	await _wheel_hits(wheel, lead, ahead)
	await S.say([
		D._cue({"text": _wheel_stopped(lead)}, func() -> void: _wheel_pride(lead, wheel)),
		D._cue({"text": "C'est une roue du chariot de Brac, cerclée de fer. Sur le moyeu, un masque d'os gravé."}, func() -> void: Stage.bow(chloe, 1.2)),
		{"who": CHLOE, "text": "(Il a perdu une roue ! Son chariot ne va plus aller bien vite…)"},
		D._cue({"text": "Au loin, dans la tempête : « MA ROUE ! QUI A VOLÉ MA ROUE ?! »"},
			func() -> void: Stage.turn_to(chloe, chloe.global_position + ahead * 300.0)),
		{"who": CHLOE, "text": "(Personne. Elle est partie toute seule.)"},
	])
	D._companion_back()


static func _wheel_stopped(lead: Dino) -> String:
	if lead == null:
		return "Chloé plonge sur le côté. La roue passe en sifflant, rebondit contre un rocher — BONG ! — et se couche dans le sable."
	var name := lead.nickname
	match lead.species().family:
		&"armored":
			return "%s se plante devant Chloé et baisse la tête. BONG ! La roue rebondit sur sa carapace, fait trois tours sur elle-même et se couche dans le sable. %s n'a pas bougé d'un millimètre. Il a l'air très fier." % [name, name]
		&"raptor":
			return "%s bondit par-dessus la roue, se retourne en plein saut… et atterrit dessus. La roue se couche dans le sable, avec un raptor très fier assis au milieu." % name
		&"hadrosaur":
			return "%s pousse un appel grave, si fort que… non, la roue s'en fiche complètement. Chloé et %s plongent chacun d'un côté ; la roue passe entre eux et s'arrête contre un rocher. BONG." % [name, name]
		&"ceratopsian":
			return "%s baisse les cornes et charge la roue. BONG ! Elle s'envole, retombe, roule encore un peu… et se couche, vaincue." % name
	return "%s se jette devant Chloé. La roue rebondit, fait trois tours sur elle-même et se couche dans le sable. BONG." % name


## The wheel reaches them, just before the line that tells it: her dino stops it (BONG), or
## they dive aside and it rolls on between them, into a rock.
static func _wheel_hits(wheel: Node2D, lead: Dino, ahead: Vector2) -> void:
	var chloe := Stage.chloe()
	var dino := D._companion() if lead else null
	var family: StringName = lead.species().family if lead else &""
	Stage.look_back(0.3)
	if dino == null or family == &"hadrosaur":   # its call does nothing: everyone dives aside
		var side := ahead.orthogonal()
		if dino:
			Stage.cry(dino, &"neutre")
			D._companion_walk(dino.global_position - side * 40.0, 260.0)
		Stage.recoil(chloe, chloe.global_position - side * 30.0, 26.0)
		await _roll(wheel, chloe.global_position - ahead * 140.0, 0.8)
		_wheel_falls(wheel, ahead * 16.0)
		await S.wait(0.3)
		return
	if family == &"armored":   # it plants itself in front of her
		D._companion_walk(chloe.global_position + ahead * 40.0, 300.0)
		await _roll(wheel, chloe.global_position + ahead * 84.0, 0.3)
	else:
		dino.perform_at(wheel.global_position - ahead * 50.0)
		await _roll(wheel, chloe.global_position + ahead * 70.0, 0.25)
	_wheel_falls(wheel, ahead * 30.0)
	await S.wait(0.4)


## How the lead dino looks once the wheel is down (with the line that tells it).
static func _wheel_pride(lead: Dino, wheel: Node2D) -> void:
	var dino := D._companion()
	if lead == null or dino == null:
		return
	match lead.species().family:
		&"armored":   # head down, then very proud
			D._fresh(dino)
			await Stage.bow(dino, 0.8)
			await S.wait(0.8)
			Stage.rear(dino, 0.9)
		&"raptor":   # over the wheel, and down on it
			await Stage.hop(dino, 1, 26.0)
			await S.wait(1.0)
			if is_instance_valid(wheel):
				await D._companion_walk(wheel.global_position + Vector2(0.0, 2.0), 160.0)
				Stage.turn_to(dino, Stage.chloe().global_position)
				D._fresh(dino)
				Stage.rear(dino, 0.9)   # very proud


## Brac's lost wheel, made here (it has no picture of its own): rolling, its spokes turn.
static func _make_wheel(at_px: Vector2) -> Node2D:
	var frames := SpriteFrames.new()
	frames.add_animation(&"roll")
	frames.set_animation_speed(&"roll", 16.0)
	var painted: Image = _painted_wheel()
	for i in 3:
		var turn := i * TAU / 24.0
		frames.add_frame(&"roll", _turned(painted, turn) if painted else _wheel_picture(turn))
	var wheel := Node2D.new()
	wheel.name = "RoueBrac"
	wheel.position = at_px
	Shadow.make(wheel, 34.0)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * WHEEL_SCALE
	sprite.offset = Vector2(0.0, -WHEEL_PX / 2.0)
	wheel.add_child(sprite)
	S.world().region.entities.add_child(wheel)
	sprite.play(&"roll")
	return wheel


## The painted wheel (props/roue_chariot.png), squared to WHEEL_PX; null while there is none
## (then _wheel_picture draws one).
static func _painted_wheel() -> Image:
	if not ResourceLoader.exists(PAINTED_WHEEL):
		return null
	var img: Image = (load(PAINTED_WHEEL) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(WHEEL_PX, WHEEL_PX, Image.INTERPOLATE_BILINEAR)
	return img


## `img` turned by `turn` round its centre: the spokes of the rolling wheel.
static func _turned(img: Image, turn: float) -> ImageTexture:
	var out := Image.create_empty(WHEEL_PX, WHEEL_PX, false, Image.FORMAT_RGBA8)
	var centre := Vector2(WHEEL_PX, WHEEL_PX) / 2.0
	for y in WHEEL_PX:
		for x in WHEEL_PX:
			var from := (Vector2(x + 0.5, y + 0.5) - centre).rotated(-turn) + centre
			var sx := int(from.x)
			var sy := int(from.y)
			if sx >= 0 and sy >= 0 and sx < WHEEL_PX and sy < WHEEL_PX:
				out.set_pixel(x, y, img.get_pixel(sx, sy))
	return ImageTexture.create_from_image(out)


## The wheel's picture: an iron tyre, a wooden rim, eight spokes turned by `turn`, the hub.
static func _wheel_picture(turn: float) -> ImageTexture:
	var img := Image.create_empty(WHEEL_PX, WHEEL_PX, false, Image.FORMAT_RGBA8)
	var centre := Vector2(WHEEL_PX, WHEEL_PX) / 2.0
	var outer := WHEEL_PX / 2.0 - 1.0
	for y in WHEEL_PX:
		for x in WHEEL_PX:
			var p := Vector2(x + 0.5, y + 0.5) - centre
			var r := p.length()
			var colour := Color(0, 0, 0, 0)
			if r > outer * 0.88:
				colour = WHEEL_IRON
			elif r > outer * 0.74:
				colour = WHEEL_WOOD.darkened(0.2 if r > outer * 0.82 else 0.0)
			elif r < outer * 0.12:
				colour = WHEEL_IRON
			elif r < outer * 0.22:
				colour = WHEEL_WOOD.darkened(0.35)
			else:
				var a := fposmod(p.angle() - turn, TAU / 8.0)
				if minf(a, TAU / 8.0 - a) * r < 2.0:
					colour = WHEEL_WOOD
			colour.a *= clampf(outer + 0.5 - r, 0.0, 1.0)
			img.set_pixel(x, y, colour)
	return ImageTexture.create_from_image(img)


## Rolls the wheel to `px` in `secs`. Awaitable.
static func _roll(wheel: Node2D, px: Vector2, secs: float) -> void:
	if not is_instance_valid(wheel):
		return
	var sprite := wheel.get_node("Sprite") as AnimatedSprite2D
	sprite.flip_h = px.x < wheel.global_position.x
	sprite.play(&"roll")
	var t := wheel.create_tween()
	t.tween_property(wheel, "global_position", px, secs)
	await t.finished


## BONG: the wheel bounces back by `back`, spins on the spot three times and lies down in
## the sand. Awaitable.
static func _wheel_falls(wheel: Node2D, back: Vector2) -> void:
	if not is_instance_valid(wheel):
		return
	var sprite := wheel.get_node("Sprite") as AnimatedSprite2D
	Audio.play_sfx(ROCK, -4.0)
	Stage.shake(3.0, 0.3)
	wheel.create_tween().tween_property(wheel, "global_position", wheel.global_position + back, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var bounce := sprite.create_tween()
	bounce.tween_property(sprite, "position:y", -16.0, 0.18).set_ease(Tween.EASE_OUT)
	bounce.tween_property(sprite, "position:y", 0.0, 0.2).set_ease(Tween.EASE_IN)
	await S.wait(1.1)   # three turns on the spot
	if not is_instance_valid(sprite):
		return
	var lies := sprite.create_tween()
	lies.tween_property(sprite, "scale:y", sprite.scale.y * 0.28, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await lies.finished
	if is_instance_valid(sprite):
		sprite.stop()
		D._puff(wheel.global_position, 14, 0.2)


## 3. A henchman lost in the sand, his bone mask on his ear, asks the way (Firmin, from the
## Forêt's camp): Brac is at the end of the canyon, in a dead end; he goes home to fish.
static func _lost_henchman() -> void:
	var w = S.world()
	var known: bool = Game.flag(&"sbire_camp_1_vu")
	var speaker := FIRMIN if known else "Un sbire"
	var ahead := _towards(P.BRAC_DESERT)   # he comes out of the storm, from further along the canyon
	var lost := S.stranger("SbirePerdu", "sbire", S.ground_near(w.player.global_position + ahead * 240.0, 3), "left", speaker)
	lost.modulate.a = 0.0
	var near_her: Vector2 = w.player.global_position + ahead * 80.0 + Vector2(0.0, -6.0)
	var gropes := func() -> void:   # a step, a stop, groping, another step
		Stage.fade_in(lost, 0.8)
		await lost.walk_to(lost.global_position.lerp(near_her, 0.55), "", 60.0)
		await S.wait(0.6)
		if is_instance_valid(lost):
			await lost.walk_to(near_her, "", 60.0)
			lost.face(w.player.global_position)
	var lines: Array = [
		D._cue({"text": "Une silhouette sort de la tempête à tâtons, les bras tendus comme un somnambule. Son masque d'os est de travers : il le porte sur l'oreille."}, gropes),
		{"who": speaker, "text": "Pardon… Excusez-moi… Vous n'auriez pas vu un grand monsieur roux, avec un chariot et un très gros lézard rouge ?"},
	]
	if known:
		lines.append_array([
			{"who": CHLOE, "text": "Firmin ?!"},
			D._cue({"who": FIRMIN, "text": "… Oh non. Pas toi. Pas ENCORE toi."}, func() -> void: Stage.bow(lost, 1.0)),
			{"who": FIRMIN, "text": "Je devais suivre le chef. Mais j'ai du sable dans les yeux, dans les oreilles, et dans des endroits que je ne peux pas dire à une petite fille."},
			{"who": FIRMIN, "text": "Gustave m'avait dit : « Viens pêcher avec moi, Firmin. » Et moi, j'ai répondu : « Non. Le désert, c'est l'AVENTURE. »"},
		])
	else:
		lines.append_array([
			{"who": speaker, "text": "… Attends. Une gamine avec des dinos. T'es le moucheron ! Celui dont le chef parle tout le temps, en tapant sur les tables !"},
			{"who": speaker, "text": "Je devais le suivre, mais j'ai du sable partout. PARTOUT."},
		])
	await S.say(lines)
	var pick := await Dialogue.choose(speaker, "Tu… tu ne vas pas me combattre, hein ? Je n'ai plus de dino. Il s'est envolé. C'était un Dimorphodon.",
		["Non. Où est Brac ?", "Non. Rentre chez toi."])
	var after: Array = []
	if pick == 0:
		after.append_array([
			{"who": CHLOE, "text": "Pas de combat. Mais dis-moi où est Brac."},
			{"who": speaker, "text": "Tout au fond du canyon. Mais c'est un cul-de-sac, et il ne le sait pas encore. Moi, je ne lui dirai pas : il crie, quand on lui dit des choses."},
		])
	else:
		after.append_array([
			{"who": CHLOE, "text": "Pas de combat. Rentre chez toi : Brac n'en vaut pas la peine."},
			{"who": speaker, "text": "Tu as raison. Tu as tellement raison."},
			{"who": speaker, "text": "Et si tu le cherches : il est tout au fond du canyon. C'est un cul-de-sac. Il ne le sait pas encore."},
		])
	after.append_array([
		{"who": speaker, "text": "Euh… La mer, c'est par où ?"},
		{"who": CHLOE, "text": "Tout droit vers le sud-est, puis le lac de sel, puis le Marais."},
		{"who": speaker, "text": "Le Marais… Il y a des trucs qui nagent, dans le Marais ?"},
		{"who": CHLOE, "text": "Plein."},
		{"who": speaker, "text": "… Parfait. Je nagerai." + (" Au revoir, petite. Et si tu croises Gustave, dis-lui que j'arrive. Avec du sable." if known else " Au revoir, moucheron.")},
	])
	await S.say(after)
	var fade: Tween = lost.create_tween()
	fade.tween_interval(0.5)
	fade.tween_property(lost, "modulate:a", 0.0, 0.8)
	await lost.walk_to(lost.global_position + Vector2(240.0, 140.0), "right", 110.0)
	if is_instance_valid(lost):
		lost.queue_free()
	await S.say([{"who": CHLOE, "text": "(Un cul-de-sac… Brac est coincé. J'arrive.)"}])


# ------------------------------------------------------------------ Brac, cornered

## Brac in the dead end of the canyon des Vents (Npc « BracDesert »): a few words, then the
## battle (Cabosse, Grognon, Mastoc). Beaten, he climbs away over the rock, swearing, and
## leaves the Alpha, who breaks out of the cage.
static func brac(who: Node) -> void:
	if Game.flag(&"brac_desert_battu"):
		return
	if not Game.flag(&"brac_desert_parle"):
		S.lock(true)
		await S.say(_brac_hello(who))
		Game.set_flag(&"brac_desert_parle")
		S.lock(false)
	else:
		await S.say([{"who": BRAC, "text": "Encore toi ?! Tu n'as pas eu ton compte, moucheron ? Cabosse, Grognon, Mastoc : on remet ça !"}])
	var rules := {"lose_spawn": P.LOSE_BRAC}
	var theme: AudioStream = ForetCamp.music_at(OMBRE_MUSIC)
	if theme:
		rules["music"] = theme
	if not await S.duel(BRAC, BRAC_TEAM, rules):
		return
	# Won: the state is safe even if the scene below is cut short (Brac gone, the Alpha free).
	Game.set_flag(&"brac_desert_battu")
	Save.save_game()
	await _brac_beaten(who)


static func _brac_hello(who: Node) -> Array:
	var wheel: bool = Game.flag(&"poursuite_2_ok")
	var cart = S.actor("ChariotBrac")
	var chloe := Stage.chloe()
	var banging := {}   # the Carnotaurus in the cage, against the bars (the cart jolts)
	var bangs := func() -> void:
		D._step_aside(who)
		if cart is Node2D:
			var at: Vector2 = (cart as Node2D).global_position
			Stage.look_at(at.lerp(chloe.global_position, 0.35))
			banging["loop"] = Stage.rage(cart, at + Vector2(60.0, 10.0), 1.1)
			(who as Npc).face(at)
		_cry("tyran", "attaque", -9.0, 0.85)
		await S.wait(2.2)
		_cry("tyran", "attaque", -11.0, 0.8)
	var rants := func() -> void:   # at the rock, his back to Chloé (he has not seen her)
		(who as Npc).face((who as Node2D).global_position + Vector2(-30.0, -100.0))
		Stage.hop(who, 2, 8.0)
	var turns := func() -> void:
		Stage.stop(cart, banging.get("loop"))
		Stage.look_back()
		(who as Npc).face(chloe.global_position)
		await S.wait(0.6)
		Stage.bow(who, 1.4)   # eyes shut very tight
	var over_the_shoulder := func() -> void:
		await S.wait(1.4)
		(who as Npc).face((who as Node2D).global_position + Vector2(0.0, -100.0))
		await S.wait(1.2)
		if is_instance_valid(who):
			(who as Npc).face(chloe.global_position)
	var lines: Array = [
		D._cue({"text": "Au bout du canyon, la roche se referme en cul-de-sac. Le chariot de Brac est là, penché sur trois roues, et dans la cage, le Carnotaurus Rouge se cogne contre les barreaux." if wheel
			else "Au bout du canyon, la roche se referme en cul-de-sac. Le chariot de Brac est là, et dans la cage, le Carnotaurus Rouge se cogne contre les barreaux."}, bangs),
		D._cue({"who": BRAC, "text": "Un cul-de-sac ! Qui met un CUL-DE-SAC au bout d'un canyon ?! C'est n'importe quoi, ce désert !"}, rants),
	]
	if wheel:
		lines.append(D._cue({"who": BRAC, "text": "Et j'ai perdu une roue ! Une roue toute neuve ! Enfin, presque neuve. Enfin, volée, mais neuve."}, rants))
	lines.append_array([
		D._cue({"text": "Il se retourne. Il voit Chloé. Il ferme les yeux très fort, comme s'il espérait qu'elle disparaisse."}, turns),
		{"who": BRAC, "text": "… Évidemment. Le moucheron."},
		{"who": CHLOE, "text": "Laissez-le partir, Brac. Il n'ouvrira jamais la porte pour vous. Elle ne s'ouvre qu'au gardien sans peur."},
		{"who": BRAC, "text": "Sans peur, sans peur… Il a peur de TOUT, ce gros lézard ! Des cailloux, du vent, de son ombre ! Il a même peur de MOI !"},
		{"who": CHLOE, "text": "C'est vous qui lui avez fait ça."},
		D._cue({"text": "Brac ouvre la bouche. La referme. Puis il jette un coup d'œil par-dessus son épaule, comme si quelqu'un pouvait l'entendre."}, over_the_shoulder),
		{"who": BRAC, "text": "Si je rentre sans le Cœur, le Masque va… Non. Non, non. Tu ne comprends rien, gamine."},
		D._cue({"text": "Il rabat son masque d'os sur son visage, d'un coup de pouce."}, func() -> void: Stage.bow(who, 0.4)),
		D._cue({"who": BRAC, "text": "Cabosse ! Grognon ! Mastoc ! Au travail ! On va montrer à ce moucheron ce que valent les dents du Désert !"}, func() -> void: Stage.rear(who, 0.7)),
	])
	return lines


## Beaten: he swears, gives up the Alpha (« il n'a jamais voulu rugir comme il faut ! »),
## climbs away over the rock; the Carnotaurus breaks out of the cage, mad with fear. Chloé may
## try to calm it at once, or heal first.
static func _brac_beaten(who: Node) -> void:
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var cart = S.actor("ChariotBrac")
	var cart_px: Vector2 = (cart as Node2D).global_position if cart is Node2D else S.at(P.CHARIOT.x, P.CHARIOT.y)
	var jolts := func() -> void:
		_cry("tyran", "attaque", -4.0, 0.82)
		Stage.shake(4.0, 0.4)
		Stage.lunge(cart, (who as Node2D).global_position, 1.2, false)
		Stage.hop(who, 1, 16.0)
		Stage.recoil(who, cart_px, 24.0)
	await S.say([
		D._cue({"who": BRAC, "text": "Non… Non, non, NON ! Encore ?! Mastoc ! Tu as MORDU un caillou ! Pourquoi tu as mordu un caillou ?!"}, func() -> void: Stage.hop(who, 3, 9.0)),
		{"who": BRAC, "text": "Crotte de Stégosaure ! Nom d'un fossile moisi ! Par les écailles de ma grand-mère !"},
		D._cue({"text": "Dans la cage, le Carnotaurus Rouge hurle et se jette contre les barreaux. Brac fait un bond en arrière."}, jolts),
		{"who": BRAC, "text": "Tu le veux, ton gros lézard ? PRENDS-LE ! De toute façon, il n'a jamais voulu rugir comme il faut !"},
	])
	await S.say(_brac_climbs(who))
	if is_instance_valid(who):
		who.queue_free()
	var carno := await _carno_breaks_out(cart_px)
	await S.say([{"text": "CRAAAC ! Dans la cage, les barreaux cèdent d'un coup. Le Carnotaurus Rouge est libre… et il a peur de tout."}])
	await S.say([
		D._cue({"text": "Il tourne en rond devant la cage, les yeux troubles, la gueule ouverte. Chaque coup de vent le fait sursauter."}, func() -> void: _restless(carno)),
		{"who": CHLOE, "text": "(Il n'est pas méchant. Il a peur. Peur de l'ambre noir qu'on lui a fait avaler, peur de la cage, peur de lui-même.)"},
	])
	Game.award_team_xp(XP_BRAC)
	Save.save_game()
	S.lock(false)
	await carnotaurus(carno)


## Brac climbs away up an old rope, turns round at the top, red as a tomato, and is gone.
static func _brac_climbs(who: Node) -> Array:
	var chloe := Stage.chloe()
	var cliff := _cliff_foot(S.at(P.BRAC_FUITE.x, P.BRAC_FUITE.y))
	var foot: Vector2 = cliff[0]
	var climbs := func() -> void:
		Stage.look_at(foot.lerp(chloe.global_position, 0.25) + Vector2(0.0, -40.0), 1.2)
		if not is_instance_valid(who):
			return
		# In front of the cart, not through it, to the foot of the rock face where the rope hangs.
		var round_cart := S.at(P.CHARIOT.x + 1.9, P.CHARIOT.y + 1.9)
		var past_cart := S.at(P.CHARIOT.x - 2.2, P.CHARIOT.y + 1.9)
		await (who as Npc).walk_path([round_cart, past_cart, foot], "up", 190.0)
		if not is_instance_valid(who):
			return
		var sprite := Stage.sprite_of(who)
		if sprite:   # up the rope, puffing
			sprite.create_tween().tween_property(sprite, "position:y", sprite.position.y - float(cliff[1]), 2.0).set_trans(Tween.TRANS_SINE)
	var turns := func() -> void:
		if is_instance_valid(who):
			(who as Npc).face(chloe.global_position)
			Stage.glow(who, Color(1.7, 0.75, 0.65), 1, 1.8)
	var gone := func() -> void:
		Stage.fade_out(who, 0.8)
		Stage.look_back(1.0)
	return [
		D._cue({"text": "Brac attrape une vieille corde qui pend de la falaise et grimpe, en soufflant comme un Stegosaurus dans une montée."}, climbs),
		D._cue({"text": "Tout en haut, il se retourne, rouge comme une tomate."}, turns),
		D._cue({"who": BRAC, "text": "Ce n'est pas fini, moucheron ! Le Masque… le Masque va… Oh, crotte."}, func() -> void: Stage.hop(who, 1, 6.0)),
		D._cue({"text": "Et il disparaît de l'autre côté. On l'entend jurer longtemps, de plus en plus loin, jusqu'à ce que le vent emporte les derniers gros mots."}, gone),
	]


## Where Brac climbs away: the foot of the rock face below `top` (world pixels), on the canyon
## floor, and how high he climbs (the picture's lift, px) to be at the top.
static func _cliff_foot(top: Vector2) -> Array:
	var w = S.world()
	var chloe := Stage.chloe()
	if w == null or chloe == null:
		return [top, 44.0]
	var region: Region = w.region
	var floor_h: float = region.tile_height(Vector2i((chloe.global_position / S.CELL).floor()))
	var cell := Vector2i((top / S.CELL).floor())
	var top_h: float = region.tile_height(cell)
	for i in 10:
		if absf(region.tile_height(cell) - floor_h) < 0.3:
			break
		cell.y += 1
	var rise := maxf(44.0, (top_h - floor_h) * S.CELL / 1.15)   # (the 3D view's upright stretch)
	return [(Vector2(cell) + Vector2(0.5, 0.35)) * S.CELL, rise]


## The Carnotaurus goes home: up the canyon des Vents, the way the chase came (not through the
## rock), fading out in the distance.
static func _up_the_canyon(who: Node) -> void:
	var legs: Array = [P.POURSUITES[2], P.POURSUITES[1]]
	for i in legs.size():
		if not is_instance_valid(who):
			return
		if i == legs.size() - 1:
			Stage.fade_out(who, 2.5)
		await (who as DinoNpc).walk_to(S.at(legs[i].x, legs[i].y), 150.0)
	if is_instance_valid(who):
		who.queue_free()


## CRAAAC: the bars give way and the Carnotaurus bursts out of the cage (made at the cart, it
## leaps to where it stays), just before the line. Returns it.
static func _carno_breaks_out(cart_px: Vector2) -> DinoNpc:
	var there = S.actor("CarnotaurusRouge")
	var carno := _carno_npc()
	Audio.play_sfx(LATCH, -2.0)
	_cry("tyran", "attaque", -2.0, 0.8)
	Stage.shake(7.0, 0.5)
	Stage.look_at(cart_px.lerp(carno.global_position, 0.6), 0.3)
	Stage.lunge(S.actor("ChariotBrac"), cart_px + Vector2(0.0, -60.0), 1.6, false)
	if there == null:   # made just now: out of the cage in one leap
		var spot := carno.global_position
		carno.global_position = cart_px + Vector2(16.0, 4.0)
		carno.modulate.a = 0.0
		carno.create_tween().tween_property(carno, "modulate:a", 1.0, 0.15)
		await carno.walk_to(spot, 320.0)
		Stage.cry(carno, &"attaque")
	return carno


## The Carnotaurus, mad with fear, goes round and round in front of the cage, starting at each
## gust (until _still). Once only, even when asked again.
static func _restless(carno: Node) -> void:
	if not carno is DinoNpc or not is_instance_valid(carno) or carno.has_meta(&"restless"):
		return
	var home: Vector2 = (carno as Node2D).global_position
	var chloe := Stage.chloe()
	var away: Vector2 = (home - chloe.global_position).normalized() if chloe else Vector2.LEFT
	var side := away.orthogonal()   # back and forth across her view, not onto her
	var token := Stage.pace(carno, home + away * 24.0 + side * 44.0, home + away * 24.0 - side * 44.0, 80.0)
	carno.set_meta(&"restless", token)
	while token["on"] and is_instance_valid(carno):
		await S.wait(randf_range(1.6, 3.2))
		if token["on"] and is_instance_valid(carno):
			Stage.hop(carno, 1, 7.0)   # a gust: it starts


static func _still(carno: Node) -> void:
	if is_instance_valid(carno) and carno.has_meta(&"restless"):
		Stage.stop_pacing(carno.get_meta(&"restless"))
		carno.remove_meta(&"restless")


## Brac's cart (StoryProp « ChariotBrac »): Brac guards it; once he is gone, what it carried —
## his list, black amber in a crate stamped « …ptoir d'Amb… », and a note from « M. ».
static func chariot(who: Node) -> void:
	var chloe := Stage.chloe()
	if not Game.flag(&"brac_desert_battu"):
		var boss = S.actor("BracDesert")
		var bangs := func() -> void:
			_cry("tyran", "attaque", -6.0, 0.85)
			Stage.lunge(who, chloe.global_position, 1.0, false)
		var shouts := func() -> void:
			if boss:
				boss.face(chloe.global_position)
				Stage.emote(boss, "!")
		await S.say([
			D._cue({"text": "Le chariot-cage de Brac. Dans la cage, le Carnotaurus Rouge se jette contre les barreaux, les yeux violets."}, bangs),
			D._cue({"who": BRAC, "text": "HÉ ! Pas touche à mon chariot, moucheron !"}, shouts),
		])
		if boss:
			await brac(boss)
		return
	if Game.flag(&"chariot_fouille"):
		await S.say([{"text": ForetCamp.next_line(&"chariot_n", CHARIOT_AGAIN)}])
		return
	S.lock(true)
	var lines: Array = [
		D._cue({"text": "Le chariot de Brac, penché dans le sable. La cage est ouverte, les barreaux tordus. Dessous, un vrai bric-à-brac : des cordes, des chaînes, un pot de moutarde, et une pile de papiers."},
			func() -> void: Stage.bow(chloe, 1.2)),
		{"text": "Tout en haut, la liste de Brac, en grosses lettres maladroites : « À ATTRAPER. L'Alpha de la Forêt : RATÉ (la gamine). Le Carnotaurus Rouge : … » Le reste n'est qu'un grand gribouillis rageur."},
		{"who": CHLOE, "text": "(« RATÉ, la gamine. » C'est moi. Il a même écrit « la gamine ».)"},
		{"text": "Dans une caisse, des pierres noires veinées de violet, enveloppées dans un chiffon. Sur le bois, un tampon à moitié effacé : « …ptoir d'Amb… »"},
	]
	var lead := Game.lead_dino()
	if lead:
		var growls := func() -> void:
			var dino := D._companion()
			Stage.cry(dino, &"attaque")
			D._fresh(dino)
			Stage.bow(dino, 0.8)
		lines.append(D._cue({"text": "%s gronde tout bas, le nez froncé : l'odeur de cendre froide." % lead.nickname}, growls))
	if Game.flag(&"havre_arrive"):
		lines.append({"who": CHLOE, "text": "(« …ptoir d'Amb… » ? Comme le Comptoir d'Ambre, à Havre-Doré ?)"})
	lines.append_array([
		D._cue({"text": "Chloé enveloppe l'ambre noir dans le chiffon et le glisse au fond de sa sacoche, bien fermée. Il ne fera plus peur à personne. Roc saura quoi en faire. … Enfin, elle l'espère."},
			func() -> void: Stage.bow(chloe, 1.0)),
		D._cue({"text": "Sous la caisse, un petit mot plié en quatre. Papier noir, encre argentée, écriture fine et droite. Comme dans la Forêt."},
			func() -> void: Stage.emote(chloe, "!")),
		{"text": "« Brac. L'Alpha rugira devant la porte : la peur ouvre tout. S'il refuse, ne force pas. D'autres ouvriront les portes pour nous. Rapporte-moi le Cœur avant la grande marée. — M. »"},
		{"who": CHLOE, "text": "(« D'autres ouvriront les portes pour nous »… Qui ça, « d'autres » ?)"},
	])
	if Game.flag(&"found_journal_20"):
		lines.append({"who": CHLOE, "text": "(Roc a une copie de la carte des sanctuaires… Non. Non, pas lui.)"})
	lines.append_array([
		{"text": "Le papier sent le sel. Et, tout au fond, un peu la cendre."},
		{"who": CHLOE, "text": "(La grande marée… Pourquoi parler de marée, au milieu du désert ?)"},
		{"flag": &"chariot_fouille"},
	])
	await S.say(lines)
	Game.award_team_xp(XP_CHARIOT)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ the Carnotaurus Rouge

## The Carnotaurus, free but mad with fear (DinoNpc « CarnotaurusRouge », near the cart): the
## long calming (her own hatchling in front, if she wants); calmed, it goes home and opens the
## door. When it was calmed but the door scene did not play (a reload), the door scene.
static func carnotaurus(who: Node) -> void:
	if Game.flag(&"sceau_desert") or not Game.flag(&"brac_desert_battu"):
		return
	if Game.flag(&"carnotaurus_apaise"):
		await _to_the_door(who)
		return
	var prompt := "Le Carnotaurus Rouge tourne en rond, fou de peur. Chaque coup de vent le fait sursauter."
	_restless(who)
	var pick := 0
	if _party_worn():
		# Tired after Brac: the first choice is to get their breath back (as by the Spinosaure's pool).
		pick = await Dialogue.choose("", prompt + " Ton équipe est épuisée : mieux vaut souffler un peu d'abord.",
			["Souffler un peu, à l'abri du chariot", "L'approcher tout de suite", "Pas encore"])
		if pick == 0:
			await _catch_breath()
		else:
			pick -= 1
	else:
		pick = await Dialogue.choose("", prompt, ["L'approcher doucement", "Pas encore"])
	_still(who)
	if pick != 0:
		var backs := func() -> void:
			var chloe := Stage.chloe()
			Stage.recoil(chloe, (who as Node2D).global_position, 16.0)
			await S.wait(0.8)
			Stage.turn_to(who, chloe.global_position)
		await S.say([D._cue({"text": "Chloé recule doucement. Le Carnotaurus ne la quitte pas des yeux… mais il ne s'en va pas. Il n'a nulle part où aller."}, backs)])
		return
	await _starter_first(who)
	var foe := Dino.create(&"carnotaurus", CARNO_LEVEL, "Carnotaurus Rouge")
	foe.corrupted = true
	var rules := {"catch": false, "run": false, "long_calm": true, "lose_spawn": P.LOSE_BRAC, "size": CARNO_SIZE,
		"intro": "Le Carnotaurus Rouge se dresse devant toi, fou de peur !"}
	if not Game.flag(&"carno_lecon"):
		rules["lesson"] = LONG_LESSON
	var theme: AudioStream = ForetCamp.music_at(ALPHA_MUSIC)
	if theme:
		rules["music"] = theme
	var result: String = await S.world().call(&"_battle", foe, rules)
	Game.set_flag(&"carno_lecon")
	if result != "calmed":
		D._companion_back()
		return
	Game.set_flag(&"carnotaurus_apaise")
	Save.save_game()
	await _carno_calmed(who)


## Before the long calming: her own hatchling at the front (if it is not already).
static func _starter_first(who: Node) -> void:
	var mine: Dino = Foret.starter()
	if mine == null:
		return
	if not Game.party.has(mine):
		await S.say([{"who": CHLOE, "text": "(Si seulement %s était là… Hélène disait que c'est le Lien qui calme les plus grandes peurs.)" % mine.nickname}])
		return
	if mine.hp <= 0:
		return
	if Game.party[0] != mine:
		var pick := await Dialogue.choose("", "%s est lié à toi depuis le premier jour. Avec lui en tête, le Carnotaurus l'écoutera peut-être." % mine.nickname,
			["%s, avec moi !" % mine.nickname, "Garder mon équipe"])
		if pick != 0:
			return
		Game.set_lead(Game.party.find(mine))
	var brave := "%s passe devant Chloé, tout petit face au géant rouge. Il ne recule pas." % mine.nickname
	match mine.species().family:
		&"armored":
			brave = "%s se plante devant Chloé, face au géant rouge, les pattes bien enfoncées dans le sable. Un Ankylosaurus ne recule jamais." % mine.nickname
		&"hadrosaur":
			brave = "%s passe devant Chloé et lève sa crête, face au géant rouge. Il tremble un peu. Il ne recule pas." % mine.nickname
	var family: StringName = mine.species().family
	var steps_up := func() -> void:
		var dino := D._companion()
		if dino == null or not is_instance_valid(who):
			return
		var chloe := Stage.chloe()
		await D._companion_walk(chloe.global_position.lerp((who as Node2D).global_position, 0.3), 70.0)
		if family == &"hadrosaur":
			Stage.tremble(dino, 1.4, 1.5)
		elif family == &"armored":
			D._fresh(dino)
			D._crouch(dino, 0.08, 0.4)   # feet dug in the sand
	await S.say([D._cue({"text": brave}, steps_up)])


## Calmed: the veins fade, its eyes turn the colour of embers; the one who stood in front gets
## a heart of Lien; the wind drops and the storm with it. Then it goes home.
static func _carno_calmed(who: Node) -> void:
	S.lock(true)
	_still(who)
	var calms := func() -> void:
		if is_instance_valid(who) and who is DinoNpc:
			who.cleanse()
		await Stage.tremble(who, 1.0, 3.0)   # it staggers…
		D._crouch(who, 0.2, 1.2)   # …and lies down
	await S.say([
		D._cue({"text": "Les veines violettes pâlissent, puis s'effacent, une à une. Le Carnotaurus chancelle… et se couche dans le sable, épuisé."}, calms),
		D._cue({"text": "Quand il rouvre les yeux, ils ne sont plus violets. Ils sont couleur de braise : chauds, et calmes."},
			func() -> void: Stage.glow(who, EMBER, 1, 1.8)),
	])
	await S.say(_helper_lines(who))
	Game.set_weather(&"clear")
	await S.say([
		{"text": "Et d'un coup, le vent tombe. Le sable retombe en pluie fine, tout doucement, et le ciel redevient bleu."},
		{"who": CHLOE, "text": "(Même la tempête avait peur, on dirait.)"},
	])
	D._companion_back()
	Game.award_team_xp(XP_CARNO)
	Save.save_game()
	S.lock(false)
	await _to_the_door(who)


## What the Carnotaurus does with the dino that stood between them (her own hatchling, when it led).
static func _helper_lines(who: Node) -> Array:
	var mine: Dino = Foret.starter()
	var lead := Game.lead_dino()
	var dino := D._companion()
	var chloe := Stage.chloe()
	var lines: Array = []
	if mine and lead == mine:
		var breathes := func() -> void:
			if dino:
				await D._reach(who, dino.global_position, 16.0, 1.6)
			D._puff(D._head_of(who), 10, 0.5)
		lines.append(D._cue({"text": "%s ne l'a pas quitté des yeux une seule seconde. Le Carnotaurus baisse sa grosse tête jusqu'à lui et souffle : un souffle chaud, qui sent le sable et le soleil." % mine.nickname}, breathes))
		if str(Game.flag(&"starter")) == "ankylosaurus" and Game.flag(&"rempart_rencontre"):
			lines.append(D._cue({"text": "Il renifle longuement la carapace %s. Il connaît cette odeur-là : celle de la vieille dame du canyon muré. Ils sont voisins depuis trente ans." % French.de(mine.nickname)},
				func() -> void: D._reach(who, dino.global_position if dino else chloe.global_position, 12.0, 1.8)))
		Game.add_bond(mine, 1)
		lines.append(D._cue({"text": "Entre Chloé et %s, quelque chose s'est resserré. Plus solide qu'avant." % mine.nickname},
			func() -> void: Stage.emote(dino, "♥")))
	elif lead:
		var sniffs := func() -> void:
			if dino:
				await D._reach(who, dino.global_position, 12.0, 1.0)
			D._reach(who, chloe.global_position, 12.0, 1.0)
		lines.append(D._cue({"text": "Le Carnotaurus renifle %s, puis Chloé. Il ne tremble plus." % lead.nickname}, sniffs))
	else:
		lines.append(D._cue({"text": "Le Carnotaurus renifle Chloé. Il ne tremble plus."}, func() -> void: D._reach(who, chloe.global_position, 12.0, 1.0)))
	return lines


## It goes home through the canyon; at the door, it roars — a true roar — and the door opens.
## It lays the Sceau du Désert at Chloé's feet, purrs when she scratches its horns, and lies
## down by the open door: the guardian is home.
static func _to_the_door(who: Node) -> void:
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	if is_instance_valid(who) and who is DinoNpc and who.corrupted:
		await who.cleanse()
	var chloe := Stage.chloe()
	var canyon := S.at(P.CANYON_VENTS.x, P.CANYON_VENTS.y)
	var sets_off := func() -> void:
		D._get_up(who, 0.9)
		Stage.turn_to(who, chloe.global_position)
		await S.wait(1.5)
		if not is_instance_valid(who):   # (the lines went fast: it went on ahead)
			return
		Stage.turn_to(who, canyon)
		await S.wait(0.7)
		if is_instance_valid(who):
			_up_the_canyon(who)
	var follows := func() -> void:
		await S.wait(0.6)
		D._chloe_walk(chloe.global_position + (canyon - chloe.global_position).normalized() * 70.0, 90.0, 1.4)
	await S.say([
		D._cue({"text": "Le Carnotaurus se relève. Il regarde Chloé, puis le nord : le sanctuaire des Vents. Et il se met en marche, sans se presser."}, sets_off),
		D._cue({"who": CHLOE, "text": "Tu rentres chez toi ? … Je viens avec toi."}, follows),
	])
	await S.wait(1.2)
	var door := _door_px()
	var made: Array = []   # the Carnotaurus at the door, made while the screen is dark
	var to_the_door := func() -> void:
		if is_instance_valid(who):
			who.queue_free()   # it went on ahead, through the canyon
		var front: Vector2 = w.region.spawn_point(P.SPAWN_SANCTUAIRE)
		w.player.teleport(front)
		w.companion.stand_beside(front)
		w.player.face_towards(door)
		made.append(_scene_carno("CarnoGarde", door + P.CARNO_PORTE * S.CELL, false))
		await S.wait(0.4)
	await S.fade_through(to_the_door, 0.8)
	var guard: DinoNpc = made[0]
	await S.say(_door_roar(guard, door))
	await S.say(_door_opens(guard, door))
	if ItemsDB.ITEMS.has("sceau_desert"):
		Game.give_item("sceau_desert")
	Toast.say(w.get_tree(), "Objet obtenu : le Sceau du Désert")
	await S.say(_guard_home(guard, door))
	_maia_npc()
	Save.save_game()
	S.lock(false)


## At the door, it fills its chest… and roars: a true roar, this time.
static func _door_roar(guard: DinoNpc, door: Vector2) -> Array:
	var fills := func() -> void:
		Stage.look_at(guard.global_position.lerp(door, 0.4))
		D._swell(guard, 2.2, 0.08, true)
	var roars := func() -> void:
		guard.cry(&"attaque")
		_cry("tyran", "attaque", -3.0, 0.72)
		Stage.shake(8.0, 0.9)
		Stage.rear(guard, 1.4)
	return [
		D._cue({"text": "Chloé suit le Carnotaurus à travers le canyon, jusqu'à la grande porte de pierre. Là, il s'arrête. Il gonfle sa poitrine…"}, fills),
		D._cue({"text": "… et il rugit. Pas un cri de peur, cette fois : un rugissement immense, grave et long, qui fait trembler le sable jusqu'au bout du Désert."}, roars),
	]


## The door glows and slides away; the Carnotaurus brings the Sceau from the threshold to Chloé.
static func _door_opens(guard: DinoNpc, door: Vector2) -> Array:
	var chloe := Stage.chloe()
	var opens := func() -> void:
		Stage.look_at(door, 0.8)
		_open_door()   # it glows, then slides away
		Stage.flash(Color(1.0, 0.82, 0.4, 0.45), 1.2)
		D._sparkle(door, 1.6, 30, 0.5)
	var fetches := func() -> void:
		guard.set_meta(&"fetching", true)
		await guard.walk_to(door + Vector2(0.0, 1.2 * S.CELL), 90.0)
		await Stage.bow(guard, 0.8)   # takes it in its teeth
		await guard.walk_to(chloe.global_position + Vector2(58.0, -24.0), 90.0)
		Stage.turn_to(guard, chloe.global_position)
		Stage.look_back()
		await Stage.bow(guard, 1.3)   # and lays it at her feet
		guard.remove_meta(&"fetching")
	return [
		D._cue({"text": "Sur la porte, l'empreinte géante s'allume, dorée comme l'ambre. Puis, dans un grondement de pierre, la porte des Vents glisse, lentement, lentement… et s'ouvre."}, opens),
		{"flag": &"sanctuaire_ouvert"},
		{"text": "Sur le seuil, posé sur une pierre plate, un disque d'ambre gravé d'une spirale de vent… et, dans un coin, d'une toute petite fougère."},
		D._cue({"text": "Le Carnotaurus le prend entre ses dents. Des dents grandes comme des bananes. Et il le pose aux pieds de Chloé, aussi doucement qu'une plume."}, fetches),
		D._cue({"who": CHLOE, "text": "La fougère d'Hélène… Merci."}, func() -> void: Stage.bow(chloe, 0.9)),
		D._cue({"text": "Chloé reçoit le Sceau du Désert !"}, func() -> void: Stage.companion_joy()),
		{"flag": &"sceau_desert"},
	]


## It purrs when she scratches its horns, then lies down by the open door.
static func _guard_home(guard: DinoNpc, door: Vector2) -> Array:
	var chloe := Stage.chloe()
	var purrs := func() -> void:
		while is_instance_valid(guard) and guard.has_meta(&"fetching"):
			await S.wait(0.1)
		Stage.pose(chloe, &"main", 2.6)   # (her hand held out, when drawn)
		D._reach(chloe, guard.global_position, 10.0, 1.4)
		await S.wait(0.5)
		Stage.tremble(guard, 2.4, 1.0)
		Stage.emote(guard, "♥")
	var lies_down := func() -> void:
		while is_instance_valid(guard) and guard.has_meta(&"fetching"):
			await S.wait(0.1)
		if not is_instance_valid(guard):
			return
		await guard.walk_to(door + P.CARNO_GARDE * S.CELL, 90.0)
		Stage.turn_to(guard, chloe.global_position)
		D._crouch(guard, 0.2, 1.2)
	var after: Array = [
		D._cue({"text": "Chloé tend la main, tout doucement, et lui gratte la base des cornes. Le Carnotaurus ferme les yeux… et ronronne. Un ronronnement énorme, comme un moteur de bateau."}, purrs),
	]
	if Game.flag(&"papiers_brac_lus"):
		after.append({"who": CHLOE, "text": "(« Le Carnotaurus Rouge, dans le Désert : LE PROCHAIN. » Eh bien non, Brac. Plus jamais.)"})
	after.append_array([
		D._cue({"text": "Puis il se couche à côté de la porte ouverte, la tête posée sur ses pattes. Le gardien est rentré chez lui."}, lies_down),
		D._cue({"who": CHLOE, "text": "(Le deuxième Cœur est là-dedans.)"}, func() -> void: Stage.turn_to(chloe, door)),
	])
	return after


## The Carnotaurus home again, by the open door (optional DinoNpc « CarnoGardien », there once
## the Sceau du Désert is Chloé's, event « carno_gardien »): a line at each visit.
static func gardien(who: Node) -> void:
	if Game.phase() == &"night":
		await S.say([{"text": "Le Carnotaurus dort devant la porte, la tête posée sur ses pattes. Même endormi, il garde le passage."}])
		return
	var which := int(Game.flag(&"gardien_n")) % GARDIEN_AGAIN.size()
	var line := {"text": ForetCamp.next_line(&"gardien_n", GARDIEN_AGAIN)}
	var chloe := Stage.chloe()
	var purrs := func() -> void:   # scratched at the base of its horns
		D._reach(chloe, (who as Node2D).global_position, 10.0, 1.2)
		Stage.tremble(who, 1.8, 1.0)
	var breathes := func() -> void:   # a warm breath on her bag
		await D._reach(who, chloe.global_position, 12.0, 1.0)
		D._puff(D._head_of(who), 10, 0.5)
	match which:
		1:
			line = D._cue(line, purrs)
		2:
			line = D._cue(line, breathes)
	await S.say([line])


## The door of the Vents (StoryProp « PorteVents ») glows and slides away: gone for good (hide_flag).
static func _open_door() -> void:
	Audio.play_sfx(ROCK, -2.0)
	var door = S.actor("PorteVents")
	if door == null:
		await S.wait(0.8)
		return
	door.remove_from_group(&"interactable")
	# The footprint lights up (an amber light on the door), then the stone slides away, slowly.
	var light := Stage.light_at((door as Node2D).global_position, Color(1.0, 0.8, 0.4), 4.0)
	if light:
		var l := light.create_tween()
		l.tween_property(light, "light_energy", 3.0, 1.2).set_trans(Tween.TRANS_SINE)
		l.tween_property(light, "light_energy", 0.0, 2.8).set_trans(Tween.TRANS_SINE)
		l.tween_callback(light.queue_free)
	# (A prop is cut out in the 3D view: half faded, it is gone. So it slides first, then fades.)
	var t: Tween = door.create_tween()
	t.tween_property(door, "modulate", Color(2.0, 1.6, 0.9), 1.2)
	var sprite := Stage.sprite_of(door)
	if sprite:   # it slides aside, slowly, slowly
		t.tween_callback(func() -> void: Stage.shake(2.0, 2.2))
		t.tween_property(sprite, "position:x", sprite.position.x + 90.0, 2.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(door, "modulate:a", 0.0, 0.8)
	await t.finished
	if is_instance_valid(door):
		door.queue_free()


## The door of the Vents, looked at (StoryProp « PorteVents », before it opens).
static func porte_vents(_who: Node) -> void:
	if Game.flag(&"sanctuaire_ouvert"):
		return
	var lines: Array = [
		{"text": "Une grande porte de pierre, taillée dans la falaise. Des spirales de vent gravées partout, et des trous ronds où le vent chante tout bas, comme dans une bouteille."},
		{"text": "Au milieu, une empreinte de patte immense, à trois doigts. Dessous, une inscription : « Au gardien sans peur, la porte s'ouvre. » Et dans un coin, toute petite, la fougère d'Hélène."},
		{"flag": &"porte_vents_vue"},
	]
	if Game.flag(&"brac_desert_battu"):
		lines.append({"who": CHLOE, "text": "(Le gardien… Il faut d'abord le libérer de sa peur. Il est au fond du canyon des Vents, près du chariot.)"})
	elif Game.flag(&"brac_desert_vu"):
		lines.append({"who": CHLOE, "text": "(Le gardien, c'est le Carnotaurus Rouge. Brac l'a emmené dans le canyon des Vents, à l'ouest.)"})
	else:
		lines.append({"who": CHLOE, "text": "(Le gardien du Désert… Le Carnotaurus Rouge ?)"})
	await S.say(lines)


# ------------------------------------------------------------------ inside the sanctuary

## The first time inside (zone sanctuaire_vents): the wind sings in the rock; the first Cœur, in
## Chloé's bag, feels the second one.
static func arrival() -> void:
	if Game.flag(&"sanctuaire_entre") or Game.flag(&"coeur_2"):
		return
	S.lock(true)
	await S.wait(0.6)
	var chloe := Stage.chloe()
	var altar = S.actor("Autel")
	var hall: Vector2 = (altar as Node2D).global_position if altar is Node2D else S.at(P.AUTEL.x, P.AUTEL.y)
	var lines: Array = [
		{"text": "Derrière la porte, un couloir taillé dans la roche monte en tournant. Le vent s'y engouffre et chante dans des trous ronds creusés dans la pierre : un chant grave, comme quelqu'un qui souffle dans une bouteille géante."},
		D._cue({"text": "Au bout, une grande salle ronde, ouverte sur le ciel. Des totems de pierre sculptés de spirales, et du sable qui tourne tout doucement, sans jamais retomber."},
			func() -> void: Stage.look_at(hall + Vector2(0.0, 1.5 * S.CELL), 1.2)),
	]
	if Game.flag(&"coeur_1"):
		var warms := func() -> void:
			Stage.look_back()
			Stage.glow(chloe, HEART_GLOW, 2, 1.3)
			for i in 2:   # it beats
				D._sparkle(chloe.global_position + Vector2(8.0, 0.0), 0.6, 10, 0.2)
				await S.wait(1.3)
		lines.append_array([
			D._cue({"text": "Dans la sacoche de Chloé, quelque chose se réchauffe. Le premier Cœur, celui du Marais, bat plus fort, et une lueur dorée filtre entre les coutures."}, warms),
			D._cue({"who": CHLOE, "text": "(Il sent l'autre. Le deuxième Cœur est ici.)"}, func() -> void: Stage.turn_to(chloe, hall)),
		])
	lines.append({"flag": &"sanctuaire_entre"})
	await S.say(lines)
	Save.save_game()
	S.lock(false)


## The altar (StoryProp « Autel », event « coeur_vents »): the second Cœur, warm as sand at
## noon. The two Cœurs light up together; far below, something rumbles.
static func coeur(who: Node) -> void:
	if Game.flag(&"coeur_2"):
		await S.say([{"text": "L'autel est vide. Le vent tourne autour, tout doucement, sans rien emporter."}])
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var beats := func() -> void:   # warm in her hands, beating softly
		await Stage.bow(chloe, 0.8)
		Stage.glow(chloe, HEART_GLOW, 2, 0.9)
		for i in 2:
			D._sparkle(chloe.global_position, 0.7, 8, 0.15)
			await S.wait(0.9)
	var together := func() -> void:
		Stage.flash(Color(1.0, 0.85, 0.45, 0.5), 0.9)
		D._sparkle(chloe.global_position, 0.8, 26, 0.35)
		Stage.glow(chloe, HEART_GLOW, 2, 1.0)
		Stage.glow(who, HEART_GLOW, 2, 1.0)
	var shows := func() -> void:
		D._step_aside(who, 52.0)
		Stage.glow(who, HEART_GLOW, 2, 1.6)
		D._sparkle((who as Node2D).global_position, 0.6, 14, 0.2)
	var lines: Array = [
		D._cue({"text": "Au centre de la salle, sur un autel de pierre, le sable tourne en spirale, sans jamais retomber. Au milieu repose un cœur d'ambre, gros comme un poing."}, shows),
		D._cue({"text": "Chloé le prend dans ses mains. Il est chaud, comme le sable à midi. Et il bat, doucement."}, beats),
	]
	if Game.flag(&"coeur_1"):
		lines.append(D._cue({"text": "Chloé sort le premier Cœur de sa sacoche. Les deux Cœurs s'allument en même temps, comme deux lanternes qui se reconnaissent. Pendant un instant, ils battent au même rythme."}, together))
	await S.say(lines)
	w.player.get_node("Camera").call(&"shake", 2.0, 1.2)
	await S.say([
		D._cue({"text": "Loin, très loin sous ses pieds, Chloé croit sentir quelque chose gronder. Puis plus rien. Juste le vent."},
			func() -> void: _later_emote(chloe, "?", 0.8)),
		{"who": CHLOE, "text": "(Deux Cœurs sur cinq. Je les garde, Hélène. Promis.)"},
		D._cue({"text": "Chloé reçoit le deuxième Cœur d'ambre !"}, func() -> void: Stage.companion_joy()),
		{"flag": &"coeur_2"},
	])
	if ItemsDB.ITEMS.has("coeur_2"):
		Game.give_item("coeur_2")
	Toast.say(w.get_tree(), "Objet obtenu : le deuxième Cœur d'ambre")
	Game.award_team_xp(XP_COEUR)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ helpers

## The Carnotaurus of the dead end: the zone's DinoNpc « CarnotaurusRouge » when it is there
## (after a reload), else one made here, where the zone puts it (it can be talked to).
static func _carno_npc() -> DinoNpc:
	var carno = S.actor("CarnotaurusRouge")
	if carno is DinoNpc and not (carno as DinoNpc).is_queued_for_deletion():
		return carno
	var cart = S.actor("ChariotBrac")
	var at: Vector2 = (cart as Node2D).global_position + P.CARNO_CHARIOT * S.CELL if cart is Node2D else S.at(P.CARNO.x, P.CARNO.y)
	return _scene_carno("CarnotaurusRouge", at, true, &"carnotaurus_rouge")


## Brac in the dead end: the zone's Npc « BracDesert » (there from the start after a reload: it
## shows once « brac_desert_vu » is set), else one put there now, when the door scene sets that
## flag in the same visit, so that Chloé finds him where the chase leads.
static func _brac_npc() -> void:
	if Game.flag(&"brac_desert_battu"):
		return
	var boss = S.actor("BracDesert")
	if boss is Npc and not (boss as Npc).is_queued_for_deletion():
		return
	var w = S.world()
	var n: Npc = load("res://actors/npc.tscn").instantiate()
	n.name = "BracDesert"
	n.display_name = BRAC
	n.sheet = load("res://assets/art/characters/brac.png")
	n.event = &"brac_desert"
	n.position = S.at(P.BRAC_DESERT.x, P.BRAC_DESERT.y)
	w.region.entities.add_child(n)


## Maïa at the oasis (Npc « MaiaOasis » shows once the Sceau du Désert is Chloé's): when the
## door scene gives it in the same visit, she is put there now.
static func _maia_npc() -> void:
	if Game.flag(&"maia_defi_4"):
		return
	var maia = S.actor("MaiaOasis")
	if maia is Npc and not (maia as Npc).is_queued_for_deletion():
		return
	var w = S.world()
	var n: Npc = load("res://actors/npc.tscn").instantiate()
	n.name = "MaiaOasis"
	n.display_name = "Maïa"
	n.sheet = load("res://assets/art/characters/maia.png")
	n.event = &"maia_defi_4"
	n.position = S.at(P.MAIA_OASIS.x, P.MAIA_OASIS.y)
	w.region.entities.add_child(n)


## The door of the Vents (pixels): the zone's StoryProp « PorteVents » when it is there.
static func _door_px() -> Vector2:
	var door = S.actor("PorteVents")
	return (door as Node2D).global_position if door is Node2D else S.at(P.PORTE_VENTS.x, P.PORTE_VENTS.y)


## A Carnotaurus only a scene needs (in front of the door, at the dead end), at `at_px`; with
## `event`, Chloé can talk to it.
static func _scene_carno(node_name: String, at_px: Vector2, corrupted: bool, event := &"") -> DinoNpc:
	var w = S.world()
	var d := DinoNpc.new()
	d.name = node_name
	d.species_id = &"carnotaurus"
	d.size_scale = CARNO_SIZE
	d.corrupted = corrupted
	d.event = event
	d.position = at_px
	w.region.entities.add_child(d)
	return d


## Half the party's strength or less is left: better heal before the long calming.
## Behind the cart, out of the wind: a sip from the flask, a moment, and everyone is fit again.
static func _catch_breath() -> void:
	await S.fade_through(func() -> void:
		Game.heal_party()
		Game.party_changed.emit())
	var drinks := func() -> void:
		var dino := D._companion()
		D._fresh(dino)
		Stage.bow(dino, 1.4)
	await S.say([
		D._cue({"text": "À l'abri du chariot, Chloé partage sa gourde. Tout le monde reprend son souffle, le museau dans l'ombre."}, drinks),
		{"text": "Le Carnotaurus, lui, tourne toujours en rond. Il n'a pas bougé d'un pas. Il attend quelqu'un qui n'a pas peur."},
	])


static func _party_worn() -> bool:
	var hp := 0
	var full := 0
	for d: Dino in Game.party:
		hp += d.hp
		full += d.max_hp()
	return full > 0 and hp * 2 <= full


## A sign over someone's head in a moment (after a rumble…).
static func _later_emote(actor: Node2D, text: String, secs: float) -> void:
	await S.wait(secs)
	Stage.emote(actor, text)


## A dino's call, not tied to anyone on screen: `prefix` is the cries' family (tyran…).
static func _cry(prefix: String, kind: String, volume_db: float, pitch := 1.0) -> void:
	var w = S.world()
	var path := CRY % [prefix, kind]
	if w == null or not ResourceLoader.exists(path):
		return
	var p := AudioStreamPlayer.new()
	p.bus = &"SFX"
	p.stream = load(path)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	w.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
