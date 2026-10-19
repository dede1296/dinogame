class_name ApexEngine
extends BattleEngine
## Les deux derniers combats (chapitre 9 : docs/chapitre-9-plan.md « Le combat contre Isaure » et « La mécanique
## finale », chapitre-9-scenes.md 1 d et 3 f) : les règles de BattleEngine, plus celles-ci, chacune posée par une
## règle de combat (BattleScene passe toutes celles de RULES ; ApexBattles les donne) :
##   "hesitates": "Carène"   le dino d'Isaure qui porte ce nom hésite : il perd sa première action (« elle prend son
##                           temps »). Les trois phrases du choix d'avant y mènent toutes : aucune n'est la mauvaise.
##   "calm_factor": 3        la jauge de calme fait CALM_FULL × 3 (300), à la place de LONG_CALM_FACTOR.
##   "sceaux": true          la commande « Sceaux », à la place de Fuir ({"type": "sceau", "id": "sceau_marais"}) :
##                           chaque Sceau que Chloé a (SCEAUX : les cinq gardiens de Cœurs, décision de Greg du 19/10)
##                           appelle son Alpha UNE fois ; il paraît, agit, et s'efface, sans coûter son tour à Chloé
##                           (le Souverain ne frappe pas pendant ce temps : appeler un Alpha n'est jamais puni).
##   "caillou": true         une fois, le coup du Souverain qui mettrait le dino de Chloé au sol, Caillou le prend.
##   "antidote_min_calm": k  l'Ambre clair (règle « antidote ») n'agit qu'à k × la jauge (deux tiers) ; avant, Chloé
##                           range la fiole (le tour est gardé). Alors le dernier geste du dino de départ (GESTURES :
##                           Vif, Bastion, Écho ; il entre, il se relève s'il le faut), puis la goutte. Tant que la dose
##                           est dans le sac, les mots seuls ne remplissent pas la jauge : il faut la goutte.
##   "rally": true           pas de défaite : l'équipe au sol se relève sur place (« Encore. »), soignée ; les Sceaux et
##                           Caillou reviennent ; le calme reste. Rien n'est perdu, rien n'est rechargé.
## Le Souverain (espèce SOUVERAIN, ApexBattles) : il a peur. Il frappe en reculant (le « say » de ses attaques), et
## « Il ne bouge pas » de plus en plus souvent à mesure qu'il se calme (STILL_*) ; entre deux mots, sa peur revient un
## peu (FEAR_RETURNS à la fin d'un tour où Chloé ne lui a pas parlé : jamais sous le givre de Toupet, jamais sous le
## seuil de l'Ambre clair une fois atteint) ;
## les mots mettent du temps à arriver jusqu'à lui (LISTENS) ; son Tremblement secoue toute l'équipe (TREMOR_BENCH des
## PV des autres, jamais sous 1 PV). Il ne tombe jamais sous 1 PV (corrompu), ne se capture pas, ne se fuit pas.
## Événements en plus (BattleApex les joue) : "sceau" (l'Alpha paraît : id, alpha), "sceau_end" (il s'efface),
## "caillou", "gesture" (variant), "quake", "fear" (son calme retombe : calm), "rally".

