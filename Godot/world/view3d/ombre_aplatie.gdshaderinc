// Ombres aplaties (11/10), partie commune : l'image debout (un arbre, une clôture, Chloé, un
// dino…) couchée sur le sol à l'opposé du soleil ; sa silhouette est l'alpha de la même image.
// Le soleil est UN : sa direction, la longueur de l'ombre par mètre de hauteur, sa force (la nuit,
// la pluie, la brume la pâlissent) et sa douceur viennent du global « flat_sun », posé par
// FlatShadows à chaque mise à jour du ciel. Rendu Mobile et Forward+ : rien qui soit réservé à l'un.
// L'ombre MULTIPLIE ce qui est déjà là (blend_mul) : elle l'assombrit, jamais ne l'éclaircit (mêlée
// à une couleur sombre fixe, elle éclaircissait le sol plus sombre qu'elle à l'aube). Sans
// brouillard (fog_disabled) : avec, le brouillard de l'aube (volumétrique) l'effaçait presque.

// xy : où tombe l'ombre d'un point à 1 m du sol (m, plafonné) ; z : force 0..1 ; w : douceur 0..1.
global uniform vec4 flat_sun;

// La teinte de l'ombre pleine : brun-bleu sombre, comme les ombres de contact (la lumière du ciel
// seule), jamais du noir : à l'opacité au pied, le sol garde la moitié de sa lumière.
const vec3 FLAT_TINT = vec3(0.1, 0.09, 0.13);
// L'opacité au pied (force 1, plein soleil) ; le bout est plus pâle. Elle agit sur la lumière
// LINÉAIRE : à 0,75 le sol garde 32 % de sa lumière (FLAT_TINT), ce qui se voit à l'écran (sRGB)
// comme 40 % plus sombre (1 − 0,32^(1/2,2)), le bout vers 25 % — la fourchette voulue (30 à 45 %
// au pied), un peu moins sombre que l'ancienne ombre du soleil (la lumière du ciel seule).
const float FLAT_FOOT_ALPHA = 0.75;

// Ce par quoi multiplier le sol sous une ombre d'opacité `a`.
vec3 flat_darken(float a) {
	return mix(vec3(1.0), FLAT_TINT, clamp(a, 0.0, 1.0));
}
// Une ombre ne va jamais plus loin que ça du pied (m) : un arbre de 8 m au soleil rasant.
const float FLAT_MAX_LENGTH = 9.0;
// Au-dessus du sol (m) : rien. Levée, l'ombre glisserait vers le haut de l'écran et ne partirait
// plus du pied ; c'est FLAT_PULL (le long du regard) qui la garde devant le sol.
const float FLAT_BIAS = 0.0;
// Le quad de l'ombre est plan entre ses coins, le sol ondule : il est avancé vers la caméra de
// tant (m, le long du regard : rien ne bouge à l'écran) pour ne pas s'enfoncer dans les bosses (moins
// sous un personnage : son ombre passerait sur ses propres pieds).
const float FLAT_PULL = 0.25;
const float FLAT_PULL_SPRITE = 0.07;
// Le sol suivi sommet par sommet (une colline, le haut d'une falaise : jusqu'à cet écart avec le
// pied) ; entre deux sommets, là où elle flotterait au-dessus du sol (le bord d'une falaise), elle
// s'efface ; là où elle passerait dessous (le pied d'une paroi), le sol la cache.
const float FLAT_FOLLOW_DOWN = 3.0;
const float FLAT_FOLLOW_UP = 3.0;

// Le relief de la zone (HeightMap.height_texture) et ses hautes herbes (masque des surfaces : G).
uniform bool has_ground = false;
uniform sampler2D height_tex : filter_linear, repeat_disable;
uniform vec2 height_origin = vec2(-10.0);
uniform float height_res = 2.0;
uniform vec2 height_texels = vec2(2.0);
uniform vec2 zone_offset = vec2(0.0);
uniform sampler2D terrain_mask : filter_linear, repeat_disable;
uniform vec2 map_tiles = vec2(1.0);
uniform bool has_grass = false;
// Sur les hautes herbes, l'ombre assombrit les touffes jusqu'à cette hauteur (m), pas seulement la
// terre entre elles (0 : l'ombre des touffes elles-mêmes, des personnages). Elle n'est pas levée
// (son départ glisserait à l'écran) : elle est avancée d'autant le long du regard (flat_pull).
uniform float grass_lift = 0.0;

