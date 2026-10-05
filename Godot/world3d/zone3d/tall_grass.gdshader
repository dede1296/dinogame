// Tall grass of the 3D zone (TallGrass3D): one material for every tuft of the field. All the
// movement is here, on the GPU, per vertex, in the world:
// - the wind: waves that roll across the field (the grass bends over in ripples), more with the
//   rain and the storm (`wind_strength`), and a quicker flutter at the blade tips;
// - what walks through: Chloé and the dinos (`pushers`: x, y, z and radius, a radius of 0 = none)
//   part the grass: the blades near them lean away from them and the tips bow down, more the
//   nearer, more the higher up the blade — a trampled hollow round each of them;
// - the cartoon look of the zone (docs/migration-3d.md): a dark foot, light yellow-green tips, a dark
//   edge along each blade (the brown outline of the 2.5D pictures), three soft steps of sun light.
// The foot of a blade never moves (UV.y = 0).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec3 foot_color : source_color = vec3(0.11, 0.30, 0.09);
uniform vec3 mid_color : source_color = vec3(0.27, 0.58, 0.14);
uniform vec3 tip_color : source_color = vec3(0.62, 0.80, 0.26);
uniform vec3 edge_color : source_color = vec3(0.07, 0.15, 0.05);
uniform float wet : hint_range(0.0, 1.0) = 0.0;            // rain: darker, a little bluer
uniform float wind_strength = 1.0;                         // 1: a light breeze
uniform vec2 wind_dir = vec2(0.88, 0.47);
uniform float sway_m = 0.11;                               // the tip's sway at wind 1 (m)
uniform vec4 pushers[12];                                  // xyz: where, w: how far it reaches (m)
uniform float push_m = 0.55;                               // how far a pushed tip leans (m)
uniform float bow_m = 0.38;                                // how far it bows down (m)
uniform float shade_edge = 0.0;
uniform float lit_edge = 0.5;
uniform float mid_level = 0.62;
uniform float lit_level = 0.95;
uniform float softness = 0.1;

varying float v_up;
varying float v_across;
varying float v_tint;
varying vec3 v_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float up = clamp(UV.y, 0.0, 1.0);
	float bend = up * up;                                  // the tip moves most
	vec2 wd = normalize(wind_dir);
	// waves rolling over the field, and a quick flutter on top
	float phase = dot(origin.xz, wd) * 0.28 - TIME * 1.5;
	float wave = 0.55 * sin(phase) + 0.25 * sin(phase * 2.3 + origin.x * 0.35) + 0.35;
	float flutter = sin(TIME * 4.3 + dot(origin.xz, vec2(1.7, 2.3))) * 0.18;
	vec2 sway = wd * (wave * wind_strength + flutter * min(wind_strength, 1.5)) * sway_m * bend;
	vec2 move = sway;
	float bow = 0.0;
	for (int i = 0; i < 12; i++) {
		vec4 p = pushers[i];
		if (p.w > 0.0 && up > 0.08) {
			vec2 d = world.xz - p.xz;
			float dist = length(d);
			float near = 1.0 - smoothstep(p.w * 0.25, p.w, dist);
			move += (d / max(dist, 0.05)) * near * push_m * pow(up, 1.3);
			bow = max(bow, near * bend);
		}
	}
	vec3 shift = vec3(move.x, -bow * bow_m, move.y);
	VERTEX += inverse(mat3(MODEL_MATRIX)) * shift;
	v_up = up;
	v_across = UV.x;
	v_tint = hash(floor(origin.xz * 3.0));
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float t = v_up;
	vec3 col = mix(mix(foot_color, mid_color, smoothstep(0.0, 0.5, t)), tip_color, smoothstep(0.45, 1.0, t));
	// each tuft a little different: a touch yellower or bluer, lighter or darker
	col = mix(col, col.gbr * vec3(1.15, 1.0, 0.8), (v_tint - 0.5) * 0.28);
	col *= 0.9 + 0.2 * v_tint;
	// the dark edge of the blade, thicker low down (like the outline of the 2.5D's pictures)
	float edge = abs(v_across * 2.0 - 1.0);
	col = mix(col, edge_color, smoothstep(0.55, 0.95, edge) * mix(0.9, 0.5, t));
	col = mix(col, col * vec3(0.7, 0.82, 0.92), wet);
	col *= mix(1.0, 0.82, wet);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	// a normal of the clump (leaning out of it), not flipped on the blade's back side
	NORMAL = normalize((VIEW_MATRIX * vec4(v_normal, 0.0)).xyz);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float to_mid = smoothstep(shade_edge - softness, shade_edge + softness, ndl);
	float to_lit = smoothstep(lit_edge - softness, lit_edge + softness, ndl);
	float steps = to_mid * mid_level + to_lit * (lit_level - mid_level);
	float shadow = ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		shadow = smoothstep(0.2, 0.8, ATTENUATION);
	}
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * steps * shadow;
}
