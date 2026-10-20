class_name JournalPages
extends RefCounted
## The pages of the journal wall (ui/journal_wall.gd; docs/mecaniques.md § Le Cabinet), by section, in order:
## Hélène's forty pages, then the Anciens' three (the parent of each egg: Chloé gets the page of hers, and
## of the stolen one's). A page: {flag (set when found: found_journal_*), label (on the wall), source}; its
## source gives the letter LetterView shows: a dialogue event (DialogueDB.lines: the "letter" step before the
## page's flag), the paragraphs themselves (title first, Hélène's « — H. »), or a Callable that returns
## {paragraphs, sign, voice}.
## Nouvelle partie+ (docs/post-game-plan.md § 4): a page found in a game before (Game.pages_read_before) and
## not found again in this one is « déjà lue », grey, and not readable: found again, it is read again.
## Another section (the Carnet des os of the FOSSILES lot): one more entry in sections(), its pages built
## with page() the same way.

enum State { FOUND, READ_BEFORE, UNKNOWN }

const HELENE_PAGES := 40
const SIGN := "— H."
## Pages whose letter is not in an event named page_<n>.
const HELENE_SOURCES := {1: &"ambre_proto"}


## The sections of the wall: [{title, pages: [page()…], numbered (its pages counted « 12 pages sur 40 »)}].
static func sections() -> Array[Dictionary]:
	var helene: Array[Dictionary] = []
	for n in range(1, HELENE_PAGES + 1):
		helene.append(page(StringName("found_journal_%d" % n), str(n), _helene_source(n)))
	var anciens: Array[Dictionary] = [
		page(&"found_journal_ancien", "Griffe-Grise", Foret.ANCIEN_PAGE),
		page(&"found_journal_ancien_rempart", "Le Vieux Rempart", Desert.REMPART_PAGE),
		page(&"found_journal_ancien_voix", "La Voix du Marais", Marais.VOIX_PAGE),
	]
	var out: Array[Dictionary] = [
		{"title": "Le journal d'Hélène", "pages": helene, "numbered": true},
		{"title": "Les pages des Anciens", "pages": anciens, "numbered": false},
	]
	var carnet := Fossiles.journal_section()   # (post-game, lot B: the bone notebook, once a page is given)
	if not carnet.is_empty():
		out.append(carnet)
	return out


static func page(flag: StringName, label: String, source: Variant) -> Dictionary:
	return {"flag": flag, "label": label, "source": source}


## Every page of the wall, section after section.
static func all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for section in sections():
		out.append_array(section["pages"])
	return out


static func state(p: Dictionary) -> State:
	var found: Variant = Game.flag(p["flag"])
	if found is bool and found:
		return State.FOUND
	if Game.pages_read_before().has(String(p["flag"])):
		return State.READ_BEFORE
	return State.UNKNOWN


## [found, total] among `pages`.
static func counts(pages: Array) -> Vector2i:
	var found := pages.filter(func(p: Dictionary) -> bool: return state(p) == State.FOUND).size()
	return Vector2i(found, pages.size())


## Is there anything on the wall yet (a page found, or read in a game before)?
static func any() -> bool:
	return all().any(func(p: Dictionary) -> bool: return state(p) != State.UNKNOWN)


## The letter of a page: {paragraphs (title first), sign, voice}; {} when its source gives none.
## Reading it changes nothing in the game (the lines are only read, never played).
static func letter(p: Dictionary) -> Dictionary:
	var source: Variant = p["source"]
	if source is Callable:
		return (source as Callable).call()
	if source is Array:
		return {"paragraphs": source, "sign": SIGN, "voice": ""}
	var found := {}
	for step in DialogueDB.lines(source):
		if not step is Dictionary:
			continue
		if step.has("letter"):
			found = step
		elif step.has("flag") and StringName(step["flag"]) == p["flag"]:
			break
	if found.is_empty():
		return {}
	return {"paragraphs": found["letter"], "sign": String(found.get("sign", "")), "voice": String(found.get("voice", ""))}


## The title of a page (the first line of its letter), "" when it has none.
static func title(p: Dictionary) -> String:
	var paragraphs: Array = letter(p).get("paragraphs", [])
	return String(paragraphs[0]) if paragraphs.size() > 1 else ""


static func _helene_source(n: int) -> Variant:
	if n == 23:
		return DialogueCote.PAGE_23   # (read in a scene with Maïa: story/cote_fin.gd)
	return HELENE_SOURCES.get(n, StringName("page_%d" % n))
