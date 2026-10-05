class_name NpcDialogue
extends RefCounted
## What a 3D NPC says, through the game's own dialogue box (the autoload `Dialogue` and `DialogueDB`,
## both unchanged): the 2.5D's rule, minus what the 3D cannot play yet.
## - `dialogue_id` set: those lines, chosen by the story flags as always (DialogueDB.lines).
## - `event` set (a story scene, story/story.gd): the scene itself needs Stage on 3D actors, which
##   is a later step of docs/migration-3d.md. Until then, when DialogueDB holds lines under the
##   same name — which most scenes open with (Maïa: PlainesAnnexes.maia says DialogueDB.lines(&"maia"))
##   — the NPC says those; the choreography around them waits for Stage 3D.
## - Nothing of either: the 2.5D's own greeting.
##
## Asking DialogueDB for an id it does not know prints an error, so the ids it holds are listed once,
## from the `match` of the dialogue scripts themselves (nothing copied by hand). A build whose
## scripts carry no source (an exported game) lists nothing: those NPCs then greet.

const SCRIPTS := [
	"res://data/dialogue_db.gd", "res://data/dialogue_cote.gd",
	"res://data/dialogue_desert.gd", "res://data/dialogue_monts.gd",
]
## A line of a `match` listing dialogue ids: two tabs, one or more &"id", then a colon.
const CASE_LINE := "^\\t\\t&\"[a-z0-9_]+\"(\\s*,\\s*&\"[a-z0-9_]+\")*\\s*:\\s*$"
const ID_IN_LINE := "&\"([a-z0-9_]+)\""

static var _known: Dictionary = {}


## Does DialogueDB hold lines under this id?
static func knows(id: StringName) -> bool:
	if _known.is_empty():
		_index()
	return _known.has(id)


## What `data` (an entry of NpcSource.read) says when Chloé talks to them, in the game's own format
## ([{who, text}…], flags and text_fn included).
static func lines_for(data: Dictionary) -> Array:
	var dialogue_id: StringName = data.get("dialogue_id", &"")
	if dialogue_id != &"" and knows(dialogue_id):
		return DialogueDB.lines(dialogue_id)
	var event: StringName = data.get("event", &"")
	if event != &"" and knows(event):
		return DialogueDB.lines(event)
	return [{"who": data.get("display_name", ""), "text": "Oh, bonjour Chloé !"}]


## Lists the ids of the dialogue scripts, once. Their source is read, not run: asking for an
## unknown id would print an error, and there is no other way to ask.
static func _index() -> void:
	var cases := RegEx.create_from_string(CASE_LINE)
	var ids := RegEx.create_from_string(ID_IN_LINE)
	for path: String in SCRIPTS:
		if not ResourceLoader.exists(path):
			continue
		var source := (load(path) as GDScript).source_code
		for line in source.split("\n"):
			if cases.search(line) == null:
				continue
			for found in ids.search_all(line):
				_known[StringName(found.get_string(1))] = true
	if _known.is_empty():
		_known[&""] = true   # (looked for once, even when nothing was found: an exported game)