const RULES := ["hesitates", "calm_factor", "sceaux", "caillou", "antidote_min_calm", "rally"]
const SOUVERAIN := &"souverain"
const STILL_MOVE := &"immobile"
const TREMOR_MOVE := &"tremblement"
## « Il ne bouge pas » : sa part des actions du Souverain, plus sa part en plus jauge pleine.
const STILL_BASE := 0.2
const STILL_CALM := 0.45
## Sa peur revient entre deux mots : le calme perdu à la fin d'un tour où Chloé ne lui a pas parlé (un coup, un
## soin, un changement de dino ; jamais sous le givre, jamais sous le seuil de l'Ambre clair une fois atteint).
const FEAR_RETURNS := 7
## Les mots arrivent jusqu'à lui à cette part de ce qu'ils apportent d'habitude (il est si grand…).
const LISTENS := 0.26
## Le Tremblement : la part des PV que perdent les dinos qui attendent à côté de Chloé.
const TREMOR_BENCH := 0.06
## Le dino de départ au sol, pour le dernier geste : il se relève avec cette part de ses PV.
const RISE_SHARE := 0.34
## Les Sceaux (l'ordre de la liste) : l'objet, l'Alpha (son image), son nom sur la carte, ce qu'il fait, sa bulle.
## effect "heal" : toute l'équipe remise d'aplomb (même ceux au sol : chacun boit) ; "calm" : +amount de calme ;
## "soften" : son prochain coup deux fois plus doux ; "freeze" : le calme ne baisse plus pendant `turns` tours ;
## "still" : à sa prochaine action, le Souverain ne bouge pas (il regarde Cheminée, et s'arrête).
const SCEAUX := [
	{"id": "sceau_marais", "alpha": &"spinosaurus", "name": "Spinosaure", "what": "Soigne toute l'équipe", "effect": "heal",
		"text": "Le Spinosaure Ancestral entre. Il n'y a pas d'eau ici : il en apporte dans sa gueule, sans en perdre une goutte, et chacun boit.",
		"after": "Toute l'équipe a bu : chacun est remis d'aplomb !"},
	{"id": "sceau_desert", "alpha": &"carnotaurus", "name": "Piment", "what": "+40 de calme", "effect": "calm", "amount": 40,
		"text": "Piment rugit. Pas contre lui : à côté de lui. Un rugissement sans peur. Le Souverain tremble moins.",
		"after": "Son calme monte (+40) !"},
	{"id": "sceau_cote", "alpha": &"mosasaure_abyssal", "name": "Minuit", "what": "Coup suivant adouci", "effect": "soften",
		"text": "Très loin, sous l'île, Minuit chante. Le chant monte par les veines d'ambre. Le Souverain baisse la queue.",
		"after": "Son prochain coup sera deux fois plus doux."},
	{"id": "sceau_monts", "alpha": &"cryolophosaure_titan", "name": "Toupet", "what": "Calme gelé 3 tours", "effect": "freeze", "turns": 3,
		"text": "Toupet souffle, et la cendre devient givre. La colère gèle. Pas lui.",
		"after": "Pendant trois tours, son calme ne retombera pas."},
	{"id": "sceau_volcan", "alpha": &"trex_magma", "name": "Cheminée", "what": "+60, il s'arrête", "effect": "calm", "amount": 60, "still": true,
		"text": "Cheminée entre, et se couche à côté de lui, et fume. Le sol tremble. Le Souverain le regarde, et s'arrête.",
		"after": "Son calme monte (+60) ! Il ne bouge plus, un instant."},
]
const CAILLOU := ["Caillou se met devant ! Le coup glisse sur sa collerette.", "Maïa : « Caillou ! … Bien. C'est bien. Reste là. »"]
## Ce que dit un coup qui porte (BattleEngine._use_move) : Caillou l'ayant pris, ces lignes partent avec ses dégâts.
const HIT_LINES := ["Coup critique !", "C'est super efficace !", "Ce n'est pas très efficace…"]
## (Avant le combat, la scène l'a dit : « Carène regarde Isaure, puis Chloé. Et elle prend son temps. »)
const HESITATES := "%s hésite. Elle regarde encore Isaure… et ne fait rien, ce tour-ci."
const NOT_YET := "Chloé sort la fiole d'ambre clair… et la range. Il est trop grand pour une goutte. Il faut d'abord qu'il l'écoute."
const LISTENING := "Il écoute. Ses veines pâlissent, il tremble moins… C'est le moment : l'Ambre clair, dans le Sac."
const FEAR_TOLD := "Il a encore peur : entre deux mots, son calme retombe un peu."
const THAWS := "Le givre de Toupet fond. Sa peur peut revenir."
const RALLY := [
	"Le Souverain recule contre la paroi, et tremble, et attend. Caillou tient toujours.",
	"Les veines d'ambre du sol luisent, chaudes, et l'équipe de Chloé se relève.",
	"Maïa : « Encore. Il ne part pas, et nous non plus. »",
]
const RISES := "%s se relève. Pour Chloé."
const STEPS_IN := "%s s'avance. C'est à lui."
## Le dernier geste, par espèce du dino de départ (%s : son nom) ; la dernière ligne va avec la goutte.
const GESTURES := {
	&"velociraptor": ["vif", [
		"%s bondit. De rocher en rocher, de l'épaule au cou, jusqu'au front du Souverain.",
		"Et là, il fait ce que Griffe-Grise a appris à Chloé : il le gratte sous le menton. Le Souverain s'arrête. Tout s'arrête.",
		"Chloé grimpe derrière, et verse une goutte. Une seule.",
	]],
	&"ankylosaurus": ["bastion", [
		"Le coup de queue arrive. %s se plante devant Chloé et ne recule pas d'un pas : la queue s'arrête contre lui, comme contre un mur de canyon.",
		"Il souffle un petit nuage de cendre, pour dire bonjour.",
		"Chloé passe sous la queue, et verse une goutte. Une seule.",
	]],
	&"parasaurolophus": ["echo", [
		"%s chante. La petite note tremblante de la Voix, celle d'une berceuse.",
		"L'ambre du sol répond. Puis le bloc. Puis les veines du Souverain, une à une. Il baisse la tête jusqu'à Chloé.",
		"Et elle verse une goutte. Une seule.",
	]],
}
const GESTURE_ANY := ["", ["%s se met devant Chloé, et ne recule pas.", "Chloé verse une goutte. Une seule."]]
const DROP := ["L'ambre clair coule le long des veines violettes… et les éteint, une à une.",
	"Les veines violettes s'effacent. Le Souverain est apaisé !"]

