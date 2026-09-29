shader_type canvas_item;
// The zone map, drawn like an explorer's map: the ground by colour, the relief by shading
// and contour lines, woods as little crowns; old blank paper where Chloé has not been.
// It reads the same masks and height texture as the 3D ground (and its snow: the cover layer).

uniform sampler2D terrain_mask : filter_linear, repeat_disable;    // R path, G tall grass, B water
uniform sampler2D terrain_mask2 : filter_linear, repeat_disable;   // R sand, G forest, B mud, A rock
uniform sampler2D height_tex : filter_linear, repeat_disable;
uniform vec2 height_origin = vec2(-10.0);
uniform float height_res = 2.0;
uniform vec2 height_texels = vec2(2.0);
uniform vec2 map_tiles = vec2(40.0, 26.0);
uniform sampler2D fog : filter_linear, repeat_disable;             // what has been seen
uniform vec2 fog_scale = vec2(1.0);
uniform sampler2D noise_tex : repeat_enable, filter_linear;
// A cold zone's "sand" is ice. Its snow (and other layers: Region.covers()) laid over the ground
// as on the 3D ground: their doses in cover_mask's R, G, B, each in its own colour.
uniform bool icy = false;
uniform int cover_count = 0;
uniform sampler2D cover_mask : filter_linear, repeat_disable;
uniform vec3 cover_colours[3];

const vec3 GRASS = vec3(0.62, 0.74, 0.44);
const vec3 TALL = vec3(0.50, 0.64, 0.33);
const vec3 PATH = vec3(0.87, 0.74, 0.52);
const vec3 SAND = vec3(0.93, 0.86, 0.65);
const vec3 FOREST = vec3(0.36, 0.53, 0.32);
const vec3 MUD = vec3(0.55, 0.52, 0.36);
const vec3 CANYON = vec3(0.80, 0.58, 0.42);
const vec3 WATER = vec3(0.45, 0.66, 0.80);
const vec3 SHORE = vec3(0.22, 0.36, 0.48);
const vec3 ROCK = vec3(0.68, 0.59, 0.47);
const vec3 ICE = vec3(0.72, 0.86, 0.93);
const vec3 INK = vec3(0.36, 0.27, 0.18);
const vec3 PAPER = vec3(0.90, 0.83, 0.67);
const vec3 EDGE = vec3(0.60, 0.46, 0.28);
const float CONTOUR = 1.2;   // metres between contour lines

float h_at(vec2 t) {
	return textureLod(height_tex, ((t - height_origin) * height_res + 0.5) / height_texels, 0.0).r;
}

void fragment() {
	vec2 t = UV * map_tiles;
	vec4 m = texture(terrain_mask, UV);
	vec4 m2 = texture(terrain_mask2, UV);
	float h = h_at(t);
	float e = 0.35;
	float dx = h_at(t + vec2(e, 0.0)) - h_at(t - vec2(e, 0.0));
	float dz = h_at(t + vec2(0.0, e)) - h_at(t - vec2(0.0, e));
	vec3 n = normalize(vec3(-dx, 2.0 * e, -dz));
	float light = clamp(dot(n, normalize(vec3(-0.5, 0.9, -0.6))), 0.0, 1.0);
	float slope = length(vec2(dx, dz)) / (2.0 * e);
	float crowns = texture(noise_tex, t * 0.45).r;
	float grain = texture(noise_tex, UV * 23.0).r;

	vec3 col = mix(GRASS, TALL, m.g);
	col = mix(col, icy ? ICE : SAND, m2.r);
	col = mix(col, FOREST, m2.g);
	col = mix(col, MUD, m2.b);
	col = mix(col, CANYON, m2.a);
	col = mix(col, PATH, smoothstep(0.3, 0.6, m.r));
	vec3 doses = texture(cover_mask, UV).rgb;
	for (int i = 0; i < cover_count; i++) {
		float laid = smoothstep(0.4, 0.6, doses[i] + (grain - 0.5) * 0.3);
		col = mix(col, mix(cover_colours[i], PATH * 1.12, smoothstep(0.3, 0.6, m.r) * 0.35), laid * (icy ? 1.0 - m2.r : 1.0));
	}
	// Higher ground a little paler; cliffs and steep slopes in bare rock.
	col += vec3(0.06, 0.05, 0.02) * clamp(h / 8.0, 0.0, 1.0);
	col = mix(col, ROCK, smoothstep(0.9, 2.2, slope));
	// Relief, lit from the north-west as on old maps.
	col *= 0.62 + 0.5 * light;
	// Woods: crowns drawn close together.
	col = mix(col, col * 0.7, m2.g * smoothstep(0.5, 0.62, crowns));
	// Contour lines on the heights (not on the flat meadows, where they would only wander).
	float level = h / CONTOUR;
	float contour = 1.0 - smoothstep(0.0, 1.3 * fwidth(level), abs(fract(level + 0.5) - 0.5));
	col = mix(col, INK, contour * 0.4 * smoothstep(0.6, 1.0, h));
	// Water, and a drawn line along its shore.
	col = mix(col, WATER * (0.95 + 0.1 * crowns), smoothstep(0.35, 0.6, m.b));
	float shore = 1.0 - smoothstep(0.0, 1.5 * fwidth(m.b), abs(m.b - 0.5));
	col = mix(col, SHORE, shore * 0.6);
	col *= 0.95 + 0.08 * grain;

	// Not seen yet: blank paper, with a burnt-looking edge where the drawing stops.
	float wobble = (texture(noise_tex, t * 0.3).r - 0.5) * 0.35;
	float seen = smoothstep(0.35, 0.65, texture(fog, UV * fog_scale).r + wobble);
	float edge = smoothstep(0.0, 0.5, seen) * (1.0 - smoothstep(0.5, 1.0, seen));
	col = mix(PAPER * (0.93 + 0.1 * grain), col, seen);
	col = mix(col, EDGE, edge * 0.45);
	COLOR = vec4(col, 1.0);
}
