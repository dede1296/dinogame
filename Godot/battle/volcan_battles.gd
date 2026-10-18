class_name VolcanBattles
extends RefCounted
## Les combats du chapitre 8 (la Plaine Volcanique), équilibrés par simulation (moteur réel,
## 300 combats par cas ; docs/mecaniques.md « La lave » ; scratchpad ch8/sim) : ce que les scènes
## (story/volcan*.gd) lancent, sans rien recopier. Les textes viennent de docs/chapitre-8-scenes.md
## (§ 2 ter, 4, 5 b, 8 c) ; la leçon du T-Rex est corrigée sur la table des types (le Feu craint l'Eau
## et la Terre ; ses coups brûlent le Vent et la Nature, la Pierre et l'Eau tiennent bon).
## Équilibrage (équipe : départ L, 3e petit L-1, Nessie L-1, Bouée L-2, Ptéro L-2 ; le meilleur coup,
## jamais de soin) : Brac 43/43/44 puis Fournaise 45 apaisé, équipe 43-44 : Vif 82-86 %, Bastion 94-95 %,
## Écho 91-95 % (à 44/44/45/46 : 43-72 %, trop dur) ; le T-Rex 48, équipe 45 : 89-98 % (3 K.O. en
## moyenne, le combat le plus dur), équipe 44 : 75-95 % ; les corrompus numérotés : 100 % en apaisant
## (4 tours).

const BRAC := "Brac"
## Les règles du duel de Brac en plus de celles de Story.duel : rien (pas de soin entre ses dinos, c'est
## déjà la règle d'un duel ; le fond du volcan vient de la zone). Les scènes y ajoutent « lose_spawn ».
const BRAC_RULES := {}
## Les niveaux (bestiaire : 42 à 48).
const LEVELS := {
	"numero_3": 42, "numero_7": 43, "numero_11": 43, "numero_12": 44,
	"cabosse": 43, "grognon": 43, "mastoc": 44, "fournaise": 45, "trex": 48,
}
## Les habitats (niveaux des sauvages, pour l'agent carte) : jour, jour, nuit.
const WILD := {&"styracosaurus": Vector2i(42, 44), &"saichania": Vector2i(42, 44), &"daspletosaurus": Vector2i(44, 46)}
## Les corrompus des forges, à plaque de fer numérotée : n → [espèce, clé de LEVELS, sa ligne d'entrée].
const NUMEROS := {
	3: [&"styracosaurus", "numero_3", "Le Styracosaurus « 3 » charge ! Ses veines violettes luisent sous la cendre."],
	7: [&"saichania", "numero_7", "Le Saichania « 7 » se retourne vers Chloé, sans cesser de gronder !"],
	11: [&"allosaurus", "numero_11", "L'Allosaurus « 11 » claque des dents dans le vide, puis vers Chloé !"],
	12: [&"majungasaurus", "numero_12", "Le Majungasaurus « 12 » gratte le sol, et regarde enfin Chloé !"],
}
const NUMERO_LESSON := "Un dino corrompu ne tombe pas : il s'apaise. Parle-lui (« Apaiser ») : plus il est fatigué, mieux il écoute."
## Le T-Rex de Magma : ~1,4 fois un Daspletosaurus (sa taille vue, comme les Alphas : DinoNpc.size_scale).
const TREX := &"trex_magma"
const TREX_NAME := "T-Rex de Magma"
const TREX_SIZE := 1.2
const TREX_INTRO := "Le T-Rex de Magma rugit, et toute la salle de verre chante avec lui ! (Combat d'honneur : pas de collier, pas de fuite.)"
const TREX_LESSON := [
	"Le T-Rex de Magma est un dino de Feu : l'Eau et la Terre le touchent fort.",
	"Ses flammes brûlent les dinos de Vent et de Nature ; la Pierre et l'Eau, elles, tiennent bon. Tu peux changer de dino pendant le combat.",
]
const ALPHA_MUSIC := "res://assets/audio/music/alpha.ogg"


## L'équipe de Brac (format Story.duel) : Cabosse, Grognon, Mastoc, puis Fournaise, corrompu (un
## apaisement long). Pas de soin entre eux.
static func brac_team() -> Array:
	return [
		[&"stygimoloch", LEVELS["cabosse"], "Cabosse", {"before": [{"who": BRAC, "text": "Cabosse, cette fois tu te relèves !"}]}],
		[&"majungasaurus", LEVELS["grognon"], "Grognon", {"before": [{"who": BRAC, "text": "Grognon ! Et ne boude pas : c'est la dernière fois que je te le demande."}]}],
		[&"allosaurus", LEVELS["mastoc"], "Mastoc", {"before": [{"who": BRAC, "text": "Mastoc ! Il a encore du sable entre les dents. Depuis le Désert. Il ne veut pas qu'on le brosse."}]}],
		[&"daspletosaurus", LEVELS["fournaise"], "Fournaise", {"corrupted": true, "long_calm": true,
			"before": [{"who": BRAC, "text": "Fournaise. Vas-y doucement, il est tout neuf. … Non, vas-y fort, qu'est-ce que je raconte."}],
			"intro": "Brac envoie Fournaise, et la cendre tremble !",
			"lesson": ["Fournaise ne tombe pas : il s'apaise. Les trois autres, oui."]}],
	]


## Fournaise, apaisé, qui choisit de rejoindre Chloé (un cœur de Lien : il l'a reconnue).
static func fournaise() -> Dino:
	var d := Dino.create(&"daspletosaurus", LEVELS["fournaise"], "Fournaise")
	d.bond = 1
	return d


## Le corrompu numéro `n` (3, 7, 11, 12), prêt pour son combat (corrompu).
static func numero(n: int) -> Dino:
	var def: Array = NUMEROS.get(n, NUMEROS[3])
	var d := Dino.create(def[0], LEVELS[def[1]])
	d.corrupted = true
	return d


## Les règles de son combat : pas de collier (il ne rejoint pas l'équipe : il a une forge à régler), la
## leçon au premier (`first`).
static func numero_rules(n: int, first := false) -> Dictionary:
	var def: Array = NUMEROS.get(n, NUMEROS[3])
	var rules := {"catch": false, "intro": def[2]}
	if first:
		rules["lesson"] = [NUMERO_LESSON]
	return rules


## Le T-Rex de Magma, prêt pour son combat d'honneur.
static func trex() -> Dino:
	return Dino.create(TREX, LEVELS["trex"], TREX_NAME)


## Ses règles : combat d'honneur (pas de collier, pas de fuite), sa taille, la musique des Alphas, la
## leçon (vraie : la table des types). Les scènes y ajoutent « lose_spawn ».
static func trex_rules() -> Dictionary:
	var rules := {"catch": false, "run": false, "size": TREX_SIZE, "intro": TREX_INTRO, "lesson": TREX_LESSON.duplicate()}
	if ResourceLoader.exists(ALPHA_MUSIC):
		rules["music"] = load(ALPHA_MUSIC)
	return rules