// Le genre d'objet (ShadowKinds) : force, longueur, flou en plus (m), et « tourne » (1 : l'image
// se tourne face au soleil, un objet rond ; 0 : une planche vue de face, une clôture).
uniform float strength = 1.0;
uniform float length_scale = 1.0;
uniform float blur = 0.0;
uniform float turn = 1.0;
// Le bord adouci par 5 prises (qualité Haute), ou par une seule, plus floue (Moyenne : moins cher).
uniform bool fine = true;

varying float v_along;      // 0 au pied, 1 au sommet de l'image
varying float v_blur;       // flou à cet endroit (m)
varying float v_fade;       // opacité de cette ombre (visibilité, monture, altitude…)
varying vec2 v_ground_xz;   // où l'ombre touche le sol (m)
varying float v_plane;      // hauteur du plan de l'ombre (m)
varying float v_follow;     // 1 : posée sur le relief de la zone (on vérifie qu'elle ne flotte pas)
varying vec2 v_uv_per_m;    // combien d'UV pour un mètre de l'image

float flat_ground(vec2 w) {
	vec2 uv = ((w - zone_offset - height_origin) * height_res + 0.5) / height_texels;
	return textureLod(height_tex, uv, 0.0).r;
}

float flat_grass(vec2 w) {
	return has_grass ? textureLod(terrain_mask, (w - zone_offset) / map_tiles, 0.0).g : 0.0;
}

// Le sol sous un point (m).
float flat_floor(vec2 w) {
	return flat_ground(w);
}

// De combien (m, le long du regard) avancer l'ombre au point `g` : `base` contre les bosses du sol,
// plus de quoi passer devant le bas des touffes d'herbes hautes (un point levé de h se voit à la
// même place qu'un point avancé de h / sin 40°).
float flat_pull(float base, vec2 g) {
	return base + grass_lift * flat_grass(g) * 1.55;
}

// L'axe de la hauteur de l'image couchée au sol (m de sol par m de hauteur), plafonné pour que
// l'image entière (`top` m de haut) tienne dans FLAT_MAX_LENGTH.
vec2 flat_length(float top) {
	vec2 sv = flat_sun.xy * length_scale;
	float reach = length(sv) * max(top, 0.05);
	return sv * min(1.0, FLAT_MAX_LENGTH / max(reach, 0.001));
}

// L'axe de la largeur de l'image au sol : celui de la caméra (une planche), ou tourné en travers
// du soleil (un objet rond : l'ombre a toute sa largeur, d'où que vienne le soleil).
vec2 flat_across(vec2 cam_right, vec2 sv) {
	vec2 u = length(sv) > 0.0001 ? normalize(sv) : vec2(0.0, -1.0);
	vec2 across = vec2(-u.y, u.x);
	if (dot(across, cam_right) < 0.0) {
		across = -across;
	}
	return normalize(mix(cam_right, across, turn));
}

// 1 si l'objet dont le pied est à `foot` est debout sur le relief de la zone (pas un ponton, une
// barque, le haut d'une falaise recalé) : son ombre suit alors le relief, de près.
float flat_on_ground(vec3 foot) {
	return has_ground ? 1.0 - step(0.3, abs(foot.y - flat_ground(foot.xz))) : 0.0;
}

// La hauteur du plan de l'ombre au point `g` du sol (`follow` : flat_on_ground).
float flat_plane(vec3 foot, vec2 g, float follow) {
	float y = foot.y;
	if (follow > 0.5) {
		y = clamp(flat_ground(g), foot.y - FLAT_FOLLOW_DOWN, foot.y + FLAT_FOLLOW_UP);
	}
	return y + FLAT_BIAS;
}

