shader_type canvas_item;
// The island's atlas, with the mist over the regions not visited yet (only the coast shows
// through), and the region under the finger lit up a little.

uniform sampler2D atlas : filter_linear_mipmap;
uniform sampler2D regions : filter_nearest;      // region index * 16 (sea: 255)
uniform float visited[16];
uniform int hover = -1;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 sea : source_color = vec4(0.41, 0.58, 0.65, 1.0);   // the open sea, also around the square

const vec3 MIST = vec3(0.84, 0.82, 0.77);

void fragment() {
	vec3 col = texture(atlas, UV).rgb;
	float raw = texture(regions, UV).r * 255.0;
	int id = int(round(raw / 16.0));
	if (raw < 250.0) {
		float drift = texture(noise_tex, UV * 3.0 + vec2(TIME * 0.004, 0.0)).r;
		if (visited[id] < 0.5) {
			// Mist: the land fades to paper, a hint of relief stays.
			float lum = dot(col, vec3(0.3, 0.55, 0.15));
			col = mix(col, MIST * (0.9 + 0.2 * drift) * (0.85 + 0.25 * lum), 0.86);
		} else if (id == hover) {
			col = mix(col, vec3(1.0, 0.95, 0.8), 0.18);
		}
	}
	// The square's edges melt into the open sea around it (no seam).
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	col = mix(sea.rgb, col, smoothstep(0.0, 0.06, edge));
	COLOR = vec4(col, 1.0);
}
