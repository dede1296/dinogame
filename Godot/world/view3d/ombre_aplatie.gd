class_name FlatShadows
extends RefCounted
## Les ombres aplaties (11/10) : chaque image debout du monde (arbre, buisson, rocher, clôture,
## herbe, barque, Chloé, un dino, un PNJ) jette au sol sa propre silhouette, couchée à l'opposé du
## soleil — la technique des jeux 2,5D. Elle remplace, pour les images, l'ombre-carte du soleil
## (DirectionalLight3D), qui donnait des ombres en escalier qui vibraient, et un simple trait sous
## une image fine éclairée de côté. Nette à toute distance (pas d'atlas), stable, elle suit :
## - l'heure : direction et longueur selon l'élévation et l'azimut du soleil (WorldView.DAYLIGHT),
##   plafonnées (FLAT_MAX_LENGTH, K_MAX) ; la nuit, un léger halo sous la lune ;
## - le temps : la pluie, la brume, le sable, la neige la pâlissent et l'adoucissent ;
## - le vent et Chloé qui passe (le même balancement que billboard.gdshader), un arbre fouillé ;
## - l'image COURANTE d'une animation (un dino qui marche), son retournement, sa taille, le saut de
##   pas (SpriteMotion) ; en l'air (le Vol), l'ombre reste au sol, très en dessous.
## Les maisons (modèles 3D), le relief et ce qui n'est pas une image gardent l'ombre-carte du soleil.
## Qualité (Quality « projected_shadows ») : Haute et Moyenne ; Basse n'a que l'ombre de contact.
## Les shaders : ombre_aplatie.gdshader (décors en MultiMesh, une instance d'ombre par paquet),
## ombre_aplatie_sprite.gdshader (images recopiées du 2D, en « material_overlay »). La force de
## chaque genre : shadow_kinds.gd.

const KINDS := preload("res://world/view3d/shadow_kinds.gd")
const PROPS_SHADER := "res://world/view3d/ombre_aplatie.gdshader"
const SPRITE_SHADER := "res://world/view3d/ombre_aplatie_sprite.gdshader"
## Le global des shaders (ombre_aplatie.gdshaderinc « flat_sun ») : xy où tombe l'ombre d'un point à
## 1 m du sol, z sa force, w sa douceur. Créé ici, au lancement : rien à déclarer dans le projet.
const GLOBAL := &"flat_sun"
## La longueur par mètre de hauteur, plafonnée en douceur : 2 au plus (le soleil à 6 h 30 en
## donnerait 4,7).
const K_MAX := 2.0
## Les énergies du soleil de WorldView.DAYLIGHT : la nuit (la lune) et l'aube.
const NIGHT_ENERGY := 0.35
const DAWN_ENERGY := 0.8
## La lune : un léger halo (part de la force du plein jour).
const MOON := 0.22
## Dedans (une lumière d'en haut, diffuse) et sous la mer : plus pâle.
const INDOOR := 0.55
const UNDERWATER := 0.4
const UNDERWATER_SUN := Vector3(-74.0, 18.0, 0.0)   # (Underwater._light)
## Sur les hautes herbes, l'ombre d'un arbre assombrit les touffes jusqu'à cette hauteur (m ; elle
## reste posée au sol, avancée le long du regard : ombre_aplatie.gdshaderinc « flat_pull »).
const GRASS_LIFT := 0.45
## Jusqu'où une ombre peut tomber de son image (m) : FLAT_MAX_LENGTH, et un peu de marge.
const REACH := 10.0
## Une image recopiée du 2D reste dessinée (son ombre) jusqu'à tant hors de la vue (m).
const CULL_MARGIN := 3.0
## Les ombres des décors ne sont plus dessinées au-delà (m de la caméra) : elles s'y sont effacées.
const SHADOW_RANGE := 48.0
## Une ombre de décor qui peut dépasser cette longueur (m) suit le relief rangée par rangée (_twin).
const TWIN_FROM := 1.5
const ROWS := 8

## Les tests forcent les ombres aplaties (1) ou l'ancienne ombre-carte (0) ; -1 : la qualité.
static var forced := -1
static var _global_made := false
## Le bas de ce qui est dessiné, déjà mesuré (picture_bottom), par image ; et par image d'une
## animation (_drawn_bottom : la texture elle-même pour clé, sans refaire de nom à chaque image).
static var _bases := {}
static var _bottoms := {}

