class_name ApexGiants
extends RefCounted
## Les quatre géants du cratère, au post-game (docs/histoire.md § Post-game ; chapitre-9-scenes.md 2 c ; page 40 :
## « on ne réveille rien de force… on s'assoit à côté, et on attend qu'il n'ait plus peur »). La mécanique seule
## (les scènes de réveil, les images, les espèces des géants viendront avec la suite) : dès le drapeau `post_game`,
## Chloé s'assoit à côté d'un bloc (StoryProp BlocGeant1..4) une fois par jour du jeu (Game.day) ; au bout de
## SITS_TO_WAKE jours, le géant ouvre l'œil. Un seul à la fois, dans l'ordre : les suivants dorment « pour de bon.
## Pour l'instant. » tant que le précédent n'est pas réveillé.
## Drapeaux : geant_<n>_assis (les jours passés à côté), geant_<n>_jour (le dernier), geant_<n>_eveille.
## Le Lien monte (BOND_SIT points pour le dino de tête, assis à côté avec elle).

const COUNT := 4
const SITS_TO_WAKE := 3
const BOND_SIT := 60
## L'état d'un bloc (state).
const ASLEEP := &"dort"            # pas encore son tour (ou pas encore le post-game)
const WAITING := &"attend"         # son tour : Chloé peut s'asseoir
const SAT_TODAY := &"assis"        # elle s'est assise là aujourd'hui : demain
const AWAKE := &"eveille"
## Ce que dit le bloc (les scènes peuvent dire autre chose) ; %d : les jours qu'il reste.
const LINES := {
	&"dort": "Celui-là dort pour de bon. Pour l'instant.",
	&"attend": "Chloé s'assoit contre l'ambre, et attend. Dedans, quelque chose respire un peu plus lentement.",
	&"assis": "Chloé s'est déjà assise ici aujourd'hui. Demain : on ne réveille rien de force.",
	&"eveille": "Il a les yeux ouverts. Il regarde le cratère, et il n'a pas peur.",
	&"reveil": "Un œil s'ouvre dans l'ambre. Il regarde Chloé, longtemps. Il n'a pas peur.",
}


static func _flag(n: int, what: String) -> StringName:
	return StringName("geant_%d_%s" % [n, what])


static func awake(n: int) -> bool:
	return Game.flag(_flag(n, "eveille")) == true


static func awake_count() -> int:
	var k := 0
	for n in range(1, COUNT + 1):
		if awake(n):
			k += 1
	return k


## Le géant dont c'est le tour (1 à COUNT) ; 0 avant le post-game ou quand tous sont réveillés.
static func current() -> int:
	if not Game.flag(&"post_game"):
		return 0
	for n in range(1, COUNT + 1):
		if not awake(n):
			return n
	return 0


## Les jours que Chloé a passés à côté du bloc `n`.
static func sits(n: int) -> int:
	return int(Game.flag(_flag(n, "assis")))


static func state(n: int) -> StringName:
	if awake(n):
		return AWAKE
	if current() != n:
		return ASLEEP
	return SAT_TODAY if int(Game.flag(_flag(n, "jour"))) == Game.day and sits(n) > 0 else WAITING


## Chloé s'assoit à côté du bloc `n` (s'il attend) : un jour de plus ; le dernier, il se réveille.
## Retourne {"ok": assise ou non, "sits": jours, "woke": réveillé à l'instant, "text": la ligne}.
static func sit(n: int) -> Dictionary:
	var now := state(n)
	if now != WAITING:
		return {"ok": false, "sits": sits(n), "woke": false, "text": LINES[now]}
	var days := sits(n) + 1
	Game.set_flag(_flag(n, "assis"), days)
	Game.set_flag(_flag(n, "jour"), Game.day)
	Game.grow_bond(Game.lead_dino(), BOND_SIT)
	if days < SITS_TO_WAKE:
		return {"ok": true, "sits": days, "woke": false, "text": LINES[WAITING]}
	Game.set_flag(_flag(n, "eveille"))
	return {"ok": true, "sits": days, "woke": true, "text": LINES[&"reveil"]}
