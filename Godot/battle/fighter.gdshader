// Un combattant, en une seule matière : il respire, il encaisse, il disparaît, et s'il est
// corrompu, l'ambre noir court sous sa peau.
//
// - RESPIRATION (vertex) : dessinés avec peu d'images, les combattants resteraient figés entre
//   deux images. La peinture enfle et retombe autour des pieds (l'origine du sprite), au même
//   rythme que dans l'exploration (world/view3d/sprite_motion.gd). En vertex, donc elle s'ajoute
//   à tous les mouvements du combat (bonds, secousses, collier qui aspire).
// - MOLLESSE (`squash`, `sway`) : la peinture n'est pas rigide. `squash` l'écrase (positif) ou
//   l'étire (négatif) autour des pieds, et l'amorti du ressort est joué par le combat (_jelly) :
//   un coup encaissé écrase puis rebondit, un bond s'étire. `sway` balance le haut du corps
//   (cou, tête) plus que les pieds, comme une gelée posée sur le sol — ce qui donne de la vie à
//   des planches de 3 images sans en redessiner une.
// - COUP ENCAISSÉ (`flash`) : la silhouette vire d'un coup vers la couleur du type de l'attaque,
//   sans écraser les pixels sombres comme le faisait un simple `modulate` multiplié.
// - DISPARITION (`dissolve`) : K.O., capture, rappel — la peinture se consume avec un liseré
//   chaud, au lieu de s'effacer platement. À l'envers (1 → 0), le dino se matérialise.
// - CORRUPTION (`corruption`) : pour les espèces qui n'ont pas de planche corrompue dessinée
//   (assets/art/dinos/<id>_corrompu.png), des veines d'ambre noir qui rampent, et la lumière
//   mangée. Les cinq espèces qui ont leur planche n'en ont pas besoin.
shader_type canvas_item;

// respiration
uniform float amount = 0.012;   // part de la hauteur
uniform float period = 2.6;     // une respiration (s)
uniform float phase = 0.0;      // les deux combattants ne respirent pas ensemble
// mollesse
uniform float squash = 0.0;     // + écrasé, - étiré (joué par le combat, amorti)
uniform float sway = 0.014;     // balancement du haut du corps, part de la hauteur
uniform float body_height = 120.0;   // hauteur de la peinture (px), pour savoir où est le « haut »
// coup encaissé
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
// disparition
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 dissolve_edge : source_color = vec4(1.0, 0.72, 0.28, 1.0);
uniform float dissolve_edge_width : hint_range(0.0, 0.3) = 0.05;
uniform float dissolve_scale = 55.0;
// ambre noir
uniform float corruption : hint_range(0.0, 1.0) = 0.0;
uniform vec4 corruption_color : source_color = vec4(0.32, 0.12, 0.42, 1.0);

float _hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float _noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = _hash(i);
	float b = _hash(i + vec2(1.0, 0.0));
	float c = _hash(i + vec2(0.0, 1.0));
	float d = _hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	float b = sin(TAU * TIME / period + phase) * amount;
	// Plus un point est haut au-dessus des pieds, plus il suit le balancement (0 aux pieds).
	float up = clamp(-VERTEX.y / body_height, 0.0, 1.0);
	VERTEX.x += sin(TAU * TIME / (period * 1.7) + phase + up * 1.5) * sway * body_height * up * up;
	VERTEX.y *= 1.0 + b - squash;
	VERTEX.x *= 1.0 - b * 0.4 + squash * 0.7;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (corruption > 0.0) {
		// Des veines : les lignes où le bruit passe par sa valeur du milieu, qui dérivent lentement.
		float vein = 1.0 - smoothstep(0.0, 0.09, abs(_noise(UV * 16.0 + vec2(0.0, TIME * 0.04)) - 0.5));
		tex.rgb = mix(tex.rgb * (1.0 - 0.25 * corruption), corruption_color.rgb, vein * corruption * 0.8);
	}
	tex.rgb = mix(tex.rgb, flash_color.rgb, flash * tex.a);

	if (dissolve > 0.0) {
		float n = _noise(UV * dissolve_scale);
		if (n < dissolve) {
			discard;
		}
		if (n < dissolve + dissolve_edge_width) {
			tex.rgb = mix(tex.rgb, dissolve_edge.rgb, 0.9);
		}
	}
	COLOR = tex * COLOR;
}