## Les ombres aplaties de la zone en cours (décidé à begin_zone, d'après la qualité).
var on := false
var _props_shader: Shader
var _sprite_shader: Shader
var _ground := {}
var _materials := {}                   # matériau d'une image de décor -> celui de son ombre (ou null)
var _twins := {}                       # MultiMesh d'images -> son jumeau en rangées (_twin)
var _rows := {}                        # quad d'une image -> le même, découpé en rangées
var _sun := Vector4(0.0, -0.6, 1.0, 0.0)
var _fine := true                      # des bords adoucis par 5 prises (Haute), sinon une seule
var _eye := Vector3.ZERO               # où est la caméra (mis à jour avec le ciel, à chaque image)
var _mount_shadow := true              # l'ombre de la monture de Chloé se voit (le Vol : pas trop haut)


func _init() -> void:
	make_global()


## Les ombres aplaties sont-elles demandées (qualité, ou forcées par un test) ?
static func enabled() -> bool:
	if forced >= 0:
		return forced == 1
	return bool(Quality.setting(&"projected_shadows"))


## Le global « flat_sun », avant que le premier shader qui le lit ne soit compilé.
static func make_global() -> void:
	if _global_made:
		return
	_global_made = true   # (une fois par lancement : il n'est pas dans les réglages du projet)
	RenderingServer.global_shader_parameter_add(GLOBAL, RenderingServer.GLOBAL_VAR_TYPE_VEC4, Vector4(0.0, -0.6, 1.0, 0.0))


## Ce que vaut le soleil des ombres maintenant (tests) : [direction xy, force, douceur].
func sun_state() -> Vector4:
	return _sun


# ------------------------------------------------------------------ la zone

## Une nouvelle zone : ses ombres selon la qualité, sur son relief `hm` (son sol : `ground_mat`,
## pour ses hautes herbes).
func begin_zone(hm: HeightMap, ground_mat: ShaderMaterial) -> void:
	on = enabled()
	_fine = int(Quality.level) >= 2
	_materials.clear()
	_twins.clear()
	_rows.clear()
	use_ground(hm, ground_mat)


## Le relief sur lequel se posent les ombres des décors bâtis ensuite : celui de la zone (`shift` :
## son décalage, en cases). Les décors d'une voisine montrée au-delà d'un bord prennent aussi celui-ci :
## leurs ombres tombent dans la zone (son relief déborde de HeightMap.MARGIN cases) ; plus loin, une
## ombre ne suit plus le sol et reste à la hauteur de son pied.
func use_ground(hm: HeightMap, ground_mat: ShaderMaterial = null, shift := Vector2.ZERO) -> void:
	_ground = {}
	if hm == null:
		return
	var tex := hm.height_texture()
	_ground = {"has_ground": true, "height_tex": tex["texture"], "height_origin": tex["origin"],
		"height_res": tex["res"], "height_texels": tex["texels"], "zone_offset": shift}
	var mask: Texture2D = ground_mat.get_shader_parameter("terrain_mask") if ground_mat else null
	if mask:
		_ground["terrain_mask"] = mask
		_ground["map_tiles"] = ground_mat.get_shader_parameter("map_tiles")
		_ground["has_grass"] = true


## Les billboards projettent-ils encore l'ombre-carte du soleil ? (Pas quand leur ombre aplatie
## la remplace : elle doublerait.)
func map_shadows_for_pictures() -> bool:
	return not on


# ------------------------------------------------------------------ les décors (MultiMesh)

## L'ombre d'un paquet de décors `inst` (des images de genre `kind`, WorldView._add_multimesh) :
## une instance posée à côté dans `parent`, sur le même MultiMesh — ou, pour une ombre qui peut
## être longue, sur son jumeau découpé en rangées (TWIN_FROM) pour épouser le relief.
func add_chunk(parent: Node3D, inst: MultiMeshInstance3D, kind: String) -> void:
	if not on or inst.multimesh == null:
		return
	var quad := inst.multimesh.mesh as QuadMesh
	if quad == null or not quad.material is ShaderMaterial:
		return
	var mat := _props_material(kind, quad)
	if mat == null:
		return
	var shadow := MultiMeshInstance3D.new()
	shadow.name = "OmbreAplatie"
	var longest := float(mat.get_shader_parameter("top_m")) * 1.4 * K_MAX * float(mat.get_shader_parameter("length_scale"))
	shadow.multimesh = _twin(inst.multimesh, quad) if longest > TWIN_FROM else inst.multimesh
	shadow.set_meta(&"picture", inst)
	shadow.material_override = mat
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var box := inst.custom_aabb
	shadow.custom_aabb = AABB(box.position - Vector3(REACH, 0.5, REACH), box.size + Vector3(REACH * 2.0, 1.0, REACH * 2.0))
	# Pas plus loin que là où elle s'efface (ombre_aplatie.gdshaderinc FLAT_FADE_TO) : autant
	# d'appels de dessin en moins.
	shadow.visibility_range_end = SHADOW_RANGE
	shadow.visibility_range_end_margin = 0.0
	shadow.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	parent.add_child(shadow)


