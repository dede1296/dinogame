class_name CreditsRoll
extends Control
## Les crédits d'Ambrelune (docs/cinematiques.md § Les CRÉDITS), joués comme le dernier plan d'une
## cinématique (ui/cinematic.gd, plan « credits » : « Passer », la pause) — après la fin du jeu
## (Cinematiques.end_sequence) ou depuis le menu (Cinematiques.play_credits) :
## - le fond animé C-01 (Cinematiques.credits_background : la mer au crépuscule depuis la jetée, le ciel
##   qui passe à la nuit, les étoiles une à une, les dinos qui passent un par un) ;
## - le carton d'ouverture, seul au centre : la première section de CreditsData (« Ambrelune », « Un jeu
##   créé par Grégory Cuypers »…) ; après la fin du jeu, « Ambrelune » d'abord seul (F-10) ;
## - le défilé de CreditsData (la seule source : tirée de docs/credits.md), lent et lisible par un enfant,
##   dans le ciel : titres en ambre, lignes en crème, « ## » = sous-titre, « » = un espace ;
## - « Pour Chloé » (décision de Greg), puis « Merci d'avoir joué », qui reste, puis le fondu.
## A, Espace, Entrée ou un clic : pause (la cinématique appelle toggle_pause).

const SPEED := 25.0               # px/s for a screen 720 px tall
const OPENING_S := 5.0
const CARD_IN := 1.0
const CARD_HOLD := 3.0
const THANKS_HOLD := 4.0
const REST_IN := 1.0              # the rest of the roll fades in once the opening card starts to rise
const AREA_TOP := 0.04            # the sky: where the roll is read (screen heights)
const AREA_BOTTOM := 0.62
const EDGE := 54.0                # lines fade in and out over this much at the area's edges
const WIDTH := 960.0
const CREATOR := "Grégory Cuypers"
const DEDICATION := "Pour Chloé"
const THANKS := "Merci d'avoir joué"
const AMBER := Color(0.98, 0.76, 0.35)   # #fac259
const CREAM := Color(0.98, 0.94, 0.84)
const OUTLINE := Color(0.08, 0.06, 0.05, 0.92)
## Each kind of line: [font size, colour, outline].
const STYLES := {
	"card_title": [84, Color(1, 0.86, 0.5), 16],
	"card_name": [46, CREAM, 10],
	"card_line": [26, Color(CREAM, 0.9), 8],
	"section": [34, AMBER, 10],
	"subtitle": [25, Color(1, 0.88, 0.62), 8],
	"line": [23, CREAM, 8],
	"card": [52, CREAM, 12],
}
const SPACE_PX := {"space": 16.0, "section_gap": 56.0}

var plan: Dictionary
var done := false
var paused := false
## "opening", "roll", "dedication", "thanks".
var phase := "opening"
var background: CinematicPlan
var content: VBoxContainer
var _opening: VBoxContainer
var _rest: Array[Control] = []
var _card: Label
var _phase_t := 0.0
var _scroll := 0.0
var _opening_s := OPENING_S
var _title_alone := 0.0


static func create(p: Dictionary) -> CreditsRoll:
	var roll := CreditsRoll.new()
	roll.plan = p
	roll._build()
	return roll


## What the roll says, in order: {"text", "style"} — the opening card (section 1 of CreditsData), then
## each section (its title, its lines), then the two last cards. From CreditsData only.
static func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in CreditsData.SECTIONS.size():
		var section: Dictionary = CreditsData.SECTIONS[i]
		if i == 0:
			for line in section["lines"]:
				out.append({"text": String(line), "style": _opening_style(String(line)), "opening": true})
			continue
		out.append({"text": "", "style": "section_gap"})
		out.append({"text": String(section["title"]), "style": "section"})
		for line in section["lines"]:
			var text := String(line)
			if text == "":
				out.append({"text": "", "style": "space"})
			elif text.begins_with("## "):
				out.append({"text": text.substr(3), "style": "subtitle"})
			else:
				out.append({"text": text, "style": "line"})
	out.append({"text": DEDICATION, "style": "card"})
	out.append({"text": THANKS, "style": "card"})
	return out


