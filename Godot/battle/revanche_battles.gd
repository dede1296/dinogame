class_name RevancheBattles
extends RefCounted
## Les revanches du post-game (docs/post-game-plan.md § 3) : les sept Alphas « pour voir », chez eux, et le pari
## d'Isaure ; ce que story/revanches.gd lance, sans rien recopier (le défi n° 6 de Maïa : ApexBattles.maia_team).
## - Un Alpha : un seul dino, niveau 50 à 53, ni capture ni fuite, pas corrompu, la musique des Alphas, « lose_spawn »
##   l'entrée du lieu ; il est chez lui (« home ») : son attaque, sa défense, sa vitesse partent plus haut (des crans,
##   comme un Grondement : règle « foe_stages » de BattleEngine ; la leçon du combat le dit). Seul contre l'équipe de
##   fin (cinq dinos de 48 à 50), un Alpha de 50 à 53 tombe 96 à 100 fois sur 100 : ces crans le ramènent à 70-85 % ;
##   Piment et Toupet les font baisser ; sous l'eau pour Minuit (le récif est la seule zone sous la mer : le temple du Spinosaure ne
##   l'est pas, son combat du chapitre 3 non plus) ; la neige, le volcan : ceux de la zone. Quand il tombe, le combat
##   dit ALPHA_STOPS (« Il s'arrête. Il a vu. »), jamais « K.O. » (règle « foe_faint »). Son Sceau ne vient pas contre
##   lui (règle « alpha », ApexEngine.Libres). Le Roi des Cieux ne combat pas ; le Souverain, jamais : absents.
## - Isaure : Hauban, Bouline, Étrave, Carène, plus haut qu'au chapitre 9, et Carène n'hésite plus ; pas de musique
##   (le vent, la mer) ; « lose_spawn » le quai.
## Équilibrage : EQUILIBRAGE (tests/apex/revanches/test_equilibrage_revanches.gd).

const ALPHA_MUSIC := "res://assets/audio/music/alpha.ogg"
## Les Alphas, par région (l'ordre de l'île) : l'espèce, son titre (son nom en combat : « le Tricératops Alpha »), le
## niveau, sa taille (celle de son chapitre), son Sceau, les pièces de chaque victoire, où l'on revient après une
## défaite (rien : l'entrée de la zone), sous l'eau ; « spot » : où il se tient quand il faut le faire venir (cases) ;
## « home » : ses crans chez lui (simulés : EQUILIBRAGE).
const ALPHAS := {
	&"plaines": {"species": &"triceratops", "title": "Tricératops Alpha", "level": 50, "size": 1.2, "sceau": "sceau_plaines",
		"coins": 60, "lose_spawn": &"Crane", "spot": Vector2(107.2, 63.8), "home": {"atk": 2}},
	&"foret": {"species": &"utahraptor", "title": "Chef de Meute", "level": 51, "size": 1.2, "sceau": "sceau_foret", "coins": 60,
		"home": {"atk": 3, "def": 2, "spd": 1}},
	&"marais": {"species": &"spinosaurus", "title": "Spinosaure Ancestral", "level": 51, "size": 1.25, "sceau": "sceau_marais",
		"coins": 70, "lose_spawn": &"DepuisMarais", "home": {"atk": 1, "spd": 1}, "spot": Vector2(19.5, 5.9)},
	&"desert": {"species": &"carnotaurus", "title": "Carnotaurus Rouge", "level": 51, "size": 1.2, "sceau": "sceau_desert",
		"coins": 70, "lose_spawn": &"DepuisSanctuaire", "home": {"atk": 3, "def": 1}},
	&"cote": {"species": &"mosasaure_abyssal", "title": "Mosasaure Abyssal", "level": 52, "size": 1.2, "sceau": "sceau_cote",
		"coins": 80, "lose_spawn": &"DepuisCote", "underwater": true, "abyss": true, "home": {"atk": 1}},
	&"monts": {"species": &"cryolophosaure_titan", "title": "Cryolophosaure Titan", "level": 52, "size": 1.1, "sceau": "sceau_monts",
		"coins": 80, "lose_spawn": &"DepuisMonts", "home": {"atk": 1, "def": 1}},
	&"volcan": {"species": &"trex_magma", "title": "T-Rex de Magma", "level": 53, "size": 1.2, "sceau": "sceau_volcan",
		"coins": 90, "lose_spawn": &"DepuisCoulees", "home": {"spd": 1}},
}
const ISAURE := "Isaure"
const ISAURE_LEVELS := {"hauban": 50, "bouline": 50, "etrave": 51, "carene": 52}
## Chaque pari gagné après le premier : « une pièce sur deux pour la barque, l'autre moitié ».
const ISAURE_COINS := 100
## Où l'on revient après un pari perdu : le quai (l'embarcadère de Port-Ambre).
const ISAURE_LOSE_SPAWN := &"Embarcadere"
## L'équilibrage simulé (tests/apex/revanches/test_equilibrage_revanches.gd ; 120 combats par cas, graine 50).
const EQUILIBRAGE := "Sans les crans « chez lui », chaque Alpha de 50 à 53 contre une équipe de 50 : 96 à 100 %. Avec (moyenne Vif/Bastion/Écho, équipe de 50 ; de 48) : Tricératops 82 % en 11,9 tours (68 %), Chef de Meute 82 % en 7,7 (73 %), Spinosaure 82 % en 15,2 (63 %), Piment 81 % en 8,4 (71 %), Minuit 87 % en 8,8 (78 %), Toupet 73 % en 9,7 (64 %), Cheminée 77 % en 9,2 (62 %) ; 2 à 4 K.O. Avec les six autres Sceaux bien appelés : 95 à 100 %. Isaure (50/50/51/52) : 92 % (de 48 : 75 %) ; Maïa (50/50/50/51) : 94 % (de 48 : 83 %)."


