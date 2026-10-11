class_name PcLight
extends RefCounted
## La lumière du PC : ce que le rendu Forward+ ajoute au monde, et que le téléphone (Mobile) ne sait
## pas faire. Posé par WorldView, jamais obligatoire : sans Forward+ (Android, Compatibilité) ou à
## qualité Moyenne/Basse, rien n'est allumé et le monde reste tel qu'il était.
##
## - Brouillard volumétrique : le soleil, ses ombres portées et l'air. Sous les arbres, la lumière
##   se découpe en rayons, surtout à l'aube et au crépuscule, et dans la brume.
## - Occlusion ambiante (SSAO) : un peu d'ombre au pied des troncs, des rochers et des maisons.
## - Flou de profondeur calé sur la caméra : Chloé et ce qui l'entoure restent nets, le lointain
##   se fond ; dans un gros plan de scène, le fond se défait davantage.
##
## Pourquoi pas Lens Effects (flare et rayons du soleil à l'écran) : la caméra du jeu regarde vers
## le nord, penchée de 40° vers le sol, et le soleil du jeu est TOUJOURS derrière elle (azimuts de
## −60° à +75°) ; l'horizon n'est jamais à l'écran. Il n'y aurait rien à voir.

## La nuit n'a pas de rayons : sous cette énergie de soleil, le brouillard s'éteint.
const SUN_MIN_ENERGY := 0.3
const FOG_LENGTH := 56.0           # jusqu'où le brouillard volumétrique porte (m)
const FOG_BASE := 0.004            # densité en plein jour
const FOG_LOW_SUN := 0.011         # en plus, soleil bas (aube, crépuscule)
const FOG_MIST := 0.03             # en plus, dans la brume
const FOG_ANISOTROPY := 0.25       # la lumière se diffuse un peu vers l'avant
const SSAO_RADIUS := 1.3
const SSAO_INTENSITY := 1.5
## Les ombres du soleil. Le réglage d'origine (une zone de 4,5 m, puis une de 45 m, sur 4096 px) donnait
## aux sprites des ombres en escalier qui vibraient : la zone où l'on joue tombait dans la 2e, étalée sur
## 45 m. Maintenant la 1re zone couvre ce qu'on voit (de la caméra à un peu derrière Chloé) et la
## portée suit la distance de la caméra ; sur PC l'atlas passe à 8192 px (134 Mo de mémoire vidéo).
const SHADOW_ATLAS_PC := 8192
const SHADOW_ATLAS_PHONE := 4096
const SHADOW_RANGE_MARGIN := 14.0   # au-delà de la caméra : ce qu'il faut encore ombrer
const SHADOW_RANGE_MIN := 22.0
const SHADOW_RANGE_MAX := 45.0
const SHADOW_NEAR_SPLIT := 0.5      # la part de la portée couverte par la 1re zone (la plus fine)
## Flou de profondeur : la netteté s'étend jusqu'à la distance de la caméra + cette marge.
const DOF_MARGIN := 13.0
const DOF_BLUR := 0.04
const DOF_BLUR_CLOSE_UP := 0.085   # le fond, plus défait, quand la caméra se rapproche
const DOF_CLOSE_UP_FROM := 9.0     # sous cette distance de caméra, c'est un gros plan


## Vrai si le rendu courant sait faire ces effets (Forward+ : le PC).
static func available() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"


## Pose les ombres du soleil à la résolution du niveau de qualité (`detailed` : ombres sur toute la
## vue, niveau Haute ; sinon une seule zone proche).
static func apply_shadows(sun: DirectionalLight3D, detailed: bool) -> void:
	RenderingServer.directional_shadow_atlas_set_size(SHADOW_ATLAS_PC if Screen.on_computer() else SHADOW_ATLAS_PHONE, true)
	if Screen.on_computer():   # des bords d'ombre plus doux, sans le grain
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if detailed 		else DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_split_1 = SHADOW_NEAR_SPLIT


## La portée des ombres suit la caméra (`shown` : sa distance réelle) : ni plus loin que la vue — où
## chaque pixel d'atlas serait perdu —, ni si près que l'ombre s'arrête devant Chloé.
static func update_shadow_range(sun: DirectionalLight3D, shown: float) -> void:
	sun.directional_shadow_max_distance = clampf(shown + SHADOW_RANGE_MARGIN, SHADOW_RANGE_MIN, SHADOW_RANGE_MAX)


## Allume ou éteint les effets selon la qualité, et pose leurs réglages fixes.
static func apply_quality(env: Environment) -> void:
	var on := available()
	env.ssao_enabled = on and bool(Quality.setting(&"ssao"))
	env.ssao_radius = SSAO_RADIUS
	env.ssao_intensity = SSAO_INTENSITY
	env.volumetric_fog_enabled = on and bool(Quality.setting(&"volumetric_fog"))
	env.volumetric_fog_length = FOG_LENGTH
	env.volumetric_fog_anisotropy = FOG_ANISOTROPY
	env.volumetric_fog_ambient_inject = 0.2
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_temporal_reprojection_enabled = true


## À chaque mise à jour du ciel : l'épaisseur et la teinte de l'air selon l'heure et le temps.
## `low_sun` : 0 soleil haut, 1 soleil rasant ; `mist` : 0 à 1 ; `dim` : 1 normal, 0 plus de soleil.
static func update_fog(env: Environment, sun: DirectionalLight3D, low_sun: float, mist: float, dim: float) -> void:
	if not env.volumetric_fog_enabled:
		return
	var lit := clampf((sun.light_energy - SUN_MIN_ENERGY) / SUN_MIN_ENERGY, 0.0, 1.0) * dim
	env.volumetric_fog_density = (FOG_BASE + FOG_LOW_SUN * low_sun + FOG_MIST * mist) * lit
	env.volumetric_fog_albedo = sun.light_color.lerp(Color.WHITE, 0.35)
	env.volumetric_fog_emission = Color.BLACK


## Le flou de profondeur, calé sur la caméra (`shown` : sa distance réelle, gros plans compris).
static func update_dof(attributes: CameraAttributesPractical, shown: float) -> void:
	if not attributes.dof_blur_far_enabled:
		return
	attributes.dof_blur_far_distance = shown + DOF_MARGIN
	attributes.dof_blur_far_transition = clampf(shown * 1.4, 10.0, 26.0)
	var close := clampf((DOF_CLOSE_UP_FROM - shown) / DOF_CLOSE_UP_FROM, 0.0, 1.0)
	attributes.dof_blur_amount = lerpf(DOF_BLUR, DOF_BLUR_CLOSE_UP, close)