var hesitant := ""
var sceaux := false
var caillou := false
var rally := false
## L'Ambre clair n'agit qu'à cette part de la jauge (0 : tout de suite, comme au chapitre 8).
var antidote_min := 0.0
## Combien de fois l'équipe s'est relevée.
var rallies := 0
var _hesitated := false
var _called: Array[String] = []
var _soften_next := false
var _still_next := false
var _frozen := 0
var _caillou_used := false
var _caillou_now := false
var _foe_striking := false
var _listening := false
var _told_fear := false
## L'équipe s'est relevée ce tour-ci (pas de peur qui revient juste après « Encore. »).
var _rallied_now := false


func _init(player_team: Array[Dino], wild: Dino, rules := {}) -> void:
	super(player_team, wild, rules)
	hesitant = String(rules.get("hesitates", ""))
	sceaux = rules.get("sceaux", false)
	caillou = rules.get("caillou", false)
	rally = rules.get("rally", false)
	antidote_min = float(rules.get("antidote_min_calm", 0.0))
	if rules.has("calm_factor"):
		calm_full = roundi(CALM_FULL * float(rules["calm_factor"]))


## Un combat livré avec ces règles est-il l'un des siens ?
static func applies(rules: Dictionary) -> bool:
	return RULES.any(func(k: String) -> bool: return rules.has(k))


func is_souverain() -> bool:
	return foe.species().id == SOUVERAIN


func name_of(side: String) -> String:
	if side == "foe" and is_souverain():
		return "le Souverain"
	return super(side)


func _calm_name() -> String:
	return "le Souverain" if is_souverain() else super()


func _calmed_name() -> String:
	return "Le Souverain" if is_souverain() else super()


# ------------------------------------------------------------------ un tour

func turn(action: Dictionary) -> Array:
	_rallied_now = false
	if over or must_switch:
		return super(action)
	match action["type"]:
		"catch", "run":
			if is_souverain():
				return []   # (ni capturé, ni fui : rien ne se passe, le tour est gardé)
		"sceau":
			return _call_sceau(String(action.get("id", "")))
		"antidote":
			if antidote_waits() and not antidote_ready():
				return [{"type": "text", "text": NOT_YET}]   # (le tour est gardé)
	return super(action)


