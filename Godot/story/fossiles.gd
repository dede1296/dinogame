class_name Fossiles
## The post-game's legendary fossils (docs/post-game-plan.md § 2, docs/post-game-scenes.md « F »): three
## skeletons of five bones each, in nine zones of the island (BONES): thirteen buried, dug up with a
## Flair dino (world/os_enfoui.gd, put in the zones' scenes by tools/zones/os_legendaires.gd), two skulls
## one simply looks at (placed here on entering their zone: place). Tante Sirocco's notebook gives the
## land (F1); Isaure's page the sea (her bet, lot C: flag isaure_pari_gagne): a beast's bones only show
## once its page is given. Hélène at the Cabinet: a word at the first bone of each (F3), the resurrection
## once all five are there (F4: twenty amber tears, the incubator, one egg at a time), a word once it has
## hatched (F5); the hatching itself (level 45). The words: data/dialogue_fossiles.gd.
## Flags: carnet_os, carnet_terre, os_<beast>_1..5, helene_os_<beast>, helene_manque_<beast>,
## ressuscite_<beast>, eclos_<beast>, helene_eclos_<beast> (beast: titanosaure, kronosaurus, gigantoraptor).
## Objects: os_titanosaure, os_kronosaurus, os_gigantoraptor (0 to 5 each), carnet_os.
## New Game+ (lot D) keeps what starts with « os_ » (the bones, as objects and flags).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const A := preload("res://story/apex.gd")
const DF := preload("res://data/dialogue_fossiles.gd")

const BEASTS: Array[StringName] = [&"titanosaure", &"kronosaurus", &"gigantoraptor"]
const SPECIES := {&"titanosaure": &"saltasaurus", &"kronosaurus": &"kronosaurus", &"gigantoraptor": &"gigantoraptor"}
## The names the eggs come with (Doré, Cronos, Plume).
const EGG_NAMES := {&"titanosaure": "Doré", &"kronosaurus": "Cronos", &"gigantoraptor": "Plume"}
## What makes a beast's bones show: its page given (the land: Sirocco; the sea: Isaure's bet, lot C).
const SHOWN_BY := {&"titanosaure": &"carnet_terre", &"kronosaurus": &"isaure_pari_gagne", &"gigantoraptor": &"carnet_terre"}
## The price of a resurrection (Pépite's, in amber tears), the level of the newborn, the steps to walk.
const TEARS := 20
const EGG_LEVELS := {&"saltasaurus": 45, &"kronosaurus": 45, &"gigantoraptor": 45}
const EGG_STEPS := 300
## Experience for the party, a bone found (as for any item dug up: DigSpot.XP_ITEM).
const XP_BONE := 30
const ITEM_SFX := "res://assets/audio/sfx/item.wav"
const FOUND_SFX := "res://assets/audio/sfx/os-trouve.ogg"
const GLASS := "res://assets/audio/sfx/glass.wav"
const AMBER_FLASH := Color(1.0, 0.8, 0.4, 0.45)
## In the Cabinet (tiles): the incubator (PlainesAnnexes.INCUBATOR), the table.
const INCUBATOR := Vector2(13.8, 3.6)
const TABLE := Vector2(9.4, 5.1)

