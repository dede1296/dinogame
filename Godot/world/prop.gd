@tool
class_name Prop
extends StaticBody2D
## A piece of scenery (tree, rock, flowers…). Place it in a region's Entities node and
## pick its `kind` in the Inspector: sprite, shadow, collision and sway come from KINDS.
## The node's origin is where the object touches the ground (for Y-sorting).

const SWAY := preload("res://world/shaders/sway.gdshader")
const ART := "res://assets/art/props/%s.png"

## scale: sprite scale; foot: fraction of the sprite height below the ground point;
## solid: collision radius (float) or box size (Vector2), 0 = walk through;
## sway: sway strength in px (0 = rigid); shadow: shadow width in px (0 = none).
const KINDS := {
	"arbre_rond": {"scale": 0.62, "foot": 0.05, "solid": 16.0, "sway": 1.2, "shadow": 120.0},
	"araucaria": {"scale": 0.62, "foot": 0.03, "solid": 11.0, "sway": 1.5, "shadow": 80.0},
	"fougere_arbre": {"scale": 0.6, "foot": 0.03, "solid": 11.0, "sway": 2.5, "shadow": 90.0},
	"buisson": {"scale": 0.4, "foot": 0.08, "solid": 24.0, "sway": 0.8, "shadow": 96.0},
	"rocher": {"scale": 0.42, "foot": 0.1, "solid": Vector2(96, 34), "sway": 0.0, "shadow": 100.0},
	"cailloux": {"scale": 0.3, "foot": 0.1, "solid": 16.0, "sway": 0.0, "shadow": 50.0},
	"tronc": {"scale": 0.42, "foot": 0.15, "solid": Vector2(104, 30), "sway": 0.0, "shadow": 104.0},
	"ronces": {"scale": 0.34, "foot": 0.05, "solid": 20.0, "sway": 1.5, "shadow": 60.0},
	"hautes_herbes": {"scale": 0.24, "foot": 0.05, "solid": 0.0, "sway": 3.0, "shadow": 0.0},
	"fougeres": {"scale": 0.26, "foot": 0.06, "solid": 0.0, "sway": 3.0, "shadow": 0.0},
	"fleurs_roses": {"scale": 0.2, "foot": 0.06, "solid": 0.0, "sway": 2.0, "shadow": 0.0},
	"fleurs_violettes": {"scale": 0.2, "foot": 0.06, "solid": 0.0, "sway": 2.0, "shadow": 0.0},
	"panneau": {"scale": 0.3, "foot": 0.04, "solid": 8.0, "sway": 0.0, "shadow": 36.0},
	"cloture": {"scale": 0.35, "foot": 0.08, "solid": Vector2(70, 12), "sway": 0.0, "shadow": 0.0},
	"ambre": {"scale": 0.26, "foot": 0.08, "solid": 0.0, "sway": 0.0, "shadow": 22.0},
	"souche": {"scale": 0.3, "foot": 0.12, "solid": 16.0, "sway": 0.0, "shadow": 56.0},
	# Port-Ambre (the buildings' origin is the middle of their facade's foot).
	"maison_blanche": {"scale": 0.62, "foot": 0.02, "solid": Vector2(250, 110), "sway": 0.0, "shadow": 0.0},
	"maison_jaune": {"scale": 0.62, "foot": 0.02, "solid": Vector2(230, 110), "sway": 0.0, "shadow": 0.0},
	"maison_port": {"scale": 0.62, "foot": 0.02, "solid": Vector2(250, 110), "sway": 0.0, "shadow": 0.0},
	"cabinet": {"scale": 0.68, "foot": 0.02, "solid": Vector2(270, 120), "sway": 0.0, "shadow": 0.0},
	"barque": {"scale": 0.55, "foot": 0.12, "solid": 0.0, "sway": 0.0, "shadow": 0.0, "float": true},
	"caisses": {"scale": 0.36, "foot": 0.08, "solid": Vector2(70, 30), "sway": 0.0, "shadow": 80.0},
	"tonneau": {"scale": 0.42, "foot": 0.05, "solid": 18.0, "sway": 0.0, "shadow": 46.0},
	"filet": {"scale": 0.53, "foot": 0.05, "solid": Vector2(100, 16), "sway": 1.0, "shadow": 0.0},
	"bitte": {"scale": 0.36, "foot": 0.08, "solid": 10.0, "sway": 0.0, "shadow": 30.0},
	"lanterne": {"scale": 0.65, "foot": 0.03, "solid": 8.0, "sway": 0.0, "shadow": 30.0, "light": true},
	"casiers": {"scale": 0.45, "foot": 0.08, "solid": Vector2(70, 30), "sway": 0.0, "shadow": 80.0},
	"cordage": {"scale": 0.39, "foot": 0.1, "solid": 0.0, "sway": 0.0, "shadow": 50.0},
	"banc": {"scale": 0.48, "foot": 0.06, "solid": Vector2(76, 16), "sway": 0.0, "shadow": 70.0},
	"sechoir": {"scale": 0.6, "foot": 0.04, "solid": Vector2(80, 12), "sway": 0.6, "shadow": 0.0},
	"ancre": {"scale": 0.42, "foot": 0.08, "solid": 20.0, "sway": 0.0, "shadow": 56.0},
	"bac_fleurs": {"scale": 0.38, "foot": 0.06, "solid": 14.0, "sway": 1.0, "shadow": 40.0},
	# Inside the Cabinet.
	"bureau": {"scale": 0.3, "foot": 0.08, "solid": Vector2(110, 36), "sway": 0.0, "shadow": 110.0},
	"bibliotheque": {"scale": 0.36, "foot": 0.03, "solid": Vector2(90, 24), "sway": 0.0, "shadow": 0.0},
	"couveuse": {"scale": 0.28, "foot": 0.05, "solid": 22.0, "sway": 0.0, "shadow": 60.0, "light": true},
	"fougere_pot": {"scale": 0.22, "foot": 0.05, "solid": 14.0, "sway": 1.5, "shadow": 40.0},
	"lampe": {"scale": 0.3, "foot": 0.03, "solid": 8.0, "sway": 0.0, "shadow": 30.0, "light": true},
	"fauteuil": {"scale": 0.28, "foot": 0.06, "solid": 22.0, "sway": 0.0, "shadow": 56.0},
	"etabli": {"scale": 0.3, "foot": 0.06, "solid": Vector2(80, 26), "sway": 0.0, "shadow": 90.0},
	# Plaines: the amber door, the scales and the Grand Crâne; the Grotte des Échos.
	"porte_ambre": {"scale": 0.33, "foot": 0.01, "solid": Vector2(96, 30), "sway": 0.0, "shadow": 0.0},
	"ecaille": {"scale": 0.15, "foot": 0.05, "solid": 0.0, "sway": 0.0, "shadow": 26.0},
	"serrure": {"scale": 0.15, "foot": 0.05, "solid": 14.0, "sway": 0.0, "shadow": 36.0},
	"stalagmite": {"scale": 0.32, "foot": 0.04, "solid": 16.0, "sway": 0.0, "shadow": 50.0},
	"cristaux": {"scale": 0.18, "foot": 0.08, "solid": 16.0, "sway": 0.0, "shadow": 50.0, "light": true},
	"rocher_grotte": {"scale": 0.24, "foot": 0.08, "solid": 34.0, "sway": 0.0, "shadow": 80.0},
	"grand_crane": {"scale": 0.48, "foot": 0.02, "solid": Vector2(192, 30), "sway": 0.0, "shadow": 0.0},
	"socle": {"scale": 0.32, "foot": 0.06, "solid": 24.0, "sway": 0.0, "shadow": 64.0},
	"mur_cabinet": {"scale": 0.5, "foot": 0.0, "solid": Vector2(171, 60), "sway": 0.0, "shadow": 0.0},
	# Searching the island (provisional pictures: tools/draw-placeholders.mjs).
	"galet": {"scale": 0.11, "foot": 0.12, "solid": 0.0, "sway": 0.0, "shadow": 16.0},
	"monticule": {"scale": 0.26, "foot": 0.12, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
	"etal_fruits": {"scale": 0.5, "foot": 0.03, "solid": Vector2(120, 30), "sway": 0.0, "shadow": 120.0},
	"etal_poisson": {"scale": 0.5, "foot": 0.03, "solid": Vector2(120, 30), "sway": 0.0, "shadow": 120.0},
	"feu_camp": {"scale": 0.25, "foot": 0.07, "solid": 24.0, "sway": 0.0, "shadow": 60.0},
	# Forêt Jurassique.
	"fougere_geante": {"scale": 0.5, "foot": 0.04, "solid": 0.0, "sway": 2.0, "shadow": 110.0},
	"tronc_mousse": {"scale": 0.42, "foot": 0.15, "solid": Vector2(130, 28), "sway": 0.0, "shadow": 140.0},
	"champignons": {"scale": 0.2, "foot": 0.06, "solid": 0.0, "sway": 0.0, "shadow": 24.0},
	"rocher_mousse": {"scale": 0.34, "foot": 0.1, "solid": Vector2(100, 36), "sway": 0.0, "shadow": 108.0},
	"souche_geante": {"scale": 0.3, "foot": 0.12, "solid": 44.0, "sway": 0.0, "shadow": 110.0},
	"arbre_geant": {"scale": 0.47, "foot": 0.04, "solid": 40.0, "sway": 0.0, "shadow": 240.0},
	"os_dino": {"scale": 0.27, "foot": 0.12, "solid": 0.0, "sway": 0.0, "shadow": 0.0},
}

@export_enum("arbre_rond", "araucaria", "fougere_arbre", "buisson", "rocher", "cailloux", "tronc", "ronces",
	"hautes_herbes", "fougeres", "fleurs_roses", "fleurs_violettes", "panneau", "cloture", "ambre", "souche",
	"maison_blanche", "maison_jaune", "maison_port", "cabinet", "barque", "caisses", "tonneau", "filet", "bitte",
	"lanterne", "casiers", "cordage", "banc", "sechoir", "ancre", "bac_fleurs",
	"bureau", "bibliotheque", "couveuse", "fougere_pot", "lampe", "fauteuil", "etabli", "mur_cabinet", "socle",
	"porte_ambre", "ecaille", "serrure", "stalagmite", "cristaux", "rocher_grotte", "grand_crane",
	"galet", "monticule", "feu_camp", "etal_fruits", "etal_poisson",
	"fougere_geante", "tronc_mousse", "champignons", "rocher_mousse", "souche_geante", "arbre_geant", "os_dino")
var kind := "arbre_rond":
	set(value):
		kind = value
		_build()
@export var flip := false:
	set(value):
		flip = value
		_build()
## A tree or a stone hiding an amber pebble: its story flag (see Search).
@export var hidden_pebble: StringName

var sprite: Sprite2D
var _shape: CollisionShape2D
var _shadow: Sprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if not Engine.is_editor_hint():
		Quality.changed.connect(_build)
		# Plain scenery that can be searched (a tree shaken, a stone turned over, a bench).
		if kind == "feu_camp":
			add_to_group(&"fire")   # heard crackling nearby (world.gd, AmbienceDB)
		if get_script() == Prop and Search.can_search(self):
			add_to_group(&"interactable")
			if hidden_pebble != &"" and not Game.flag(hidden_pebble):
				add_to_group(&"secret")
		# Plain scenery with something to say about it (a closed house, a barrel…).
		elif get_script() == Prop and Examine.has(kind):
			add_to_group(&"interactable")
			set_meta(&"reach_bonus", Examine.REACH.get(kind, 10.0))
	_build()


## Searching this piece of scenery, or looking at it (Search, Examine).
func interact(player: Player) -> void:
	if Search.can_search(self):
		await Search.search(self, player)
	else:
		await Examine.look(self, player)


## Still hides an amber pebble (the companion senses it).
func is_hiding() -> bool:
	return hidden_pebble != &"" and not Game.flag(hidden_pebble)


func _build() -> void:
	if not is_inside_tree():
		return
	var def: Dictionary = KINDS.get(kind, {})
	if def.is_empty():
		return
	if sprite == null:
		_shadow = Shadow.make(self)
		sprite = Sprite2D.new()
		add_child(sprite)
		_shape = CollisionShape2D.new()
		add_child(_shape)
	var tex: Texture2D = load(ART % kind)
	sprite.texture = tex
	sprite.scale = Vector2.ONE * def["scale"]
	sprite.flip_h = flip
	var h := tex.get_height()
	sprite.offset = Vector2(0, -h / 2.0 + h * def["foot"])
	if def["sway"] > 0.0 and (Engine.is_editor_hint() or Quality.setting(&"sway_props")):
		var mat := ShaderMaterial.new()
		mat.shader = SWAY
		mat.set_shader_parameter("strength", def["sway"])
		mat.set_shader_parameter("push_strength", def["sway"] * 3.0)
		sprite.material = mat
	else:
		sprite.material = null
	Shadow.fit(_shadow, def["shadow"])
	var solid: Variant = def["solid"]
	if solid is Vector2:
		var box := RectangleShape2D.new()
		box.size = solid
		_shape.shape = box
		_shape.position = Vector2(0, -solid.y / 2.0 + 6)
	elif solid > 0.0:
		var circle := CircleShape2D.new()
		circle.radius = solid
		_shape.shape = circle
		_shape.position = Vector2.ZERO
	_shape.disabled = not (solid is Vector2 or solid > 0.0)
