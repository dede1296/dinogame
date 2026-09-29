class_name SeaLessons
extends RefCounted
## The first current, bubble column and dark nook Chloé meets (la Plongée, chapter 5): a short
## scene where her diver shows it, the lines saying what is seen as it happens (the current
## sweeps weed and bubbles past, the column gushes, the Cœurs light up). Once each (flags).
## A current in the way, met after the first one: a word only (a toast).

const CURRENT_FLAG := &"courant_explique"
const AGAINST_FLAG := &"courant_contraire_vu"
const COLUMN_FLAG := &"colonne_expliquee"
const NOOK_FLAG := &"recoin_explique"
const CHLOE := "Chloé"
const AGAINST_TIP := "Un courant contraire : trop fort pour nager contre lui. Passe d'un rocher à l'autre, à l'abri derrière eux."

## After one of these scenes, no other before this long (ms): never two in a row.
const QUIET_MS := 15000

static var _playing := false
static var _quiet_until := 0


## The current `c` is near: shown once (the first one), then a word for one in the way.
static func current(c: Node2D) -> void:
	if _playing or not _free():
		return
	if Game.flag(CURRENT_FLAG):
		if not c.get(&"helps") and not Game.flag(AGAINST_FLAG):
			Game.set_flag(AGAINST_FLAG)
			Toast.say(c.get_tree(), AGAINST_TIP, Color(0.55, 0.9, 1.0))
		return
	_playing = true
	Game.set_flag(CURRENT_FLAG)
	var diver := _diver()
	var who := diver.dino.nickname if diver else "Ton dino"
	var mid: Vector2 = (c.call(&"area") as Rect2).get_center()
	_lock(true)
	await _look(mid)
	var features := _features(c)
	var lines: Array = [
		_cue({"text": "Un peu plus loin, l'eau file : des bulles et des brins d'algue passent à toute allure, tous couchés dans le même sens."},
			_show.bind(features, &"show_current", c)),
		_cue({"text": "%s s'arrête net au bord du courant, la tête tendue vers lui. Il tire déjà sur ses nageoires." % who},
			_diver_points.bind(diver, mid)),
	]
	if c.get(&"helps"):
		lines.append({"who": CHLOE, "text": "(Il suffit de se laisser porter : il nous emmène d'un seul coup… mais on ne pourra pas le remonter.)"})
	else:
		lines.append({"who": CHLOE, "text": "(Trop fort pour nager contre lui. Mais derrière les rochers, l'eau a l'air calme…)"})
	await Dialogue.run(lines)
	_lock(false)
	_playing = false
	_quiet_until = Time.get_ticks_msec() + QUIET_MS


## The column `c` is near: shown once.
static func column(c: Node2D) -> void:
	if _playing or Game.flag(COLUMN_FLAG) or not _free():
		return
	_playing = true
	Game.set_flag(COLUMN_FLAG)
	var diver := _diver()
	var who := diver.dino.nickname if diver else "Ton dino"
	var foot: Vector2 = (c.call(&"area") as Rect2).get_center()
	var up: Vector2 = c.call(&"landing_px")
	_lock(true)
	await _look(foot)
	var features := _features(c)
	await Dialogue.run([
		_cue({"text": "Une faille s'ouvre dans le sable. Il en monte une colonne de grosses bulles qui grondent doucement, droit vers le haut."},
			_show.bind(features, &"show_column", c)),
		_cue({"text": "Tout en haut, un plateau de roche. Bien trop haut pour y nager."}, _look.bind(up)),
		_cue({"text": "%s tend le cou vers les bulles, puis se retourne vers Chloé. Il a compris avant elle." % who},
			_point_back.bind(diver, foot)),
		{"who": CHLOE, "text": "(On entre dans les bulles, et elles nous montent là-haut. Pour redescendre, il suffira de nager par-dessus le bord.)"},
	])
	_lock(false)
	_playing = false
	_quiet_until = Time.get_ticks_msec() + QUIET_MS


## The nook `n` is near, and Chloé carries a Cœur: shown once.
static func nook(n: Node2D) -> void:
	if _playing or Game.flag(NOOK_FLAG) or not _free():
		return
	_playing = true
	Game.set_flag(NOOK_FLAG)
	var chloe := _chloe()
	var features := _features(n)
	var find: Node2D = n.call(&"nearest_find", chloe.global_position)
	var near: bool = find != null and find.global_position.distance_to(chloe.global_position) < float(n.call(&"light_radius_px"))
	_lock(true)
	var lines: Array = [
		_cue({"text": "Il fait noir comme au fond d'un puits… Dans la sacoche de Chloé, les Cœurs d'ambre se mettent à luire, et une lumière dorée glisse sur le sable."},
			_show.bind(features, &"flare", n)),
	]
	if near:
		lines.append(_cue({"text": "Là, entre les pierres : quelque chose brille, juste au bord de la lumière."},
			_look.bind(find.global_position)))
	else:
		lines.append({"text": "Tout ce qui n'est pas dans leur lumière reste noyé dans le noir."})
	lines.append({"who": CHLOE, "text": "(Les Cœurs montrent ce que l'eau cache. Plus j'en aurai, plus ils éclaireront loin.)"})
	await Dialogue.run(lines)
	_lock(false)
	_playing = false
	_quiet_until = Time.get_ticks_msec() + QUIET_MS


# ------------------------------------------------------------------ helpers

## The 3D view shows what the line says (SeaFeatures.show_current, show_column, flare).
static func _show(features: Node, method: StringName, what: Node2D) -> void:
	if features:
		features.call(method, what)


## The camera comes back to the column's foot, and her diver points at it.
static func _point_back(diver: Companion, at: Vector2) -> void:
	_look(at)
	_diver_points(diver, at)


## A line whose move starts the moment it shows.
static func _cue(line: Dictionary, action: Callable) -> Dictionary:
	var text: String = line["text"]
	var cued := line.duplicate()
	cued.erase("text")
	cued["text_fn"] = func() -> String:
		action.call_deferred()
		return text
	return cued


static func _free() -> bool:
	if Time.get_ticks_msec() < _quiet_until:
		return false
	var chloe := _chloe()
	var w = Engine.get_main_loop().current_scene
	return chloe != null and chloe.can_move() and not chloe.get_tree().paused and w != null and not w.get(&"_changing_zone")


static func _chloe() -> Player:
	return (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"player") as Player


static func _diver() -> Companion:
	return (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"companion") as Companion


static func _features(n: Node) -> Node:
	return n.get_tree().get_first_node_in_group(&"sea_features")


static func _lock(on: bool) -> void:
	var chloe := _chloe()
	if chloe == null:
		return
	chloe.busy = on
	chloe.velocity = Vector2.ZERO
	if not on:
		_look(Vector2.INF)


## The camera shows `px` (INF: back to Chloé); awaitable, the time to get there.
static func _look(px: Vector2) -> void:
	var view := (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view")
	if view:
		view.set(&"focus_px", px)
	await (Engine.get_main_loop() as SceneTree).create_timer(0.8).timeout


## Her diver turns to `at`, cries and rears where it swims, a « ! » over it.
static func _diver_points(diver: Companion, at: Vector2) -> void:
	if diver == null:
		return
	var view := diver.get_tree().get_first_node_in_group(&"world_view")
	if view:
		view.call(&"emote", diver, "!")
	diver.perform_at(at)