## Where each bone lies: flag -> [zone, tile, how]. « dig »: buried, a mound only a Flair dino finds
## (tools/zones/os_legendaires.gd puts it in the zone's scene); « look »: a skull one looks at (place).
## The pieces in order: 1 the head, 2 the back, 3 the ribs, 4 the legs, 5 the tail.
## Each tile checked on the built zone: walkable open ground, reached on foot (the Marais's mud bank:
## swimming, the Nage), never in the water (the reef's skull lies on its sea floor, Chloé swimming).
const BONES := {
	# Titanosaure d'Or: the crater's wall by the block that snores (bloc 3, 67.0, 20.5), away from the
	# amber vein; the Cimetière under the giant bone of page 17, Gérard (the great skull) in sight; the
	# foot of the Prairie's cliff wall, east of the amber door; the glacier's middle band by a blue
	# block and page 29; the ash at the volcano's foot, by the trail up to the forges.
	&"os_titanosaure_1": [&"terre_apex", Vector2(72.4, 22.4), "look"],
	&"os_titanosaure_2": [&"desert", Vector2(79.2, 77.4), "dig"],
	&"os_titanosaure_3": [&"plaines", Vector2(101.0, 39.4), "dig"],
	&"os_titanosaure_4": [&"monts", Vector2(82.4, 21.4), "dig"],
	&"os_titanosaure_5": [&"champs_cendres", Vector2(47.6, 6.8), "dig"],
	# Kronosaurus: the reef's sand hollow where Minuit listens; the third of the old slipway's steps;
	# under the carving « H. + I. » of the smugglers' cache; the mud bank of the Chenaux; the grass at
	# the end of the Havre's quay, past Isaure's pier (the Havre has no shore of sand).
	&"os_kronosaurus_1": [&"recif_sanctuaire", Vector2(19.6, 15.4), "look"],
	&"os_kronosaurus_2": [&"cote", Vector2(5.5, 71.6), "dig"],
	&"os_kronosaurus_3": [&"grottes_marines", Vector2(12.6, 3.4), "dig"],
	&"os_kronosaurus_4": [&"marais", Vector2(61.0, 52.4), "dig"],
	&"os_kronosaurus_5": [&"havre_dore", Vector2(54.5, 19.6), "dig"],
	# Gigantoraptor: the far end of the Grotte des Échos; page 8 under the great trees; by the first
	# bridge's post at the Pitons; in front of Bertille's shelter; by Griffe-Grise, asleep in his ravine.
	&"os_gigantoraptor_1": [&"grotte_echos", Vector2(19.5, 3.9), "dig"],
	&"os_gigantoraptor_2": [&"foret", Vector2(69.4, 84.0), "dig"],
	&"os_gigantoraptor_3": [&"cieux", Vector2(67.5, 75.5), "dig"],
	&"os_gigantoraptor_4": [&"monts", Vector2(20.5, 56.3), "dig"],
	&"os_gigantoraptor_5": [&"foret", Vector2(22.4, 81.8), "dig"],
}
## The two skulls one looks at: their prop's node name, picture (lot B'), and the stand-in meanwhile.
const SKULLS := {&"os_titanosaure_1": ["CraneTitanosaure", "crane_titanosaure_paroi", &"crane_titanosaure"],
	&"os_kronosaurus_1": ["CraneKronosaurus", "crane_kronosaurus_sable", &"crane_kronosaurus"]}
const SKULL_STAND_IN := "os_dino"


# ------------------------------------------------------------------ the bones (pure logic)

static func flag_of(beast: StringName, piece: int) -> StringName:
	return StringName("os_%s_%d" % [beast, piece + 1])


static func beast_of(flag: StringName) -> StringName:
	var s := String(flag)
	return StringName(s.substr(3, s.rfind("_") - 3)) if s.begins_with("os_") else &""


## 0 (the head) … 4 (the tail).
static func piece_of(flag: StringName) -> int:
	return int(String(flag).get_slice("_", 2)) - 1


static func item_of(beast: StringName) -> String:
	return "os_%s" % beast


static func beast_of_species(species: StringName) -> StringName:
	for b: StringName in BEASTS:
		if SPECIES[b] == species:
			return b
	return &""


## Which of its five bones Chloé has found.
static func pieces(beast: StringName) -> Array[bool]:
	var out: Array[bool] = []
	for i in 5:
		out.append(bool(Game.flag(flag_of(beast, i))))
	return out


static func found(beast: StringName) -> int:
	return pieces(beast).count(true)


static func found_all() -> int:
	var n := 0
	for b in BEASTS:
		n += found(b)
	return n


## Its page given (and the game over): its bones show.
static func shown(beast: StringName) -> bool:
	return Game.flag(&"post_game") and Game.flag(SHOWN_BY.get(beast, &"post_game"))