# ------------------------------------------------------------------ les Sceaux

## Chloé a-t-elle ce Sceau ? (l'objet, ou le drapeau du même nom)
static func owns(id: String) -> bool:
	return Game.item_count(id) > 0 or Game.flag(StringName(id)) == true


static func sceau(id: String) -> Dictionary:
	for s: Dictionary in SCEAUX:
		if s["id"] == id:
			return s
	return {}


## Les Sceaux de Chloé, dans l'ordre de la liste.
func owned_sceaux() -> Array:
	return SCEAUX.filter(func(s: Dictionary) -> bool: return owns(s["id"]))


## Ce Sceau peut-il appeler son Alpha maintenant ? (une fois par combat)
func can_call(id: String) -> bool:
	return sceaux and not over and not must_switch and owns(id) and not _called.has(id) and not sceau(id).is_empty()


func can_call_any() -> bool:
	return owned_sceaux().any(func(s: Dictionary) -> bool: return can_call(s["id"]))


func _call_sceau(id: String) -> Array:
	var ev: Array = []
	if not can_call(id):
		return ev
	_calming = false
	_called.append(id)
	var s := sceau(id)
	ev.append({"type": "sceau", "id": id, "alpha": s["alpha"], "text": s["text"]})
	match s["effect"]:
		"heal":
			for d in team:
				d.hp = d.max_hp()
				d.status = ""
			ev.append({"type": "heal", "side": "player", "amount": 0, "hp": player().hp, "max_hp": player().max_hp(), "text": s["after"]})
		"calm":
			_raise_calm(int(s["amount"]), s["after"], ev)
		"soften":
			_soften_next = true
			ev.append({"type": "text", "text": s["after"]})
		"freeze":
			_frozen = int(s.get("turns", 3))
			ev.append({"type": "text", "text": s["after"]})
	if s.get("still", false):
		_still_next = true
	ev.append({"type": "sceau_end", "id": id, "alpha": s["alpha"]})
	return ev   # (le tour de Chloé est gardé : pendant que l'Alpha est là, le Souverain ne frappe pas)


func _raise_calm(amount: int, text: String, ev: Array) -> void:
	calm = mini(_calm_cap(), calm + amount)
	ev.append({"type": "calm", "calm": calm, "text": text})
	_tell_listening(ev)


# ------------------------------------------------------------------ le calme du Souverain

## Ce que la jauge peut atteindre : pleine, sauf tant que la dose d'Ambre clair attend (il faut la goutte).
func _calm_cap() -> int:
	return calm_full - 1 if antidote_waits() else calm_full


func calm_step() -> int:
	var step := super()
	if is_souverain():
		step = roundi(step * LISTENS)
	return mini(step, maxi(0, _calm_cap() - calm))


func _try_calm(ev: Array) -> bool:
	var done := super(ev)
	if not done:
		_tell_listening(ev)
	return done


## La première fois que le calme atteint le seuil de l'Ambre clair : on le dit (une fois).
func _tell_listening(ev: Array) -> void:
	if _listening or antidote_min <= 0.0 or not antidote_waits() or calm < threshold():
		return
	_listening = true
	ev.append({"type": "text", "text": LISTENING})


## Le seuil de l'Ambre clair (calme).
func threshold() -> int:
	return ceili(calm_full * antidote_min)


## L'Ambre clair agirait-il maintenant ?
func antidote_ready() -> bool:
	return antidote_min <= 0.0 or calm >= threshold()


## La dose attend dans le sac, au dernier combat, devant un corrompu (prête ou non).
func antidote_waits() -> bool:
	return antidote_allowed and not over and foe.corrupted and Game.item_count(ANTIDOTE) > 0


func can_use_antidote() -> bool:
	return super() and antidote_ready()