## Le jumeau d'un MultiMesh de décors : les mêmes places, retournés, tailles (une copie de ses
## données), sur un quad découpé en ROWS rangées. (Un quad de 4 sommets, plan, s'enfonçait dans une
## colline sur une ombre de plusieurs mètres.) WorldView.nudge le tient à jour (mirror).
func _twin(source: MultiMesh, quad: QuadMesh) -> MultiMesh:
	if not _rows.has(quad):
		var rows := QuadMesh.new()
		rows.size = quad.size
		rows.center_offset = quad.center_offset
		rows.subdivide_depth = ROWS - 1
		_rows[quad] = rows
	var twin := MultiMesh.new()
	twin.transform_format = MultiMesh.TRANSFORM_3D
	twin.use_custom_data = true
	twin.mesh = _rows[quad]
	twin.instance_count = source.instance_count
	twin.buffer = source.buffer
	_twins[source] = twin
	return twin


## Un décor secoué ou soulevé (WorldView.nudge) : son ombre aussi, sur le jumeau de son paquet.
func mirror(mm: MultiMesh, index: int, data: Color) -> void:
	var twin: MultiMesh = _twins.get(mm)
	if twin:
		twin.set_instance_custom_data(index, data)


## Le matériau d'ombre des images faites avec `quad` (un par genre et par zone, partagé par ses
## paquets) ; null : ce genre n'a pas d'ombre.
func _props_material(kind: String, quad: QuadMesh) -> ShaderMaterial:
	var source := quad.material as ShaderMaterial
	var key := source.get_instance_id()
	if _materials.has(key):
		return _materials[key]
	var tex := source.get_shader_parameter("tex") as Texture2D
	var spec := KINDS.for_kind(kind, tex.get_size() if tex else Vector2.ONE)
	if tex == null or float(spec["strength"]) <= 0.0:
		_materials[key] = null
		return null
	if _props_shader == null:
		_props_shader = load(PROPS_SHADER)
	var mat := ShaderMaterial.new()
	mat.shader = _props_shader
	mat.set_shader_parameter("tex", tex)
	for param in ["stretch", "sway", "push", "push_radius", "stiffness"]:
		var value: Variant = source.get_shader_parameter(param)
		if value != null:
			mat.set_shader_parameter(param, value)
	var top := quad.size.y / 2.0 + quad.center_offset.y
	var per_px := quad.size.y / maxf(tex.get_height(), 1.0)
	mat.set_shader_parameter("top_m", top)
	mat.set_shader_parameter("texel_m", per_px)
	# Sa base dessinée, par rapport à son point au sol : l'ombre part de sa dernière ligne opaque (pas
	# du bas de l'image), au droit de son point au sol (le milieu de son pied par construction : un
	# caillou au coin d'un rocher, plus bas que lui, ne doit pas faire tourner l'ombre autour de lui).
	mat.set_shader_parameter("base", Vector2(0.0, top - picture_bottom(tex) * per_px))
	_dress(mat, spec)
	_materials[key] = mat
	return mat


## Le genre (force, longueur, flou, tournée ou pas) et le sol, sur un matériau d'ombre.
func _dress(mat: ShaderMaterial, spec: Dictionary) -> void:
	mat.set_shader_parameter("strength", spec["strength"])
	mat.set_shader_parameter("length_scale", spec["length"])
	mat.set_shader_parameter("blur", spec["blur"])
	mat.set_shader_parameter("turn", spec["turn"])
	for key: String in _ground:
		mat.set_shader_parameter(key, _ground[key])
	mat.set_shader_parameter("fine", _fine)
	mat.set_shader_parameter("grass_lift", GRASS_LIFT if spec["grass"] and _ground.get("has_grass", false) else 0.0)


# ------------------------------------------------------------------ les images recopiées du 2D