## L'Alpha de la région `id` (null s'il n'y en a pas).
static func alpha(id: StringName) -> Dino:
	if not ALPHAS.has(id):
		return null
	var a: Dictionary = ALPHAS[id]
	return Dino.create(a["species"], a["level"], a["title"])


## Les règles de sa revanche (BattleScene.run, par le monde : `_battle`).
static func alpha_rules(id: StringName) -> Dictionary:
	if not ALPHAS.has(id):
		return {}
	var a: Dictionary = ALPHAS[id]
	var rules := {"catch": false, "run": false, "size": a["size"], "alpha": a["sceau"],
		"intro": DialogueRevanches.ALPHA_INTRO % BattleEngine._cap(French.le(a["title"])),
		"foe_faint": DialogueRevanches.ALPHA_STOPS, "foe_stages": (a.get("home", {}) as Dictionary).duplicate(),
		"lesson": [DialogueRevanches.home_lesson(a.get("home", {}))]}
	for key: String in ["lose_spawn", "underwater", "abyss"]:
		if a.has(key):
			rules[key] = a[key]
	if ResourceLoader.exists(ALPHA_MUSIC):
		rules["music"] = load(ALPHA_MUSIC)
	return rules


## Les Alphas, dans l'ordre de l'île.
static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(ALPHAS.keys())
	return out


## L'équipe d'Isaure pour le pari (format Story.duel) : jamais corrompus, Carène sans hésiter.
static func isaure_team() -> Array:
	return [
		[&"pteranodon", ISAURE_LEVELS["hauban"], "Hauban", {"intro": "Isaure envoie Hauban ! Il a du sel sur le bec."}],
		[&"baryonyx", ISAURE_LEVELS["bouline"], "Bouline", {"intro": "Isaure envoie Bouline ! Elle regarde la sacoche de Chloé : ça flotte ?"}],
		[&"suchomimus", ISAURE_LEVELS["etrave"], "Étrave", {"intro": "Isaure envoie Étrave ! Il est déjà en train de courir."}],
		[&"archelon", ISAURE_LEVELS["carene"], "Carène", {"intro": "Isaure envoie Carène. Elle n'hésite plus."}],
	]


## Les règles du pari (en plus de celles de Story.duel : pas de collier, pas de fuite) : pas de musique, le quai.
static func isaure_rules() -> Dictionary:
	return {"music": null, "lose_spawn": ISAURE_LOSE_SPAWN}