static func _opening_style(line: String) -> String:
	if line == CreditsData.GAME_TITLE:
		return "card_title"
	if line == CREATOR:
		return "card_name"
	return "space" if line == "" else "card_line"


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_opening_s = float(plan.get("opening_secs", OPENING_S))
	_title_alone = float(plan.get("title_alone", 0.0))
	background = CinematicPlan.create(plan.get("background", {}), float(plan.get("background_secs", 100.0)))
	add_child(background)
	content = VBoxContainer.new()
	content.name = "Roll"
	content.add_theme_constant_override(&"separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.custom_minimum_size = Vector2(WIDTH, 0)
	add_child(content)
	_opening = VBoxContainer.new()
	_opening.add_theme_constant_override(&"separation", 8)
	_opening.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_opening)
	for entry: Dictionary in entries():
		var style := String(entry["style"])
		if style == "card":
			continue   # (the last two cards: shown on their own, see _card)
		var node := _line(entry)
		if entry.get("opening", false):
			_opening.add_child(node)
			if style != "card_title" and _title_alone > 0.0:
				node.set_meta(&"after_title", true)
		else:
			content.add_child(node)
			_rest.append(node)
	_card = _label(DEDICATION, "card")
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card.modulate.a = 0.0
	add_child(_card)


func _line(entry: Dictionary) -> Control:
	var style := String(entry["style"])
	if SPACE_PX.has(style):
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, SPACE_PX[style])
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return gap
	var label := _label(String(entry["text"]), style)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(WIDTH, 0)
	return label


func _label(text: String, style: String) -> Label:
	var look: Array = STYLES.get(style, STYLES["line"])
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", look[0])
	label.add_theme_color_override(&"font_color", look[1])
	label.add_theme_color_override(&"font_outline_color", OUTLINE)
	label.add_theme_constant_override(&"outline_size", look[2])
	return label


## Every line the roll shows (the tests: built from CreditsData).
func shown_texts() -> Array[String]:
	var out: Array[String] = []
	for node in _opening.get_children() + content.get_children():
		if node is Label:
			out.append((node as Label).text)
	out.append(DEDICATION)
	out.append(THANKS)
	return out


func toggle_pause() -> void:
	paused = not paused


# ------------------------------------------------------------------ time

func tick(dt: float) -> void:
	background.tick(dt)
	if done:
		return
	if not paused:
		_phase_t += dt
	var screen := size if size.x > 0.0 else CinematicPlan.BASE
	var top := screen.y * AREA_TOP
	var bottom := screen.y * AREA_BOTTOM
	content.position.x = (screen.x - content.size.x) * 0.5
	match phase:
		"opening":
			_scroll = 0.0
			if _phase_t >= _opening_s:
				_to("roll")
		"roll":
			if not paused:
				_scroll += SPEED * screen.y / 720.0 * dt
			if content.position.y + content.size.y < top and content.size.y > 0.0:
				_card.text = DEDICATION
				_to("dedication")
		"dedication":
			_card.modulate.a = _card_alpha(CARD_HOLD, true)
			if _phase_t >= CARD_IN * 2.0 + CARD_HOLD:
				_card.text = THANKS
				_to("thanks")
		"thanks":
			_card.modulate.a = _card_alpha(THANKS_HOLD, false)
			if _phase_t >= CARD_IN + THANKS_HOLD:
				done = true
	# The opening card at the middle of the sky, then the whole roll going up.
	content.position.y = (top + bottom) * 0.5 - _opening.size.y * 0.5 - _scroll
	_fade_lines(top, bottom)


func _to(next: String) -> void:
	phase = next
	_phase_t = 0.0


func _card_alpha(hold: float, goes: bool) -> float:
	var a := clampf(_phase_t / CARD_IN, 0.0, 1.0)
	if goes:
		a = minf(a, clampf((CARD_IN * 2.0 + hold - _phase_t) / CARD_IN, 0.0, 1.0))
	return a


## Lines fade in from the horizon and out at the top of the sky (never over the sea or the jetty);
## the opening card's lines after the title come once it has shown alone; the rest of the roll stays
## hidden while the opening card is alone at the centre.
func _fade_lines(top: float, bottom: float) -> void:
	var rest := 1.0
	var after_title := 1.0
	if phase == "opening":
		rest = 0.0
		after_title = clampf((_phase_t - _title_alone) / REST_IN, 0.0, 1.0)
	elif phase == "roll":
		rest = clampf(_phase_t / REST_IN, 0.0, 1.0)
	for node in _opening.get_children():
		var a := _edge_alpha(node as Control, top, bottom)
		(node as Control).modulate.a = a * (after_title if node.has_meta(&"after_title") else 1.0)
	for node in _rest:
		node.modulate.a = _edge_alpha(node, top, bottom) * rest


func _edge_alpha(node: Control, top: float, bottom: float) -> float:
	var y := node.global_position.y - global_position.y + node.size.y * 0.5
	return smoothstep(top, top + EDGE, y) * (1.0 - smoothstep(bottom - EDGE, bottom, y))
