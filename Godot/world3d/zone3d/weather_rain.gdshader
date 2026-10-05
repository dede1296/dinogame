// Rain streaks falling around Chloé (WeatherRain). One MultiMesh of upright quads whose positions are
// all worked out here, on the GPU: each drop is a column anchored in the WORLD (it does not follow
// Chloé: the box of rain wraps round her as she walks), falling from `drop_height` above the ground
// of that very spot (read from the zone's height map) down to it, then starting again. So rain
// reaches the ground on a slope, a terrace or a pond, with nothing computed on the CPU.
// The streak is a thin quad that turns to face the camera along its own axis (a cylindrical
// billboard), lying along the fall (slanted by the wind), brightest at its head, fading to its tail.
// Per instance (INSTANCE_CUSTOM): x, y = where the column is in the box (0..1), z = phase of its fall
// and its speed jitter (0..1), w = its rank (0..1): it only shows while `density` is above it.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform sampler2D height_tex : filter_linear, repeat_disable;   // R: ground (or water) height, one texel per metre
uniform vec2 height_origin = vec2(0.0);   // world x, z of the first texel (m)
uniform vec2 height_size = vec2(1.0);     // texels (= metres) along x and z
uniform sampler2D cover_tex : filter_linear, repeat_disable;   // R: under a tree's crown (0–1), G: how high it reaches (m / 16)
uniform vec3 center = vec3(0.0);          // the middle of the box of rain (Chloé)
uniform float box = 30.0;                 // its side (m)
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float fall_speed = 13.0;          // m/s
uniform float drop_height = 11.0;         // where a drop starts above the ground (m)
uniform vec2 wind = vec2(2.0, 0.6);       // how the wind carries the drops sideways (m/s)
uniform float streak_length = 0.85;       // m
uniform float streak_width = 0.032;       // m
uniform vec4 color : source_color = vec4(0.86, 0.93, 1.0, 0.8);

varying float v_fade;

void vertex() {
	vec4 c = INSTANCE_CUSTOM;
	float half_box = box * 0.5;
	// the column nearest to the centre of the box, whichever copy of the pattern (it repeats every `box`)
	vec2 rel = mod(c.xy * box - center.xz + vec2(half_box), vec2(box)) - vec2(half_box);
	vec2 land = center.xz + rel;
	float ground = textureLod(height_tex, (land - height_origin + vec2(0.5)) / height_size, 0.0).r;
	// where the drop is on its fall: 1 at its start, 0 at the ground
	float speed = fall_speed * (0.88 + 0.24 * fract(c.z * 7.31));
	float t = fract(c.z - TIME * speed / drop_height);
	float above = t * drop_height;
	vec3 fall = vec3(wind.x, -speed, wind.y);      // velocity
	vec3 up = normalize(-fall);                     // along the streak, towards its tail
	vec3 head = vec3(land.x, ground + above, land.y) + vec3(-wind.x, 0.0, -wind.y) * (above / speed);
	// a streak that has reached the ground is gone for that instant (the splash takes over)
	// under a crown the rain stops: nothing below the height of the leaves, where a tree stands
	vec2 shelter = textureLod(cover_tex, (head.xz - height_origin) / height_size, 0.0).rg;
	float sheltered = step(0.5, shelter.r) * step(above, shelter.g * 16.0);
	float alive = step(0.0, above - 0.05) * step(c.w, density) * (1.0 - sheltered);
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 to_cam = normalize(cam - head);
	vec3 right = normalize(cross(up, to_cam));
	float dist = distance(cam, head);
	// thin things far away turn to nothing: a little wider with distance, as the eye would have it
	float width = streak_width * (1.0 + dist * 0.06);
	vec3 world = head + up * (VERTEX.y * streak_length) + right * (VERTEX.x * width);
	POSITION = alive > 0.5 ? PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world, 1.0)) : vec4(0.0, 0.0, -2.0, 1.0);
	// the box's rim fades out (no drop pops into view), and right against the lens too
	float rim = 1.0 - smoothstep(0.6, 1.0, length(rel) / half_box);
	v_fade = rim * smoothstep(0.4, 1.6, dist);
}

void fragment() {
	// soft sides, bright head (UV.y = 0), tail fading away
	float side = 1.0 - pow(abs(UV.x * 2.0 - 1.0), 2.0);
	float tail = 1.0 - UV.y;
	ALBEDO = color.rgb;
	ALPHA = color.a * v_fade * side * (0.15 + 0.85 * tail * tail);
}
