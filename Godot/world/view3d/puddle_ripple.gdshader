shader_type spatial;
// The ripples of a puddle, laid flat over its picture: each impact (a heavy step far off) sends a
// train of round waves out from its middle, which spread, weaken and die out before its rim
// (PuddleRipple). Only the waves are drawn: slopes and crests turned to the light shine, the others
// darken; calm water leaves the picture as it is.
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, blend_mix, fog_disabled;

uniform vec4 crest : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 trough : source_color = vec4(0.30, 0.45, 0.68, 1.0);
uniform float impacts[6];         // seconds (PuddleRipple.time) of the last impacts; < 0: none
uniform float now;
uniform float speed = 0.7;        // how fast a wave front runs out (disc radii per second)
uniform float wavelength = 0.22;  // (disc radii)
uniform float train = 2.2;        // how fast the rings fade behind a front (the higher, the fewer)
uniform float decay = 0.9;        // how fast a wave train dies out (per second)
uniform float strength = 1.0;
uniform float shine = 0.85;       // the crests' strongest cover
uniform float shade = 0.55;       // the troughs' strongest cover
uniform sampler2D noise_tex : repeat_enable, filter_linear;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	// The waves die on the rim, a little irregular (a puddle is never a perfect circle).
	float edge = 0.9 + 0.06 * texture(noise_tex, UV * 0.9).r;
	float rim = 1.0 - smoothstep(edge - 0.22, edge, r);
	if (rim <= 0.0) {
		discard;
	}
	vec2 dir = r > 0.0001 ? p / r : vec2(0.0);
	float slope = 0.0;   // the surface's slope along the radius
	float height = 0.0;
	for (int i = 0; i < 6; i++) {
		float dt = now - impacts[i];
		if (impacts[i] < 0.0 || dt < 0.0 || dt > 4.0) {
			continue;
		}
		float behind = dt * speed - r;       // > 0: the train has reached this point
		if (behind < 0.0) {
			continue;
		}
		float env = strength * exp(-decay * dt) * exp(-behind * train) * smoothstep(0.0, 0.05, behind);
		float phase = behind / wavelength * 6.2832;
		height += env * sin(phase);
		slope += env * cos(phase);
	}
	// Light from the upper left: what faces it (and the crests) shines, the rest darkens.
	vec2 light_dir = normalize(vec2(-0.55, -0.83));
	float lit = (0.65 * dot(dir, light_dir) * slope + 0.55 * height) * rim;
	float bright = smoothstep(0.1, 0.9, lit);
	float dark = smoothstep(0.1, 0.9, -lit);
	ALBEDO = bright >= dark ? crest.rgb : trough.rgb;
	ALPHA = max(bright * shine, dark * shade);
}
