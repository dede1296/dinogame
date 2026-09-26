class_name DinoCard
extends PanelContainer
## A dino's sheet, clear at a glance: its portrait on its type's colour, name, species, type
## and level; health and experience bars; its three stats as bars; its attacks as cards in
## their type's colour; what it can do out in the world (Tranche, Charge, Flair, Monture,
## Vol, Nage…), each with its picture; its species' description.

signal closed

const INK := Color(0.106, 0.122, 0.157, 0.97)
const CREAM := Color(1, 0.97, 0.9)
const AMBER := Color(0.98, 0.76, 0.35)
const PANEL_BORDER := Color(0.79, 0.54, 0.16)
const XP_BLUE := Color(0.45, 0.75, 1.0)
const STATS := [["atk", "Attaque", Color(0.92, 0.45, 0.35)], ["def", "Défense", Color(0.55, 0.65, 0.8)], ["spd", "Vitesse", Color(0.45, 0.85, 0.72)]]
## A stat bar is full at this value times the level (so bars stay comparable between dinos).
const STAT_SCALE := 3.2

var dino: Dino


static func make(d: Dino) -> DinoCard:
	var card := DinoCard.new()
	card.dino = d
	return card


func _ready() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = PANEL_BORDER
	box.set_border_width_all(3)
	box.set_corner_radius_all(20)
	box.set_content_margin_all(16)
	add_theme_stylebox_override("panel", box)
	custom_minimum_size = Vector2(780, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	add_child(row)
	row.add_child(_identity())
	row.add_child(_details())


# ------------------------------------------------------------------ left: who it is

func _identity() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(220, 0)
	col.add_theme_constant_override("separation", 6)
	var type_colour: Color = MovesDB.TYPE_COLORS.get(dino.type(), CREAM)
	var face := Control.new()
	face.custom_minimum_size = Vector2(200, 200)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tex := PartyBar.portrait(dino.species())
	face.draw.connect(func() -> void:
		var c := face.size / 2.0
		face.draw_circle(c, 98.0, type_colour.darkened(0.35))
		face.draw_circle(c, 92.0, type_colour.lerp(Color.WHITE, 0.55))
		face.draw_texture_rect(tex, Rect2(c - Vector2(88, 88), Vector2(176, 176)), false)
		face.draw_arc(c, 95.0, 0.0, TAU, 64, AMBER, 4.0, true)
		# The level, on a badge at the bottom right.
		var b := c + Vector2(66, 66)
		face.draw_circle(b, 26.0, INK)
		face.draw_arc(b, 26.0, 0.0, TAU, 32, AMBER, 3.0, true)
		var font := face.get_theme_default_font()
		var lvl := str(dino.level)
		var w := font.get_string_size(lvl, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		face.draw_string(font, b + Vector2(-w / 2.0, 8), lvl, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, CREAM)
		face.draw_string(font, b + Vector2(-12, -12), "niv.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(CREAM, 0.7)))
	col.add_child(face)
	col.add_child(_label(dino.nickname, 28, AMBER, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(_label(dino.species_name(), 16, Color(CREAM, 0.75), HORIZONTAL_ALIGNMENT_CENTER))
	var badge := _pill("Type " + MovesDB.TYPE_NAMES.get(dino.type(), dino.type()), type_colour)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(badge)
	var about := _label(dino.species().description, 14, Color(CREAM, 0.7), HORIZONTAL_ALIGNMENT_CENTER)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size = Vector2(220, 0)
	col.add_child(about)
	return col


# ------------------------------------------------------------------ right: what it does

func _details() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.add_child(_label("État", 20, AMBER))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var close := Button.new()
	close.text = "✕"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(44, 44)
	close.add_theme_font_size_override("font_size", 22)
	close.add_theme_color_override("font_color", CREAM)
	for state in ["normal", "hover", "pressed"]:
		var b := StyleBoxFlat.new()
		b.bg_color = Color(0.16, 0.18, 0.22, 1.0 if state == "normal" else 0.8)
		b.border_color = PANEL_BORDER
		b.set_border_width_all(2)
		b.set_corner_radius_all(22)
		close.add_theme_stylebox_override(state, b)
	close.pressed.connect(func() -> void: closed.emit())
	top.add_child(close)
	col.add_child(top)
	var hp_ratio := float(dino.hp) / maxf(dino.max_hp(), 1.0)
	var hp_colour := Color(0.45, 0.85, 0.4) if hp_ratio > 0.5 else Color(0.95, 0.8, 0.3) if hp_ratio > 0.2 else Color(0.95, 0.4, 0.3)
	col.add_child(_bar("PV", hp_ratio, "%d / %d" % [dino.hp, dino.max_hp()], hp_colour))
	col.add_child(_bar("Exp.", float(dino.xp) / maxf(Dino.xp_to_next(dino.level), 1.0), "%d / %d" % [dino.xp, Dino.xp_to_next(dino.level)], XP_BLUE))
	var s := dino.stats()
	for st: Array in STATS:
		col.add_child(_bar(st[1], s[st[0]] / (STAT_SCALE * dino.level + 10.0), str(s[st[0]]), st[2]))
	col.add_child(_label("Attaques", 20, AMBER))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for m: Dictionary in dino.moves:
		grid.add_child(_move_card(MovesDB.move(m["id"])))
	col.add_child(grid)
	col.add_child(_label("Sur le terrain", 20, AMBER))
	col.add_child(_abilities())
	return col


## A labelled bar: name, the bar, the value.
func _bar(title: String, ratio: float, value: String, colour: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name := _label(title, 16, Color(CREAM, 0.85))
	name.custom_minimum_size = Vector2(70, 0)
	row.add_child(name)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, bar.size)
		bar.draw_rect(r, Color(1, 1, 1, 0.08))
		bar.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(ratio, 0.0, 1.0), r.size.y)), colour)
		bar.draw_rect(r, Color(0, 0, 0, 0.35), false, 1.5))
	row.add_child(bar)
	var v := _label(value, 16, CREAM, HORIZONTAL_ALIGNMENT_RIGHT)
	v.custom_minimum_size = Vector2(76, 0)
	row.add_child(v)
	return row


## An attack as a little card in its type's colour: name, type, power.
func _move_card(move: Dictionary) -> Control:
	var colour: Color = MovesDB.TYPE_COLORS.get(move.get("type", "neutre"), CREAM)
	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = colour.darkened(0.55)
	box.border_color = colour
	box.border_width_left = 6
	box.set_corner_radius_all(8)
	box.content_margin_left = 12
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", box)
	card.custom_minimum_size = Vector2(240, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)
	col.add_child(_label(move.get("name", "?"), 17, CREAM))
	var power: int = move.get("power", 0)
	var info: String = MovesDB.TYPE_NAMES.get(move.get("type", "neutre"), "")
	info += " · puissance %d" % power if power > 0 else " · effet"
	col.add_child(_label(info, 13, Color(CREAM, 0.7)))
	return card


## The abilities, each with its picture; the ones still to come say so.
func _abilities() -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	var ids := Abilities.of(dino)
	if ids.is_empty():
		flow.add_child(_label("Aucune capacité particulière : un bon compagnon de combat.", 15, Color(CREAM, 0.6)))
		return flow
	for id in ids:
		var def: Dictionary = Abilities.DEFS[id]
		var young: bool = def.get("adult", false) and dino.level < Abilities.ADULT_LEVEL
		var soon: bool = def.get("soon", false) or young
		var chip := PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.16, 0.18, 0.22)
		box.border_color = Color(AMBER, 0.45 if soon else 1.0)
		box.set_border_width_all(2)
		box.set_corner_radius_all(10)
		box.set_content_margin_all(6)
		chip.add_theme_stylebox_override("panel", box)
		chip.tooltip_text = def["desc"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		chip.add_child(row)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(34, 34)
		var colour := Color(AMBER, 0.5 if soon else 1.0)
		icon.draw.connect(func() -> void: Abilities.draw_icon(icon, def["icon"], icon.size / 2.0, 30.0, colour))
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", -2)
		text.add_child(_label(def["name"], 16, Color(CREAM, 0.55 if soon else 1.0)))
		if young:
			text.add_child(_label("adulte au niv. %d" % Abilities.ADULT_LEVEL, 12, Color(CREAM, 0.6)))
		elif soon:
			text.add_child(_label("bientôt", 12, Color(CREAM, 0.5)))
		row.add_child(text)
		flow.add_child(chip)
	return flow


func _pill(text: String, colour: Color) -> Control:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(14)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", box)
	p.add_child(_label(text, 16, Color(0.1, 0.08, 0.05)))
	return p


func _label(text: String, font_size: int, colour: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	return l
