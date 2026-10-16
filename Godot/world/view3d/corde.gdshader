// Les cordes des ponts de lianes (Ropes) : un ruban tourné vers la caméra le long de chaque corde,
// peint comme les cordes dessinées des poteaux (pilier_pont_1, 2) : une torsade ocre dorée, ses brins
// plus sombres, le contour brun des images ; éclairé comme un cylindre (le dessus prend le soleil).
// Ses bouts passent juste derrière l'image du poteau (poussés le long du regard : rien ne bouge à
// l'écran) : l'image les cache, la corde paraît nouée, sans clignoter contre elle.
// Sommets (Ropes._mesh) : VERTEX sur la ligne de la corde (dans le monde), UV = (mètres le long, côté
// ±1), UV2 = (noué 0..1, sol sous ce point), CUSTOM0.xyz = la direction de la corde.
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

uniform float half_width = 0.027;     // m : la corde dessinée des poteaux fait ~5 cm, contour compris
uniform float min_pixels = 1.6;       // jamais plus fine à l'écran (au loin, elle ne scintille pas)
uniform float tie_push = 0.08;        // m derrière l'image du poteau, à ses bouts
uniform float lay = 16.0;             // brins par mètre (le pas de la torsade)
uniform float sway = 0.05;           // m : le balancement au vent, au milieu de la travée (rien aux poteaux)
uniform vec3 fibre : source_color = vec3(0.8, 0.6, 0.37);
uniform vec3 groove : source_color = vec3(0.45, 0.28, 0.19);
uniform vec3 outline : source_color = vec3(0.2, 0.07, 0.08);

varying vec3 v_side;
varying vec3 v_front;

void vertex() {
	vec3 p = VERTEX;
	// Le vent : la corde se balance, d'un côté et un peu en hauteur, nulle là où elle est nouée.
	float free_part = 1.0 - UV2.x;
	float gust = 0.6 * sin(TIME * 1.1 + UV.x * 0.9 + p.x * 0.3) + 0.4 * sin(TIME * 2.3 + UV.x * 1.7 + p.z * 0.5);
	vec3 along = normalize(CUSTOM0.xyz);
	vec3 across = normalize(vec3(-along.z, 0.0, along.x) + vec3(0.0001, 0.0, 0.0));
	p += (across + vec3(0.0, 0.4, 0.0)) * gust * sway * free_part;
	vec3 t = normalize(CUSTOM0.xyz);
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 to_cam = normalize(cam - p);
	vec3 side = cross(t, to_cam);
	side = length(side) > 0.0001 ? normalize(side) : vec3(1.0, 0.0, 0.0);
	// Sa largeur : celle de la corde, au moins `min_pixels` à l'écran.
	float metres_per_px = 2.0 * length(cam - p) / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	float hw = max(half_width, 0.5 * min_pixels * metres_per_px);
	p += side * UV.y * hw;
	p -= to_cam * tie_push * UV2.x;
	v_side = side;
	v_front = normalize(to_cam - t * dot(to_cam, t));
	VERTEX = p;
}

void fragment() {
	float s = UV.y;
	float a = abs(s);
	// La torsade : des brins en biais, leurs creux plus sombres ; trop fins au loin, ils s'effacent.
	float phase = UV.x * lay + s * 0.55;
	float f = fract(phase);
	float w = fwidth(phase);
	float g = 1.0 - smoothstep(0.05, 0.2 + w, min(f, 1.0 - f));
	g *= 1.0 - smoothstep(0.3, 0.7, w);
	vec3 col = mix(fibre, groove, g * 0.75);
	// Le contour brun des images (adouci quand la corde ne fait que quelques pixels).
	float ws = fwidth(s);
	float edge = smoothstep(0.6 - ws, 0.74 + ws, a);
	col = mix(col, outline, edge * mix(1.0, 0.55, smoothstep(0.35, 0.9, ws)));
	// Ronde : la normale tourne d'un bord à l'autre.
	vec3 n = normalize(v_front * sqrt(max(1.0 - s * s * 0.85, 0.0)) + v_side * s * 0.9);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	ALBEDO = col;
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
}