## Un nœud recopié en image (WorldView._track : `p` est son « proxy ») : son ombre aplatie, posée
## sur son Sprite3D.
func track(p: Dictionary) -> void:
	var vis := p["vis"] as SpriteBase3D
	if not on or vis == null:
		return
	var src: Node = p["src"]
	var spec: Dictionary
	if src is Prop:
		var picture := (p["sprite"] as Sprite2D).texture if p["sprite"] is Sprite2D else null
		spec = KINDS.for_kind(String((src as Prop).kind), picture.get_size() if picture else Vector2.ONE)
	else:
		spec = KINDS.for_kind(KINDS.CHARACTER)
	if float(spec["strength"]) <= 0.0:
		return
	if _sprite_shader == null:
		_sprite_shader = load(SPRITE_SHADER)
	var mat := ShaderMaterial.new()
	mat.shader = _sprite_shader
	_dress(mat, spec)
	vis.material_overlay = mat
	# (L'image juste hors de la vue, son ombre dedans : on la dessine. Pas plus large : chaque image
	# gardée hors de la vue coûte, mesuré 0,5 ms par image d'écran avec 10 m.)
	vis.extra_cull_margin = CULL_MARGIN
	p["flat"] = mat
	p["flat_atlas"] = null
	p["flat_last"] = {}


## Chaque image : l'ombre de l'image courante, sous les pieds (`at` : la place 2D), cachée quand
## l'image nage ou plonge (`hidden`).
func sync(p: Dictionary, at: Vector2, heights: HeightMap, hidden: bool) -> void:
	var mat: ShaderMaterial = p.get("flat")
	if mat == null:
		return
	var vis := p["vis"] as SpriteBase3D
	# (Cachée, ou trop loin de la caméra pour que son ombre se voie : rien à faire. Un dino sauvage
	# qui erre au loin coûtait autant qu'un tout proche.)
	if not vis.visible or vis.global_position.distance_squared_to(_eye) > SHADOW_RANGE * SHADOW_RANGE:
		return
	var frame := _frame(vis)
	var src: Node = p["src"]
	var shown := not hidden and frame != null and _shadow_shown(p)
	# Rien n'a bougé depuis l'image d'avant (un objet posé, un PNJ immobile) : rien à refaire.
	var sig := [frame, shown, at, vis.global_position, vis.scale, vis.offset, vis.pixel_size]
	if sig == p.get("flat_sig"):
		return
	p["flat_sig"] = sig
	if not shown:
		_give(p, vis, &"look", Vector4(0.0, 0.0, 0.0, -1.0))
		return
	var atlas := frame
	var region := Rect2(Vector2.ZERO, frame.get_size())
	if frame is AtlasTexture and (frame as AtlasTexture).atlas:
		atlas = (frame as AtlasTexture).atlas
		region = (frame as AtlasTexture).region
	if atlas != p["flat_atlas"]:
		p["flat_atlas"] = atlas
		mat.set_shader_parameter("tex", atlas)
	var sheet := atlas.get_size()
	var pivot := heights.to_3d(at)
	if src is Prop and Prop.KINDS.get((src as Prop).kind, {}).get("float", false):
		pivot.y = maxf(pivot.y, HeightMap.WATER_LEVEL + 0.06)
	# Ses pieds dessinés dans l'image courante, par rapport à l'origine du nœud (au droit de celle-ci,
	# le milieu de ses pieds par construction ; à la hauteur de sa dernière ligne dessinée), le haut
	# de l'image au-dessus du sol (m), et sa hauteur en l'air (le Vol : l'ombre pâlit et se floute).
	var size := frame.get_size()
	var per_px := vis.pixel_size * vis.scale.y
	var base := Vector2(vis.offset.x * vis.pixel_size * vis.scale.x, (size.y / 2.0 - _drawn_bottom(frame) + vis.offset.y) * per_px)
	var above := vis.global_position.y - pivot.y
	# (Trois valeurs par image, pour trois appels au plus quand elle bouge : où, quelle image, comment.)
	_give(p, vis, &"ground", Vector4(pivot.x, pivot.y, pivot.z, above + (size.y / 2.0 + vis.offset.y) * per_px))
	_give(p, vis, &"uv_rect", Vector4(region.position.x / sheet.x, region.position.y / sheet.y, region.size.x / sheet.x, region.size.y / sheet.y))
	_give(p, vis, &"look", Vector4(base.x, base.y, vis.pixel_size * vis.scale.x, maxf(0.0, above + base.y)))
	# Chloé en selle : son ombre après celle de sa monture, qui passe la première (le gabarit :
	# une seule ombre pour les deux).
	var rider := src is Player and (src as Player).carried_by() != null
	var priority := 1 if rider else 0
	if mat.render_priority != priority:
		mat.render_priority = priority


