class_name ApexBattles
extends RefCounted
## Les combats du chapitre 9 (la Terre des Apex), équilibrés par simulation (moteur réel ; tests/apex/mecaniques/
## test_equilibrage_apex.gd) : ce que les scènes (story/apex*.gd) lancent, sans rien recopier. Les textes viennent de
## docs/chapitre-9-scenes.md (1 d, 3 f) ; ceux qui se disent pendant le combat sont dans ApexEngine (découpés pour le
## bandeau du combat).
## - Isaure (`Story.duel(ISAURE, isaure_team(), isaure_rules())`, la scène y ajoute « lose_spawn ») : « les miens »,
##   quatre dinos de la mer jamais corrompus, Hauban 47, Bouline 47, Étrave 48, Carène 49 ; pas de musique (le vent,
##   les torches) ; Carène hésite (perd sa première action). Le CHOIX d'avant Carène : la scène lance d'abord
##   `isaure_team().slice(0, 3)`, puis le choix, puis `isaure_team().slice(3)` (les PV de l'équipe de Chloé restent).
## - Le Souverain (`Story.duel("", souverain_team(), souverain_rules())`) : niv. 50, corrompu, jauge triple (300),
##   Sceaux, Caillou, l'Ambre clair à deux tiers, la musique des Alphas, et pas de défaite (« rally » : on reprend sur
##   place, rien à recharger : pas de « lose_spawn »). Story.duel compte « calmed » comme gagné.
## Équilibrage : EQUILIBRAGE (et docs/mecaniques.md).

const ISAURE := "Isaure"
const LEVELS := {"hauban": 47, "bouline": 47, "etrave": 48, "carene": 49, "souverain": 50}
## Le dino d'Isaure qui hésite (règle « hesitates » d'ApexEngine).
const HESITANT := "Carène"
const SOUVERAIN := &"souverain"
## Le Souverain vu en combat : ×1,5 (« trop grand pour l'écran » ; la taille de l'espèce, son gabarit d'adulte).
const SOUVERAIN_SIZE := 1.5
const SOUVERAIN_INTRO := "Le Souverain. Il est trop grand pour l'écran, et il tremble de tout son corps. Ses veines sont violettes jusqu'aux yeux. Il ne sait pas où il est."
const SOUVERAIN_LESSON := [
	"Les Sceaux. Cinq Alphas ont promis quelque chose à Hélène : ceux qui gardaient un Cœur. Appelle-les, un par un. Et parle-lui : il n'a jamais eu que ça, les mots d'Hélène.",
	"(Les Sceaux sont à la place de Fuir. L'Ambre clair, dans le Sac, quand il écoute.)",
]
const ALPHA_MUSIC := "res://assets/audio/music/alpha.ogg"
## L'équilibrage simulé (tests/apex/mecaniques/test_equilibrage_apex.gd, 120 combats par cas, graine 48).
const EQUILIBRAGE := "Isaure contre une équipe de 47 : Vif 95 %, Bastion 100 %, Écho 86 % (moyenne 94 % ; de 46 : 88 %). Le Souverain contre une équipe de 48 : sans Sceaux 17-24 tours, avec les cinq 9,5 (en lui parlant) à 15 (en l'usant d'abord) ; 0 à 0,8 K.O., jamais perdu."


## L'équipe d'Isaure (format Story.duel) : Hauban, Bouline, Étrave, Carène. Pas un dino corrompu ; une réplique
## « before » d'Isaure chacun (sauf Carène : la scène pose son CHOIX), l'« intro » de chacun.
static func isaure_team() -> Array:
	return [
		[&"pteranodon", LEVELS["hauban"], "Hauban", {
			"before": [{"who": ISAURE, "text": "Hauban. Il a pêché pour le port les hivers où personne ne pêchait."}],
			"intro": "Isaure envoie Hauban ! Il a du sel sur le bec."}],
		[&"baryonyx", LEVELS["bouline"], "Bouline", {
			"before": [{"who": ISAURE, "text": "Bouline. Elle fait couler tout ce qui flotte, et le regarde remonter. Elle ne s'en lasse pas."}],
			"intro": "Isaure envoie Bouline ! Elle regarde la sacoche de Chloé : ça flotte ?"}],
		[&"suchomimus", LEVELS["etrave"], "Étrave", {
			"before": [{"who": ISAURE, "text": "Étrave. Il n'a jamais perdu une course. Il n'a jamais compris non plus pourquoi on courait."}],
			"intro": "Isaure envoie Étrave ! Il est déjà en train de courir."}],
		[&"archelon", LEVELS["carene"], HESITANT, {"intro": "Isaure envoie Carène. Elle prend son temps."}],
	]


## Ses règles (en plus de celles de Story.duel : pas de collier, pas de fuite) : pas de musique, Carène hésite.
static func isaure_rules() -> Dictionary:
	return {"music": null, "hesitates": HESITANT}


## Le Souverain, prêt pour son combat (corrompu).
static func souverain() -> Dino:
	var d := Dino.create(SOUVERAIN, LEVELS["souverain"])
	d.corrupted = true
	return d


## Le Souverain au format Story.duel (le nom vide : c'est « le Souverain », ApexEngine.name_of).
static func souverain_team() -> Array:
	return [[SOUVERAIN, LEVELS["souverain"], "", {"corrupted": true, "long_calm": true, "size": SOUVERAIN_SIZE,
		"intro": SOUVERAIN_INTRO, "lesson": SOUVERAIN_LESSON.duplicate()}]]


## Ses règles (ApexEngine) : jauge triple, Sceaux, Caillou, l'Ambre clair à deux tiers, pas de défaite ; le Cœur des
## Apex (battle/battle_apex.gd : son fond) ; la musique des Alphas.
static func souverain_rules() -> Dictionary:
	var rules := {"catch": false, "run": false, "long_calm": true, "calm_factor": 3, "sceaux": true, "caillou": true,
		"antidote": true, "antidote_min_calm": 0.66, "rally": true, "apex": true, "size": SOUVERAIN_SIZE,
		"intro": SOUVERAIN_INTRO, "lesson": SOUVERAIN_LESSON.duplicate()}
	if ResourceLoader.exists(ALPHA_MUSIC):
		rules["music"] = load(ALPHA_MUSIC)
	return rules
