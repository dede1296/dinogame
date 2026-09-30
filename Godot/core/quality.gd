extends Node
## Graphics quality (autoload "Quality"): one place that says how rich the effects are.
## Scenes never test the level itself; they read a named setting and listen to `changed`:
##     p.amount = Quality.scaled(36, &"particles")
##     Quality.changed.connect(_apply_quality)
## The first launch picks a level from the phone's GPU and memory (`recommended`); the
## player can change it in Paramètres → Graphismes. Stored in user://settings.cfg, apart
## from the game save, so a new game keeps it.

signal changed

enum Level { LOW, MEDIUM, HIGH }

const NAMES := ["Basse", "Moyenne", "Haute"]
const PATH := "user://settings.cfg"

## particles    — multiplier on particle counts (pollen, debris, combat bursts);
## sway_props   — trees, bushes and flowers move in the wind;
## grass_tufts  — tufts per tall-grass cell (the grass sways at every level: it is gameplay);
## clouds       — drifting cloud shadows over the region;
## lights       — glowing lights (amber, pickups);
## water_detail — ripples, glints and foam on water (the colour stays);
## max_fps      — 0 = the display's rate (120 Hz on recent phones), else a cap to save battery;
## shadows      — 0 none, 1 near the camera, 2 everywhere in view;
## render_scale — resolution of the 3D view (the interface stays sharp);
## glow, dof    — light bloom, blur far away;
## ground_step  — ground mesh vertices per metre (finer slopes and cliffs);
## forest_density — trees per forest tile;
## relief_props — the big scenery that has one (houses) as its real 3D model, not its picture.
const PROFILES := {
	Level.LOW: {"particles": 0.35, "sway_props": false, "grass_tufts": 1, "clouds": false,
		"lights": false, "water_detail": false, "max_fps": 60,
		"shadows": 0, "render_scale": 0.7, "glow": false, "dof": false, "ground_step": 2, "forest_density": 0.7,
		"relief_props": false},
	Level.MEDIUM: {"particles": 0.7, "sway_props": true, "grass_tufts": 2, "clouds": true,
		"lights": true, "water_detail": true, "max_fps": 60,
		"shadows": 1, "render_scale": 0.85, "glow": true, "dof": false, "ground_step": 3, "forest_density": 1.0,
		"relief_props": true},
	Level.HIGH: {"particles": 1.0, "sway_props": true, "grass_tufts": 3, "clouds": true,
		"lights": true, "water_detail": true, "max_fps": 0,
		"shadows": 2, "render_scale": 1.0, "glow": true, "dof": true, "ground_step": 4, "forest_density": 1.4,
		"relief_props": true},
}

## In the browser, the big scenery keeps its picture whatever the level: the web game is exported
## without assets/models (export_presets.cfg « Web » exclude_filter), because their atlases and
## normal maps weighed 416 Mo of the 570 Mo of textures — far too much to download, and the
## browser choked on them. The phone (APK) keeps them.
static var WEB := OS.has_feature("web")

var level: Level = Level.HIGH
## What the device detection suggested (shown as « Recommandée » in the settings).
var recommended: Level = Level.HIGH

var _prefs := ConfigFile.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	recommended = detect()
	var saved: int = recommended
	if _prefs.load(PATH) == OK:
		saved = _prefs.get_value("graphics", "quality", recommended)
	level = clampi(saved, Level.LOW, Level.HIGH) as Level
	_apply_engine()


## A setting of the current profile (see PROFILES).
func setting(key: StringName) -> Variant:
	if key == &"relief_props" and WEB:
		return false   # (see WEB: the web game ships without the models)
	return PROFILES[level][key]


## `base` particles scaled by the current profile, never below 1.
func scaled(base: int, key: StringName = &"particles") -> int:
	return maxi(1, roundi(base * float(setting(key))))


func set_level(value: int) -> void:
	value = clampi(value, Level.LOW, Level.HIGH)
	if value == level:
		return
	level = value as Level
	_apply_engine()
	set_pref("graphics", "quality", int(level))
	changed.emit()


## Name shown to the player; -1 = the current level.
## Another player setting kept in settings.cfg (camera distance…).
func pref(section: String, key: String, default: Variant) -> Variant:
	return _prefs.get_value(section, key, default)


## save = false: kept in memory (a slider being dragged); save_prefs() writes it later.
func set_pref(section: String, key: String, value: Variant, save := true) -> void:
	_prefs.set_value(section, key, value)
	if save:
		save_prefs()


func save_prefs() -> void:
	var err := _prefs.save(PATH)
	if err != OK:
		push_error("Réglages non enregistrés (%s)" % error_string(err))


func level_name(value := -1) -> String:
	return NAMES[level if value < 0 else value]


func _apply_engine() -> void:
	Engine.max_fps = setting(&"max_fps")


## Level suggested for this device. Desktop and editor: HIGH. Phones: from the GPU name
## (Adreno / Mali / Immortalis / Xclipse / PowerVR), capped by the memory.
func detect() -> Level:
	if not OS.has_feature("mobile"):
		return Level.MEDIUM if OS.has_feature("web") else Level.HIGH
	var by_gpu := level_for_gpu(RenderingServer.get_video_adapter_name())
	var ram_gb := float(OS.get_memory_info().get("physical", 0)) / 1073741824.0
	if ram_gb > 0.0 and ram_gb < 3.5:
		return Level.LOW
	if ram_gb > 0.0 and ram_gb < 5.5:
		return mini(by_gpu, Level.MEDIUM) as Level
	return by_gpu


## Rough GPU tiers of the last ~7 years of Android phones (static: testable on its own).
static func level_for_gpu(gpu: String) -> Level:
	var name := gpu.to_lower()
	var number := _first_number(name)
	if name.contains("adreno"):
		# 730+ = Snapdragon 8 Gen 1 and later (S25 Ultra: Adreno 830); 640–725 = 855 → 7-series.
		if number >= 730:
			return Level.HIGH
		return Level.MEDIUM if number >= 640 else Level.LOW
	if name.contains("immortalis") or name.contains("xclipse"):
		return Level.HIGH
	if name.contains("mali"):
		# Mali-G710/G715/G720… = recent flagships; G76/G77/G78 = older flagships; G52/G57 = budget.
		if number >= 710:
			return Level.HIGH
		return Level.MEDIUM if number >= 76 else Level.LOW
	if name.contains("powervr"):
		return Level.LOW
	return Level.MEDIUM   # unknown GPU: middle ground, the player can raise it


static func _first_number(text: String) -> int:
	var regex := RegEx.create_from_string("\\d+")
	var m := regex.search(text)
	return int(m.get_string()) if m else 0