// L'alpha de l'image adouci : 5 prises (au centre, et à `radius` en diagonale), un peu floues,
// sans sortir du rectangle de l'image (une planche de sprites : pas d'image voisine).
float flat_soft_alpha(sampler2D t, vec2 uv, vec2 radius, float lod, vec4 rect) {
	vec2 lo = rect.xy;
	vec2 hi = rect.xy + rect.zw;
	if (!fine) {
		return textureLod(t, clamp(uv, lo, hi), lod + 1.0).a;
	}
	float a = textureLod(t, clamp(uv, lo, hi), lod).a * 0.28;
	a += textureLod(t, clamp(uv + radius, lo, hi), lod).a * 0.18;
	a += textureLod(t, clamp(uv - radius, lo, hi), lod).a * 0.18;
	a += textureLod(t, clamp(uv + vec2(radius.x, -radius.y), lo, hi), lod).a * 0.18;
	a += textureLod(t, clamp(uv + vec2(-radius.x, radius.y), lo, hi), lod).a * 0.18;
	return a;
}

// Ce que l'ombre garde de son opacité : plus pâle vers le bout (`along`, davantage quand elle est
// longue) ; effacée là où le plan flotte au-dessus d'un sol qui descend (`above` m).
float flat_alpha(float silhouette, float along, float fade, float above) {
	float long_shadow = smoothstep(1.0, 2.0, length(flat_sun.xy));
	float tip = mix(1.0, mix(0.8, 0.5, long_shadow), smoothstep(0.0, 1.0, along));
	float a = silhouette * FLAT_FOOT_ALPHA * strength * flat_sun.z * tip * fade;
	return a * (1.0 - smoothstep(0.12, 0.35, above));
}

// Loin de la caméra, là où le brouillard couvre le sol, l'ombre s'efface (elle n'en reçoit pas).
const float FLAT_FADE_FROM = 26.0;
const float FLAT_FADE_TO = 46.0;
float flat_far(vec3 view_position) {
	return 1.0 - smoothstep(FLAT_FADE_FROM, FLAT_FADE_TO, length(view_position));
}

// Le flou (m) : net au pied, plus doux au bout, plus doux quand l'ombre est longue ou le temps couvert.
float flat_blur(float along, float extra) {
	float far = 0.06 + 0.05 * length(flat_sun.xy) + 0.25 * flat_sun.w;
	return mix(0.012, far, along) + blur + extra;
}

// Où l'ombre commence : là où la base DESSINÉE de l'image (`base`, dans le monde : sa dernière ligne
// opaque, au milieu de son pied) paraît toucher le sol à la hauteur `ground`, vue de la caméra `cam`
// (le regard qui passe par elle, prolongé jusqu'au sol). Une base dessinée plus bas que le point au
// sol (des racines, l'avant d'un tronc) ou plus haut (une marge transparente) : l'ombre part quand
// même de ce qu'on voit.
vec2 flat_anchor(vec3 base, float ground, vec3 cam) {
	float t = (cam.y - ground) / max(cam.y - base.y, 0.01);
	return cam.xz + (base.xz - cam.xz) * t;
}

// La position (repère de la caméra) d'un point de l'ombre au sol, avancée vers la caméra (FLAT_PULL).
vec3 flat_view(mat4 view, vec3 world, float pull) {
	vec3 p = (view * vec4(world, 1.0)).xyz;
	return p * max(1.0 - pull / max(length(p), 0.001), 0.05);
}

// Le niveau de mipmap et le rayon des prises (UV) pour un flou de `metres`.
float flat_lod(float metres, vec2 uv_per_m, vec2 size_px, float max_lod) {
	float texels = metres * max(uv_per_m.x * size_px.x, uv_per_m.y * size_px.y);
	return clamp(log2(max(texels * 0.5, 1.0)), 0.0, max_lod);
}