## A bone found: the object, the flag, some experience; the Dinodex « sees » the beast. True the first
## bone of its beast. Nothing again for a bone already found.
static func dig(flag: StringName) -> bool:
	if Game.flag(flag) or not BONES.has(flag):
		return false
	var beast := beast_of(flag)
	var first := found(beast) == 0
	Game.set_flag(flag)
	Game.give_item(item_of(beast))
	Game.award_team_xp(XP_BONE)
	Game.mark_seen(SPECIES[beast])
	return first


static func toast(flag: StringName) -> String:
	var beast := beast_of(flag)
	return DF.toast(beast, found(beast))


## After a bone (not waited for: the mound is already gone): the first of its beast, Chloé's thought.
static func after_find(flag: StringName, first: bool, who: String) -> void:
	if first:
		await S.say(DF.first_bone(beast_of(flag), who))


static func found_sound() -> AudioStream:
	return load(FOUND_SFX if ResourceLoader.exists(FOUND_SFX) else ITEM_SFX)


static func _toast(text: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		Toast.say(tree, text)


# ------------------------------------------------------------------ the notebook

## Its page has been given: the land's from Sirocco, the sea's from Isaure.
static func page_known(beast: StringName) -> bool:
	if beast == &"kronosaurus":
		return Game.flag(&"isaure_pari_gagne") == true or Game.flag(&"carnet_mer") == true
	return Game.flag(&"carnet_terre") == true


static func riddle(beast: StringName, piece: int) -> String:
	var all: Array = DF.RIDDLES.get(beast, [])
	return all[piece] if piece >= 0 and piece < all.size() else ""


## The notebook's pages Chloé has, for the journal wall (section « Carnet des os », lot D):
## {id, title, letter (its lines, title first), sign}.
static func carnet_pages() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in [&"titanosaure", &"gigantoraptor", &"kronosaurus"]:
		if page_known(b):
			var p := DF.page(b)
			out.append({"id": b, "title": DF.TITLES[b], "letter": p["letter"], "sign": p["sign"]})
	return out


## The journal wall's section « Le carnet des os » (ui/journal_pages.gd, lot D: JournalPages.sections),
## once Sirocco (or Isaure) has given a page ({} before): its three pages, each found with the flag that gives
## it (the land: carnet_terre; the sea: isaure_pari_gagne, lot C), its letter from DialogueFossiles.
static func journal_section() -> Dictionary:
	if not Game.flag(&"carnet_os") and not page_known(&"kronosaurus"):   # (Isaure's page may come first)
		return {}
	var pages: Array[Dictionary] = []
	for b: StringName in [&"titanosaure", &"gigantoraptor", &"kronosaurus"]:
		var flag: StringName = &"isaure_pari_gagne" if b == &"kronosaurus" else &"carnet_terre"
		pages.append({"flag": flag, "label": DF.TITLES[b], "source": func() -> Dictionary: return _page_letter(b)})
	return {"title": "Le carnet des os", "pages": pages, "numbered": false}


static func _page_letter(beast: StringName) -> Dictionary:
	var p := DF.page(beast)
	return {"paragraphs": p["letter"], "sign": p["sign"], "voice": ""}


## Tante Sirocco (Desert.sirocco, after her request of chapter 4 and while awake): F1 once the game is
## over. True when it played.
static func sirocco(who: Node) -> bool:
	if not Game.flag(&"post_game") or not Game.flag(&"fossiles_rendus") or Game.flag(&"carnet_os"):
		return false
	if who is Npc and Stage.chloe():
		(who as Npc).face(Stage.chloe().global_position)
	S.lock(true)
	var lines := DF.carnet(bool(Game.flag(&"found_journal_17")))
	lines[DF.TAP] = CS.cue(lines[DF.TAP], func() -> void: Stage.bow(who, 0.8))
	lines[DF.GIVE] = CS.cue(lines[DF.GIVE], func() -> void:
		Game.give_item("carnet_os")
		_toast("Objet obtenu : %s" % ItemsDB.item("carnet_os")["name"]))
	await S.say(lines)
	await S.say([DF.page(&"titanosaure"), DF.page(&"gigantoraptor")])
	Save.save_game()
	S.lock(false)
	return true


# ------------------------------------------------------------------ the skulls one looks at

## Entering a zone (Story._on_zone_entered): the skull of the crater's wall, the one on the reef's sand,
## once their page is given and until found.
static func place(zone: StringName) -> void:
	for flag: StringName in SKULLS:
		if BONES[flag][0] != zone or Game.flag(flag) or not shown(beast_of(flag)):
			continue
		var w = S.world()
		if w == null or w.get("region") == null or S.actor(SKULLS[flag][0]) != null:
			continue
		var kind: String = SKULLS[flag][1]
		var p := StoryProp.new()
		p.name = SKULLS[flag][0]
		p.set("kind", kind if Prop.KINDS.has(kind) and ResourceLoader.exists(Prop.ART % kind) else SKULL_STAND_IN)
		p.event = SKULLS[flag][2]
		p.hide_flag = flag
		var tile: Vector2 = BONES[flag][1]
		p.position = S.at(tile.x, tile.y)
		w.region.entities.add_child(p)


## A skull looked at (events crane_titanosaure, crane_kronosaurus): it comes out; the toast, the thought.
static func crane(event: StringName, who: Node) -> void:
	var flag: StringName = &"os_titanosaure_1" if event == &"crane_titanosaure" else &"os_kronosaurus_1"
	if Game.flag(flag):
		return
	var beast := beast_of(flag)
	var by: Dino = CS.diver() if beast == &"kronosaurus" else null   # (under the sea: the one she swims on)
	if by == null:
		by = Game.lead_dino()
	var name_: String = by.nickname if by else "Ton dino"
	S.lock(true)
	await S.say(DF.skull(beast, name_))
	var first := dig(flag)
	Audio.play_sfx(found_sound())
	_toast(toast(flag))
	if who is Node2D:
		await Stage.fade_out(who, 0.5, true)
	await after_find(flag, first, name_)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Hélène

## What Hélène has to say about the bones now, the most pressing first: {"say": &"eclos" (F5),
## &"premier" (F3), &"pret" (five bones: the resurrection), &"manque" (four: which one), "beast",
## "piece"}; {} when nothing.
static func helene_step() -> Dictionary:
	for b in BEASTS:
		if Game.flag(StringName("eclos_%s" % b)) and not Game.flag(StringName("helene_eclos_%s" % b)):
			return {"say": &"eclos", "beast": b}
	for b in BEASTS:
		if found(b) > 0 and not Game.flag(StringName("helene_os_%s" % b)):
			return {"say": &"premier", "beast": b, "piece": pieces(b).find(true)}
	for b in BEASTS:
		if found(b) == 5 and not Game.flag(StringName("ressuscite_%s" % b)):
			return {"say": &"pret", "beast": b}
	for b in BEASTS:
		if found(b) == 4 and not Game.flag(StringName("helene_manque_%s" % b)):
			return {"say": &"manque", "beast": b, "piece": pieces(b).find(false)}
	return {}


## Hélène in her armchair (ApexAutour.helene, after the epilogue, before her pool): the bones. True when
## she said something about them.
static func helene(who: Node) -> bool:
	if not Game.flag(&"epilogue_fini"):
		return false
	var step := helene_step()
	if step.is_empty():
		return false
	var beast: StringName = step["beast"]
	match step["say"]:
		&"eclos":
			await S.say(DF.helene_after(beast))
		&"premier":
			await S.say(DF.helene_first(beast, step["piece"]))
		&"manque":
			await S.say(DF.missing(beast, step["piece"]))
		&"pret":
			await _ready_to_wake(beast, who)
	Save.save_game()
	return true


## Why the resurrection of `beast` cannot be done now: &"manque" (not five bones), &"fait" (already),
## &"oeuf" (an egg carried: one at a time), &"larmes" (fewer than twenty tears); &"" when it can.
static func cannot(beast: StringName) -> StringName:
	if Game.flag(StringName("ressuscite_%s" % beast)):
		return &"fait"
	if found(beast) < 5:
		return &"manque"
	if not Game.egg.is_empty():
		return &"oeuf"
	if Game.tears() < TEARS:
		return &"larmes"
	return &""


## Resurrections done so far (0 to 3): the lines change after the first.
static func done() -> int:
	return BEASTS.filter(func(b: StringName) -> bool: return Game.flag(StringName("ressuscite_%s" % b))).size()


## The resurrection itself: twenty tears spent (they leave as the sold ones do: Game.tears), the egg
## carried. The bones stay in the bag (the Dinodex shows the whole skeleton). False if it cannot.
static func resurrect(beast: StringName) -> bool:
	if cannot(beast) != &"":
		return false
	Game.give_item("larmes_vendues", TEARS)
	var species: StringName = SPECIES[beast]
	Game.egg = {"species": String(species), "name": EGG_NAMES[beast], "steps": EGG_STEPS}
	Game.set_flag(StringName("ressuscite_%s" % beast))
	Game.mark_seen(species)
	return true


## Five bones: the choice, then a refusal (one line) or F4.
static func _ready_to_wake(beast: StringName, who: Node) -> void:
	if await Dialogue.choose(DF.HELENE, DF.ask(beast), DF.ASK_OPTIONS) != 0:
		return
	var why := cannot(beast)
	if why != &"":
		await S.say(DF.refusal(why, Game.tears()))
		return
	await _resurrection(beast, who)


## F4: the bones on the table, the tears; Roc takes them to the incubator, its light; the egg.
static func _resurrection(beast: StringName, who: Node) -> void:
	var n := done()
	S.lock(true)
	await S.say(DF.resurrection_before(beast, n))
	await _incubator(who)
	resurrect(beast)
	_toast("Objet obtenu : l'œuf de %s" % EGG_NAMES[beast])
	var lines := DF.resurrection_after(beast, n)
	lines[1] = CS.cue(lines[1], func() -> void:
		Stage.look_back()
		var roc = S.actor("Roc")
		if roc:
			Stage.emote(roc, "…"))
	await S.say(lines)
	S.lock(false)


## The watched part, without words: Roc carries the bones to the incubator, twice; it lights up, the
## bones melt (glass, a flash, sparkles).
static func _incubator(her: Node) -> void:
	var at := S.at(INCUBATOR.x, INCUBATOR.y)
	var table := S.at(TABLE.x, TABLE.y)
	var roc = S.actor("Roc")
	var home: Vector2 = (roc as Node2D).global_position if roc is Node2D else Vector2.ZERO
	Stage.look_at(at)
	if roc is Npc:
		for i in 2:
			await (roc as Npc).walk_to(table, "", 110.0)
			await (roc as Npc).walk_to(at, "", 110.0)
	if her is Node2D:
		Stage.bow(her, 0.8)   # (she pours the tears)
	await S.wait(0.4)
	Audio.play_sfx(load(GLASS), -2.0)
	Stage.flash(AMBER_FLASH, 1.2)
	var light := Stage.light_at(at, Color(1.0, 0.72, 0.3))
	if light:
		var t := light.create_tween()
		t.tween_property(light, "light_energy", 3.0, 0.8).set_trans(Tween.TRANS_SINE)
		t.tween_property(light, "light_energy", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
		t.tween_callback(light.queue_free)
	await S.wait(2.2)
	if roc is Npc:
		await (roc as Npc).walk_to(home, "", 110.0)


# ------------------------------------------------------------------ the egg, the hatching

static func is_fossil_egg(egg: Dictionary) -> bool:
	return beast_of_species(StringName(egg.get("species", ""))) != &""


## The egg hatches (PlainesAnnexes.hatch hands over the eggs of the bones): it grows « à vue d'œil »
## (level 45), joins the party or the Cabinet.
static func hatch() -> void:
	var egg := Game.egg
	Game.egg = {}
	var species := StringName(egg.get("species", ""))
	var beast := beast_of_species(species)
	if beast == &"":
		return
	var name_: String = egg.get("name", EGG_NAMES[beast])
	S.lock(true)
	var cast := {"baby": _hatchling(species, 1), "grown": _hatchling(species, 0)}
	var lines := DF.hatching(beast, name_)
	lines[0] = CS.cue(lines[0], func() -> void:
		Stage.shake(2.0, 0.25)
		Stage.tremble(Stage.chloe(), 0.35, 2.0))
	lines[1] = CS.cue(lines[1], func() -> void: _grows(cast))
	await S.say(lines)
	for k: String in cast:
		if is_instance_valid(cast[k]):
			Stage.fade_out(cast[k], 0.4, true)
	var d := Dino.create(species, EGG_LEVELS.get(species, 45), name_)
	var in_party := Game.add_caught(d)
	_toast("%s rejoint l'équipe !" % d.nickname if in_party else "%s rejoint le Cabinet." % d.nickname)
	Save.save_game()
	S.lock(false)


## The newborn by Chloé, as big as a dino of level `level` (0: grown), hidden until its line; a scene
## actor. None in the water.
static func _hatchling(species: StringName, level: int) -> DinoNpc:
	var chloe := Stage.chloe()
	var w = S.world()
	if chloe == null or w == null or w.get("region") == null or chloe.call(&"is_swimming"):
		return null
	var baby := DinoNpc.new()
	baby.species_id = species
	baby.level = level
	baby.position = S.ground_near(chloe.global_position + Vector2(60, 16), 2)
	baby.modulate.a = 0.0
	w.region.entities.add_child(baby)
	baby.remove_from_group(&"interactable")
	return baby


## Out of the shell, a hop; an amber flash, and it is grown (the little one gives way to the big one).
static func _grows(cast: Dictionary) -> void:
	var baby = cast.get("baby")
	var grown = cast.get("grown")
	if not is_instance_valid(baby) or not is_instance_valid(grown):
		return
	Stage.turn_to(baby, Stage.chloe().global_position)
	Stage.turn_to(grown, Stage.chloe().global_position)
	await Stage.fade_in(baby, 0.5)
	if not is_instance_valid(baby):
		return
	await Stage.hop(baby, 1, 5.0)
	Stage.flash(AMBER_FLASH, 0.9)
	Stage.fade_out(baby, 0.6)
	await Stage.fade_in(grown, 0.8)
	if is_instance_valid(grown):
		grown.cry(&"neutre")


# ------------------------------------------------------------------ the objective, the Dinodex

## The side objective « Les fossiles » (ApexObjectives.side): what to do next. {text, zone}.
static func objective() -> Dictionary:
	if not Game.flag(&"carnet_os"):
		return {"text": "Tante Sirocco, au Désert, a quelque chose à te dire sur les os de l'île.", "zone": &"desert"}
	for b in BEASTS:
		if found(b) == 5 and not Game.flag(StringName("ressuscite_%s" % b)):
			return {"text": "Les cinq os %s : à porter à Hélène, au Cabinet, avec vingt larmes d'ambre." % DF.OF[b], "zone": &"cabinet"}
	var text := "Les os des trois bêtes d'avant l'ambre : %d sur 15. Leurs devinettes sont dans leur fiche du Dinodex." % found_all()
	if not page_known(&"kronosaurus"):
		text += " La page de la mer : Isaure, à sa barque de Port-Ambre."
	return {"text": text, "zone": &""}


## The Dinodex sheet of a legendary (ui/dex_entry.gd): where it lives (nowhere: its bones), and its
## hint before it is seen.
static func dex_where(species: StringName) -> String:
	var beast := beast_of_species(species)
	if Game.flag(StringName("eclos_%s" % beast)):
		return "Il ne vit plus nulle part sur l'île, sauf avec toi : ses os ont fondu dans la couveuse du Cabinet."
	return "Il ne vit plus nulle part : ses cinq os sont dispersés sur l'île. Hélène et la couveuse du Cabinet sauront quoi en faire."


static func dex_hint(species: StringName) -> String:
	if page_known(beast_of_species(species)):
		return "Le carnet des os en parle : ses cinq os sont dispersés sur l'île, une devinette chacun (ci-dessous)."
	return "Tante Sirocco, au Désert, cherche des os depuis vingt ans. Elle doit savoir quelque chose."