## Une valeur par image donnée au shader, seulement quand elle change.
func _give(p: Dictionary, vis: SpriteBase3D, key: StringName, value: Variant) -> void:
	var last: Dictionary = p["flat_last"]
	if last.get(key) == value:
		return
	last[key] = value
	vis.set_instance_shader_parameter(key, value)


## Le bas des pieds dessinés de `frame` (px depuis son haut : sous sa dernière ligne dessinée) : une
## image d'une planche (SheetFrames, mesurée d'un coup), ou une image entière (picture_bottom).
static func _drawn_bottom(frame: Texture2D) -> float:
	var known: Variant = _bottoms.get(frame)
	if known != null:
		return known
	var bottom := SheetFrames.drawn_in(frame).end.y if frame is AtlasTexture and (frame as AtlasTexture).atlas 		else picture_bottom(frame)
	_bottoms[frame] = bottom
	return bottom


## Le bas de ce qui est dessiné dans une image entière (px depuis son haut : sous sa dernière ligne
## opaque, alpha > 0,5) — là où elle touche le sol. Mesuré une fois par image.
static func picture_bottom(tex: Texture2D) -> float:
	var key := tex.resource_path if tex.resource_path != "" else str(tex.get_instance_id())
	if _bases.has(key):
		return _bases[key]
	var bottom := tex.get_size().y
	var img := tex.get_image()
	if img and (not img.is_compressed() or img.decompress() == OK):
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		var data := img.get_data()
		var found := false
		for y in range(h - 1, -1, -1):
			for x in range(0, w, 2):
				if data[(y * w + x) * 4 + 3] > 127:
					found = true
					break
			if found:
				bottom = (y + 1) * tex.get_size().y / h   # (une image importée plus petite que son dessin)
				break
	_bases[key] = bottom
	return bottom


## L'image affichée maintenant par `vis` (celle de l'animation en cours).
static func _frame(vis: SpriteBase3D) -> Texture2D:
	if vis is AnimatedSprite3D:
		var anim := vis as AnimatedSprite3D
		if anim.sprite_frames == null or not anim.sprite_frames.has_animation(anim.animation):
			return null
		return anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	return (vis as Sprite3D).texture if vis is Sprite3D else null


## L'ombre d'un personnage se voit quand son ombre de contact se voit (le jeu la cache en l'air
## trop haut, au-dessus de l'eau…) ; Chloé en selle : comme celle de sa monture.
func _shadow_shown(p: Dictionary) -> bool:
	var src: Node = p["src"]
	if src is Prop:
		return true
	var shadow_2d = p.get("foot_2d")   # (non typé : il a pu être libéré)
	var own := not is_instance_valid(shadow_2d) or (shadow_2d as CanvasItem).visible
	if src is Companion and (src as Companion).carrying():
		_mount_shadow = own
		return own
	if src is Player and (src as Player).carried_by() != null:
		return _mount_shadow
	return own


# ------------------------------------------------------------------ le soleil

## À chaque mise à jour du ciel (WorldView._update_sky, _indoor_light) : la direction du soleil
## (ou de la lune), et ce que le temps laisse de l'ombre. `clear_energy` : l'énergie qu'aurait le
## soleil par temps clair à cette heure (la nuit : celle de la lune) ; le reste vient du temps.
func update_sky(sun: DirectionalLight3D, clear_energy: float, indoor := false, underwater := false) -> void:
	var dir := sun.global_transform.basis.z
	if underwater:
		dir = Basis.from_euler(UNDERWATER_SUN * PI / 180.0).z
	var up := maxf(dir.y, 0.1)
	var sv := Vector2(-dir.x, -dir.z) / up
	var k := sv.length()
	if k > 0.0001:
		sv *= K_MAX * tanh(k / K_MAX) / k
	var day := smoothstep(NIGHT_ENERGY, DAWN_ENERGY, clear_energy)
	var weather := clampf(sun.light_energy / maxf(clear_energy, 0.01), 0.0, 1.0)
	var strength := lerpf(MOON, 1.0, day) * weather
	if indoor:
		strength *= INDOOR
	if underwater:
		strength *= UNDERWATER
	var soft := clampf((1.0 - weather) * 0.9 + (1.0 - day) * 0.5, 0.0, 1.0)
	_sun = Vector4(sv.x, sv.y, strength, soft)
	RenderingServer.global_shader_parameter_set(GLOBAL, _sun)
	var camera := sun.get_viewport().get_camera_3d() if sun.is_inside_tree() else null
	if camera:
		_eye = camera.global_position
