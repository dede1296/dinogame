class_name DexEntry
extends VBoxContainer
## The sheet of a species in the Dinodex (DexScreen): its pictures from the side and from the
## front (black shapes until seen), its number and name, then what Chloé knows of it.
##   Not seen: a rumour of where it lives (a region she knows), nothing more.
##   Seen: its pictures, name, type, family, size, description; where and when it lives (each
##   place, with its moments); its strengths and weaknesses.
##   Caught (or a unique met): everything — what it can do out in the world, its attacks, its
##   base stats, its diet, its era, a true story — and Chloé's own dinos of the species (team or
##   reserve), to bring into the team, to make lead, to leave in the reserve (or dragged onto
##   the team, on the right: DexTile).

const GOLD := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)
const AMBER := Color(0.98, 0.76, 0.35)
const LEFT_WIDTH := 330.0
const STATS := [["attaque", "Attaque", Color(0.92, 0.45, 0.35)], ["defense", "Défense", Color(0.55, 0.65, 0.8)],
	["vitesse", "Vitesse", Color(0.45, 0.85, 0.72)], ["force", "Force", Color(0.95, 0.7, 0.35)],
	["taille", "Taille", Color(0.75, 0.62, 0.9)], ["intel", "Ruse", Color(0.6, 0.85, 0.45)]]
## Part stats go from 0 to about 10.
const STAT_MAX := 10.0
const DAWN_TINT := Color(1.0, 0.62, 0.38)

var id: StringName
var screen: DexScreen
## One of Chloé's dinos of the species to show first (tapped in the team or the reserve).
var first: Dino
var _sp: DinoSpecies
var _status: StringName
var _seen := false
## Everything shown: caught, or a unique met (one does not catch those).
var _full := false
var _scroll: ScrollContainer
var _mine: Control


func _ready() -> void:
	_sp = SpeciesDB.get_species(id)
	_status = DexDB.status(id)
	_seen = _status != DexDB.UNSEEN
	_full = _status == DexDB.CAUGHT or (DexDB.is_unique(id) and _seen)
	add_theme_constant_override("separation", 8)
	add_child(_top_bar())
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	add_child(row)
	row.add_child(_identity())
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(_scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	_scroll.add_child(col)
	_fill(col)
	# Opened from one of Chloé's dinos: its row in view.
	if first and _mine:
		(func() -> void: _scroll.ensure_control_visible(_mine)).call_deferred()


func _top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	var back := DexScreen.ui_button("◂ Liste", 18, Vector2(110, 44))
	back.pressed.connect(screen.back_to_list)
	bar.add_child(back)
	var title := DexScreen.ui_label("%s   %s" % [DexDB.number_text(id), _sp.display_name if _seen else "???"], 26, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)
	var badge: Array = {DexDB.UNSEEN: ["Pas encore vu", Color(0.45, 0.48, 0.55)], DexDB.SEEN: ["Vu", Color(0.45, 0.75, 1.0)],
		DexDB.CAUGHT: ["Possédé", GOLD]}[_status]
	if DexDB.is_unique(id) and _seen:
		badge = ["Rencontré", Color(0.45, 0.75, 1.0)]
	bar.add_child(_pill(badge[0], badge[1]))
	return bar


# ------------------------------------------------------------------ left: who it is

func _identity() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(LEFT_WIDTH, 0)
	col.add_theme_constant_override("separation", 8)
	col.add_child(_pictures())
	if not _seen:
		col.add_child(DexScreen.ui_wrapped("Tu ne l'as pas encore vu. Quand tu l'auras croisé, sa fiche se remplira.", 16, Color(CREAM, 0.7)))
		return col
	if DexDB.is_unique(id):
		col.add_child(DexScreen.ui_wrapped(DexDB.unique_info(id)["role"], 18, AMBER))
	var pills := HFlowContainer.new()
	pills.add_theme_constant_override("h_separation", 8)
	var type := DexDB.type_of(id)
	pills.add_child(_pill("Type " + MovesDB.TYPE_NAMES.get(type, type), MovesDB.TYPE_COLORS.get(type, CREAM)))
	pills.add_child(_pill(DexDB.FAMILY_NAMES.get(_sp.family, String(_sp.family)), Color(0.3, 0.33, 0.4), CREAM))
	pills.add_child(_pill(DexDB.RARITY_NAMES.get(_sp.rarity, ""), Color(0.3, 0.33, 0.4), AMBER))
	col.add_child(pills)
	var cry := DexScreen.ui_button("Écouter son cri", 17, Vector2(0, 44))
	cry.pressed.connect(func() -> void:
		var s := _sp.cry("neutre")
		if s:
			Audio.play_sfx(s, -2.0, 0.05))
	col.add_child(cry)
	col.add_child(DexScreen.ui_wrapped(_sp.description, 15, Color(CREAM, 0.8)))
	return col


## The species from the side and from the front, on its type's colour (black shapes on grey
## until seen).
func _pictures() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(LEFT_WIDTH, 214)
	var colour: Color = MovesDB.TYPE_COLORS.get(DexDB.type_of(id), CREAM) if _seen else Color(0.4, 0.42, 0.48)
	var tint := Color.WHITE if _seen else DexTiles.SHADOW
	var side_tex := DexTiles.side(_sp)
	var face_tex := DexTiles.face(_sp)
	c.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, c.size)
		c.draw_style_box(DexTiles.card_box(colour.darkened(0.62), colour.darkened(0.15), 2, 16), r)
		var split := r.size.x * 0.66
		for ground: Array in [[Vector2(split / 2.0, r.size.y - 22.0), split * 0.42], [Vector2(split + (r.size.x - split) / 2.0, r.size.y - 22.0), 40.0]]:
			c.draw_set_transform(ground[0], 0.0, Vector2(1.0, 0.22))
			c.draw_circle(Vector2.ZERO, ground[1], Color(0, 0, 0, 0.28))
		c.draw_set_transform(Vector2.ZERO)
		DexTiles.draw_fit(c, side_tex, Rect2(10, 14, split - 14, r.size.y - 36), tint)
		DexTiles.draw_fit(c, face_tex, Rect2(split + 2, 44, r.size.x - split - 10, r.size.y - 66), tint)
		var font := c.get_theme_default_font()
		DexTiles.text(c, font, Vector2(0, r.size.y - 6), split, "de profil", 13, Color(CREAM, 0.55))
		DexTiles.text(c, font, Vector2(split, r.size.y - 6), r.size.x - split, "de face", 13, Color(CREAM, 0.55)))
	return c