## Touché, il s'affole un peu (BattleEngine) ; mais pas sous le givre de Toupet (la colère gèle), et jamais sous
## le seuil de l'Ambre clair une fois atteint.
func _frighten(ev: Array) -> void:
	var floor_at := threshold() if _listening else 0
	if _frozen <= 0 and calm > floor_at:
		calm = maxi(floor_at, calm - CALM_LOST_ON_HIT)
		ev.append({"type": "calm", "calm": calm, "text": "Le coup l'affole : il se méfie davantage…"})
	if foe.hp == 1 and not _told_fury:
		_told_fury = true
		ev.append({"type": "text", "text": "La fureur le tient debout ! Seul l'apaisement peut l'arrêter."})


func _end_of_turn(ev: Array) -> void:
	super(ev)
	if over or not is_souverain() or _rallied_now:   # (l'équipe vient de se relever : le calme reste)
		return
	if _frozen > 0:
		_frozen -= 1
		if _frozen == 0:
			ev.append({"type": "text", "text": THAWS})
		return
	var floor_at := threshold() if _listening else 0
	if _calming or calm <= floor_at:   # (Chloé lui a parlé ce tour-ci : pas de peur qui revient)
		return
	calm = maxi(floor_at, calm - FEAR_RETURNS)
	var e := {"type": "fear", "calm": calm}
	if not _told_fear:
		_told_fear = true
		e["text"] = FEAR_TOLD
	ev.append(e)


# ------------------------------------------------------------------ ses coups

func _choose_foe_move() -> int:
	if not is_souverain():
		return super()
	var forced := _still_next   # (Cheminée couché à côté de lui : il le regarde, et s'arrête)
	_still_next = false
	var still := -1
	var others: Array = []
	for i in foe.moves.size():
		if foe.moves[i]["pp"] <= 0:
			continue
		if foe.moves[i]["id"] == STILL_MOVE:
			still = i
		else:
			others.append(i)
	var chance := STILL_BASE + STILL_CALM * calm / float(calm_full)
	if still >= 0 and (forced or others.is_empty() or rng.randf() < chance):
		return still
	return others[rng.randi() % others.size()] if not others.is_empty() else super()


func _use_move(side: String, index: int, ev: Array) -> void:
	if side == "foe" and hesitant != "" and not _hesitated and foe.nickname == hesitant and foe.status != "etourdi":
		_hesitated = true
		ev.append({"type": "text", "text": HESITATES % _cap(name_of("foe"))})
		return
	var before := ev.size()
	_foe_striking = side == "foe"
	_caillou_now = false
	super(side, index, ev)
	_foe_striking = false
	if side != "foe" or before >= ev.size() or ev[before]["type"] != "move":
		return
	var move := _move_of(foe, index)
	if move.has("say"):
		ev[before]["text"] = String(move["say"]) % _cap(name_of("foe"))
	if _caillou_now:
		_caillou_steps_in(ev, before)
	var missed := ev.slice(before).any(func(x: Dictionary) -> bool: return x["type"] == "miss")
	if ev[before]["move"] == TREMOR_MOVE and not missed:
		_quake(ev)


func _damage(side: String, other: String, move: Dictionary) -> Dictionary:
	var hit := super(side, other, move)
	if side == "foe" and _soften_next:
		_soften_next = false   # le chant de Minuit : ce coup-là, deux fois plus doux
		hit["damage"] = maxi(1, roundi(hit["damage"] * 0.5))
	return hit


## Caillou : le coup du Souverain qui mettrait le dino de Chloé au sol, il le prend (une fois).
func _hurt(side: String, amount: int) -> bool:
	var d := dino(side)
	if caillou and _foe_striking and side == "player" and not _caillou_used and d.hp > 0 and d.hp - amount <= 0:
		_caillou_used = true
		_caillou_now = true
		return false
	return super(side, amount)


