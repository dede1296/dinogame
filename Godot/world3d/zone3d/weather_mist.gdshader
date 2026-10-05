// The veil of the mist (WeatherMist): a screen-wide pass, drawn after everything, that lays a pale
// mist over what the camera sees — thick near the ground, thinning with height, in drifting banks
// (so the grass of a meadow disappears into it and the trees stand above it), with a glow towards
// the sun. For each pixel it walks a short way along the ray, from the camera to the first thing
// it hits (the depth buffer), adding up the mist it crosses; the more it crosses, the more the
// pixel turns to the colour of the mist. A handful of steps, with a dither so they do not show.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, blend_mix;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform float amount : hint_range(0.0, 1.0) = 1.0;       // how thick the mist is now
uniform vec3 mist_color : source_color = vec3(0.78, 0.82, 0.86);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);              // towards the sun
uniform float sun_glow = 0.5;
uniform float ground_y = 0.0;                             // where the mist lies thickest (m)
uniform float scale_height = 2.0;                         // how fast it thins going up (m)
uniform float density = 0.085;                            // per metre, at the ground, in the thick of a bank
uniform float max_dist = 90.0;                            // beyond this the fog of the environment takes over
uniform vec2 drift = vec2(0.5, 0.2);                      // the banks' drift (m/s)
uniform float bank_scale = 0.045;                         // 1 / metres of a bank
const int STEPS = 4;

float bank(vec2 p) {
	float a = texture(noise_tex, p * bank_scale).r;
	float b = texture(noise_tex, p * bank_scale * 2.3 + vec2(0.37, 0.11)).r;
	return smoothstep(0.25, 0.85, a * 0.7 + b * 0.3);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = textureLod(depth_tex, SCREEN_UV, 0.0).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	view.xyz /= view.w;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 hit = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	vec3 ray = hit - cam;
	float reach = min(length(ray), max_dist);
	vec3 dir = normalize(ray);
	float dither = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	float tau = 0.0;
	float step_len = reach / float(STEPS);
	for (int i = 0; i < STEPS; i++) {
		float t = (float(i) + dither) * step_len;
		vec3 p = cam + dir * t;
		float high = max(p.y - ground_y, 0.0);
		float body = exp(-high / scale_height);
		tau += density * body * (0.25 + 1.1 * bank(p.xz + drift * TIME)) * step_len;
	}
	float veil = (1.0 - exp(-tau * amount)) * amount;
	float glow = pow(max(dot(dir, normalize(sun_dir)), 0.0), 5.0) * sun_glow;
	ALBEDO = mist_color * (1.0 + glow);
	ALPHA = clamp(veil, 0.0, 0.92);
}