# ------------------------------------------------------------------ right: what is known

func _fill(col: VBoxContainer) -> void:
	if not _seen:
		_section(col, "Où le trouver")
		for h in DexDB.hints(id):
			col.add_child(DexScreen.ui_wrapped("• " + h, 17, CREAM))
		return
	_section(col, "Fiche d'identité")
	var facts := DexDB.facts(id)
	col.add_child(_info_row("Taille réelle", facts.get("size", "?")))
	if _full:
		col.add_child(_info_row("Régime", DexFacts.DIETS.get(facts.get("diet", ""), "?")))
		col.add_child(_info_row("Époque", facts.get("era", "?")))
		col.add_child(_info_row("Fossiles", "trouvés %s" % facts.get("from", "") if facts.get("from", "") != "" else "?"))
		col.add_child(_info_row("Signe particulier", facts.get("trait", "")))
	_where(col)
	if not DexDB.is_unique(id) and _status == DexDB.CAUGHT:
		_my_dinos(col)
	_matchups(col)
	if not _full:
		col.add_child(DexScreen.ui_wrapped("Capture-en un pour découvrir ses capacités, ses attaques et une histoire vraie !", 16, AMBER))
		_diary(col)
		return
	_abilities(col)
	_attacks(col)
	_stats(col)
	_section(col, "Le savais-tu ?")
	var fact := PanelContainer.new()
	fact.add_theme_stylebox_override("panel", SettingsMenu._box(Color(0.3, 0.22, 0.08, 0.6), 12, 2, 12, AMBER))
	fact.add_child(DexScreen.ui_wrapped(facts.get("fact", ""), 17, CREAM))
	col.add_child(fact)
	_diary(col)


## Each place where it lives, with its moments (pictures of the sun, the moon…).
func _where(col: VBoxContainer) -> void:
	_section(col, "Où le trouver")
	if DexDB.is_unique(id):
		col.add_child(DexScreen.ui_wrapped(DexDB.unique_info(id)["where"], 17, CREAM))
		return
	var elsewhere := false   # (a region Chloé has not been to: not named)
	for p in DexDB.places(id):
		if not DexDB.region_known(p["region"]):
			elsewhere = true
			continue
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 2)
		block.add_child(DexScreen.ui_wrapped(DexDB.place_title(p), 17, CREAM))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 4)
		for icon: Array in _moment_icons(p):
			var t := TextureRect.new()
			t.texture = icon[0]
			t.modulate = icon[1]
			t.custom_minimum_size = Vector2(26, 26)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			line.add_child(t)
		var details := DexScreen.ui_wrapped(DexDB.place_details(p), 15, Color(CREAM, 0.72))
		line.add_child(details)
		block.add_child(line)
		col.add_child(block)
	if elsewhere:
		col.add_child(DexScreen.ui_wrapped(DexDB.ELSEWHERE, 15, Color(CREAM, 0.72)))
	if id in Game.STARTERS:
		col.add_child(DexScreen.ui_wrapped(DexDB.STARTER_HINT, 15, Color(CREAM, 0.72)))