## Le coup pris par Caillou : à la place de ses dégâts (et de « Coup critique ! »…), Caillou et Maïa.
func _caillou_steps_in(ev: Array, from: int) -> void:
	for i in range(from, ev.size()):
		if ev[i]["type"] != "damage" or ev[i]["side"] != "player":
			continue
		var j := i + 1
		while j < ev.size() and ev[j]["type"] == "text" and String(ev[j]["text"]) in HIT_LINES:
			j += 1
		for k in j - i:
			ev.remove_at(i)
		ev.insert(i, {"type": "text", "text": CAILLOU[1]})
		ev.insert(i, {"type": "caillou", "text": CAILLOU[0]})
		return


## Le Tremblement : les dinos qui attendent à côté de Chloé perdent un peu (jamais sous 1 PV).
func _quake(ev: Array) -> void:
	var shaken := 0
	for i in team.size():
		var d := team[i]
		if i == active or d.hp <= 1:
			continue
		d.hp = maxi(1, d.hp - maxi(1, ceili(d.max_hp() * TREMOR_BENCH)))
		shaken += 1
	if shaken > 0:
		ev.append({"type": "quake", "text": "Le sol tremble sous toute l'équipe de Chloé !"})


# ------------------------------------------------------------------ l'Ambre clair et le dernier geste

func _starter_index() -> int:
	for i in team.size():
		if starter != &"" and team[i].species().id == starter:
			return i
	return -1


## Le dernier geste du dino de départ (il entre s'il n'y est pas, il se relève s'il est au sol), puis la goutte.
func _pour_antidote(ev: Array) -> void:
	var gesture: Array = GESTURE_ANY
	var who := player().nickname   # (sans dino de départ dans l'équipe : celui qui est là)
	var i := _starter_index()
	if i >= 0:
		var d := team[i]
		who = d.nickname
		gesture = GESTURES.get(starter, GESTURE_ANY)
		if d.hp <= 0:
			d.hp = maxi(1, ceili(d.max_hp() * RISE_SHARE))
			ev.append({"type": "gesture", "variant": "rise", "dino": d, "text": RISES % d.nickname})
		if i != active:
			if player().hp > 0:
				ev.append({"type": "recall", "side": "player", "text": "Reviens, %s !" % player().nickname})
			_send_in(i, ev)
			ev[-1]["text"] = STEPS_IN % d.nickname
	var lines: Array = gesture[1]
	for k in lines.size() - 1:
		ev.append({"type": "gesture", "variant": gesture[0], "step": k,
			"text": String(lines[k]) % who if String(lines[k]).contains("%s") else String(lines[k])})
	Game.use_item(ANTIDOTE)
	ev.append({"type": "antidote", "id": ANTIDOTE, "side": "foe", "text": String(lines[-1])})
	calm = calm_full
	ev.append({"type": "calm", "calm": calm, "text": DROP[0]})
	ev.append({"type": "calmed", "text": DROP[1] if is_souverain() else "Les veines violettes s'effacent. %s est apaisé !" % _calmed_name()})
	foe.corrupted = false
	foe.status = ""
	_give_xp(ev)
	_finish("calmed", ev)


# ------------------------------------------------------------------ « Encore. »

func _finish(how: String, ev: Array) -> void:
	if how == "lose" and rally:
		_rally(ev)
		return
	super(how, ev)


## Toute l'équipe au sol : elle se relève sur place, soignée ; les Sceaux et Caillou reviennent, le calme reste.
func _rally(ev: Array) -> void:
	rallies += 1
	_rallied_now = true
	for d in team:
		d.heal()
	_called.clear()
	_caillou_used = false
	_endured.clear()
	_soften_next = false
	stages = {"player": {"atk": 0, "def": 0, "spd": 0}, "foe": {"atk": 0, "def": 0, "spd": 0}}
	must_switch = false
	active = maxi(0, _first_able())
	ev.append({"type": "rally", "text": RALLY[0]})
	ev.append({"type": "text", "text": RALLY[1]})
	ev.append({"type": "switch", "side": "player", "text": "Vas-y, %s !" % player().nickname})
	ev.append({"type": "text", "text": RALLY[2]})