## [texture, tint] for each moment and weather of a place.
func _moment_icons(p: Dictionary) -> Array:
	var out: Array = []
	var phases: Array = p["phases"]
	if &"dawn" in phases or &"dusk" in phases:
		out.append([ClockBadge.ICONS[&"sun"], DAWN_TINT])
	if &"day" in phases:
		out.append([ClockBadge.ICONS[&"sun"], Color.WHITE])
	if &"night" in phases:
		out.append([ClockBadge.ICONS[&"moon"], Color.WHITE])
	if p["full_moon"]:
		out.append([ClockBadge.ICONS[&"full_moon"], Color.WHITE])
	for w: StringName in p["weathers"]:
		if ClockBadge.ICONS.has(w):
			out.append([ClockBadge.ICONS[w], Color.WHITE])
		elif ClockBadge.LOCAL_ICONS.has(w):
			var def: Array = ClockBadge.LOCAL_ICONS[w]
			out.append([load(def[0]), Color.WHITE] if ResourceLoader.exists(def[0]) else [ClockBadge.ICONS[&"mist"], def[1]])
	return out


## Chloé's own dinos of the species: where they are, and the buttons to move them.
func _my_dinos(col: VBoxContainer) -> void:
	var mine := DexDB.owned(id)
	_mine = _section(col, "Mes %s : %d" % [_sp.display_name, mine.size()])
	if mine.is_empty():
		col.add_child(DexScreen.ui_wrapped("Tu n'en as plus avec toi.", 16, Color(CREAM, 0.7)))
		return
	var locked := screen.lock != ""
	for m: Dictionary in mine:
		var d: Dino = m["dino"]
		var i: int = m["index"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var tile := DexTiles.Owned.new()
		tile.dino = d
		tile.in_party = m["in_party"]
		tile.index = i
		tile.wide = true
		tile.highlighted = d == first
		tile.drag = screen.drag
		tile.scroll = _scroll
		tile.can_drag = func() -> bool: return m["in_party"] or not locked
		tile.drag_refused.connect(func() -> void: screen.note(screen.lock))
		row.add_child(tile)
		var where := "en tête de l'équipe" if m["in_party"] and i == 0 else "dans l'équipe" if m["in_party"] else "dans la réserve"
		var info := DexScreen.ui_label(where, 15, Color(CREAM, 0.7))
		info.custom_minimum_size = Vector2(150, 0)
		row.add_child(info)
		if m["in_party"]:
			if i > 0:
				var lead := DexScreen.ui_button("En tête", 16, Vector2(0, 44))
				lead.pressed.connect(screen.make_lead.bind(i))
				row.add_child(lead)
			var out := DexScreen.ui_button("En réserve", 16, Vector2(0, 44))
			out.disabled = locked or Game.party.size() <= 1
			out.pressed.connect(screen.send_to_reserve.bind(i))
			row.add_child(out)
		else:
			var join := DexScreen.ui_button("Dans l'équipe", 16, Vector2(0, 44))
			join.disabled = locked
			join.pressed.connect(screen.bring_in.bind(i, -1))
			row.add_child(join)
		col.add_child(row)
	if locked:
		col.add_child(DexScreen.ui_wrapped(screen.lock, 15, AMBER))
	elif mine.any(func(m: Dictionary) -> bool: return not m["in_party"]):
		col.add_child(DexScreen.ui_wrapped("Astuce : glisse un dino sur ton équipe, à droite, pour l'échanger.", 15, Color(CREAM, 0.6)))


func _matchups(col: VBoxContainer) -> void:
	_section(col, "Forces et faiblesses")
	var m := DexDB.matchups(DexDB.type_of(id))
	for line: Array in [["Fort contre", m["strong"]], ["Craint", m["weak"]], ["Résiste à", m["resists"]]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var caption := DexScreen.ui_label(line[0], 16, Color(CREAM, 0.8))
		caption.custom_minimum_size = Vector2(120, 0)
		row.add_child(caption)
		if (line[1] as Array).is_empty():
			row.add_child(DexScreen.ui_label("—", 16, Color(CREAM, 0.5)))
		for t: String in line[1]:
			row.add_child(_pill(MovesDB.TYPE_NAMES.get(t, t), MovesDB.TYPE_COLORS.get(t, CREAM)))
		col.add_child(row)


## What it can do out in the world (Abilities), with its picture.
func _abilities(col: VBoxContainer) -> void:
	_section(col, "Sur le terrain")
	var sample := DexDB.sample(id)
	var ids := Abilities.of(sample)
	var lines := Abilities.describe(sample)
	if ids.is_empty():
		col.add_child(DexScreen.ui_wrapped("Aucune capacité particulière : un bon compagnon de combat.", 16, Color(CREAM, 0.7)))
		return
	for k in ids.size():
		var def: Dictionary = Abilities.DEFS[ids[k]]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(38, 38)
		var soon: bool = def.get("soon", false)
		icon.draw.connect(func() -> void: Abilities.draw_icon(icon, def["icon"], icon.size / 2.0, 32.0, Color(AMBER, 0.5 if soon else 1.0)))
		row.add_child(icon)
		var text: String = lines[k]
		if def.get("adult", false):
			text += " (adulte, dès le niv. %d)" % Abilities.ADULT_LEVEL
		if soon:
			text += " — bientôt"
		row.add_child(DexScreen.ui_wrapped(text, 16, CREAM))
		col.add_child(row)


## The attacks it learns, level by level, in their type's colour.
func _attacks(col: VBoxContainer) -> void:
	_section(col, "Attaques")
	for e: Array in DexDB.learnset(id):
		var move := MovesDB.move(e[1])
		var colour: Color = MovesDB.TYPE_COLORS.get(move.get("type", "neutre"), CREAM)
		var card := PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = colour.darkened(0.6)
		box.border_color = colour
		box.border_width_left = 6
		box.set_corner_radius_all(8)
		box.content_margin_left = 12
		box.content_margin_right = 10
		box.content_margin_top = 3
		box.content_margin_bottom = 3
		card.add_theme_stylebox_override("panel", box)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var lv := DexScreen.ui_label("niv. %d" % e[0], 15, Color(CREAM, 0.65))
		lv.custom_minimum_size = Vector2(64, 0)
		row.add_child(lv)
		var caption := DexScreen.ui_label(move.get("name", "?"), 17, CREAM)
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(caption)
		var power: int = move.get("power", 0)
		row.add_child(DexScreen.ui_label("%s · %s" % [MovesDB.TYPE_NAMES.get(move.get("type", "neutre"), ""),
			"puissance %d" % power if power > 0 else "effet"], 15, Color(CREAM, 0.75)))
		col.add_child(card)


## The species' base stats (its body parts, 0–10), as bars.
func _stats(col: VBoxContainer) -> void:
	_section(col, "Ses points forts")
	var s := DexDB.sample(id).part_stats()
	for st: Array in STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var caption := DexScreen.ui_label(st[1], 16, Color(CREAM, 0.85))
		caption.custom_minimum_size = Vector2(110, 0)
		row.add_child(caption)
		var bar := Control.new()
		bar.custom_minimum_size = Vector2(0, 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ratio := clampf(float(s[st[0]]) / STAT_MAX, 0.0, 1.0)
		var colour: Color = st[2]
		bar.draw.connect(func() -> void:
			var r := Rect2(Vector2.ZERO, bar.size)
			bar.draw_rect(r, Color(1, 1, 1, 0.08))
			bar.draw_rect(Rect2(r.position, Vector2(r.size.x * ratio, r.size.y)), colour)
			bar.draw_rect(r, Color(0, 0, 0, 0.35), false, 1.5))
		row.add_child(bar)
		col.add_child(row)


## When it was first seen (and where), when first caught.
func _diary(col: VBoxContainer) -> void:
	_section(col, "Carnet")
	var key := String(id)
	var seen := DexDB.date_text(Game.dex_seen.get(key))
	var zone: String = Game.dex_where.get(key, "")
	var place: String = DexPlaces.ZONES.get(StringName(zone), {}).get("name", "") if zone != "" else ""
	col.add_child(DexScreen.ui_wrapped("Vu pour la première fois %s%s." % [seen if seen != "" else "il y a longtemps", " (" + place + ")" if place != "" else ""],
		16, Color(CREAM, 0.8)))
	var caught := DexDB.date_text(Game.dex_caught.get(key))
	if caught != "":
		col.add_child(DexScreen.ui_wrapped("Dans ton équipe pour la première fois %s." % caught, 16, Color(CREAM, 0.8)))


# ------------------------------------------------------------------ widgets

func _section(col: VBoxContainer, title: String) -> Control:
	var l := DexScreen.ui_label(title, 21, GOLD)
	col.add_child(l)
	return l


func _info_row(title: String, value: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var t := DexScreen.ui_label(title, 16, Color(CREAM, 0.7))
	t.custom_minimum_size = Vector2(150, 0)
	t.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	row.add_child(t)
	row.add_child(DexScreen.ui_wrapped(value, 17, CREAM))
	return row


func _pill(text: String, colour: Color, text_colour := Color(0.1, 0.08, 0.05)) -> Control:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(14)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", box)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(DexScreen.ui_label(text, 16, text_colour))
	return p
