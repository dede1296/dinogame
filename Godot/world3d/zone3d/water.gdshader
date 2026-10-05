shader_type spatial;
// The water of a 3D zone (docs/migration-3d.md, phase 4): one sheet at the 2.5D's water level, seen
// only where the ground is dug below it (ponds, the sea). Cartoon, like the rest of the PC 3D:
// franc colours in three depth bands, gentle wave trains, the path of the sun on the water, foam
// lapping the shore and ringing whatever pierces the surface, the bed showing through the shallows.
//
// It takes no light from the engine (`unshaded`): zone_water.gd hands it the colour of the sky at
// this hour (sky_zenith / sky_horizon, taken from the real sun of ZoneSky), the tint and the level
// of the light, and the water mixes its own body colour with the sky it reflects. That is why it
// never goes black: at dusk and at night it keeps the colour of the sky above it (`sky_floor`).
//
// Cost: no screen copy. One fetch of the bed's height, one of the noise, one of the depth buffer
// (free in Forward+, it is already there) — the waves and the glint are plain arithmetic.

render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

// --- the bed, read from the 2.5D's relief (HeightMap.height_texture, in tiles) ---
uniform sampler2D ground_height : filter_linear, repeat_disable;
uniform vec2 height_origin = vec2(-10.0);   // tiles
uniform float height_res = 2.0;             // samples per tile
uniform vec2 height_texels = vec2(2.0);
uniform float tile_m = 2.0;
uniform float water_level = -0.425;
uniform float deep_m = 0.72;                // this deep, the water is at its deepest colour

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;

// --- the cartoon palette: three franc bands from the shore to the deep ---
uniform vec3 shallow : source_color = vec3(0.47, 0.86, 0.80);
uniform vec3 mid : source_color = vec3(0.20, 0.64, 0.74);
uniform vec3 deep : source_color = vec3(0.09, 0.38, 0.56);
uniform vec3 foam_colour : source_color = vec3(0.95, 0.99, 0.97);
// Where the bands fall (share of deep_m) and how soft their edges are.
uniform float band_near = 0.22;
uniform float band_far = 0.6;
uniform float band_soft = 0.1;

// --- the sky of the hour, handed over by zone_water.gd ---
uniform vec3 sky_zenith : source_color = vec3(0.36, 0.62, 0.95);
uniform vec3 sky_horizon : source_color = vec3(0.72, 0.87, 1.0);
uniform vec3 body_tint : source_color = vec3(1.0);   // the hour's colour over the body of the water
uniform vec3 glint_colour : source_color = vec3(1.0, 0.96, 0.85);
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);          // from the water towards the sun (or the moon)
// How lit a flat surface is at this hour (the body of the water) and how bright the sky dome is
// (what it mirrors, and the sun's path on it). They part company at dusk: the sky is still ablaze
// while the sun no longer reaches the ground.
uniform float light_level : hint_range(0.0, 2.0) = 1.0;
uniform float sky_level : hint_range(0.0, 2.0) = 1.0;
uniform float cloudiness : hint_range(0.0, 1.0) = 0.35;
// The water never falls below this share of the sky it reflects — it never turns black.
uniform float sky_floor : hint_range(0.0, 1.0) = 0.1;
// The real mirror (zone_water.gd, Reflections.MIRROR): the scene filmed from under the water by a
// mirrored camera. mirror_mix at 0 leaves only the sky worked out above, which is the way back.
// The picture comes out swapped left to right (see _aim_mirror), so it is read swapped back.
uniform sampler2D mirror_tex : hint_default_black, filter_linear, repeat_disable;
uniform float mirror_mix : hint_range(0.0, 1.0) = 0.0;
// Just a ripple over the reflection, never a smear: too much and the mirror looks blurred.
uniform float mirror_wobble : hint_range(0.0, 0.2) = 0.025;
// The mirror's picture has already been exposed once, in its own viewport; what goes into ALBEDO
// is exposed a second time by the window. At dusk and at night the window opens wide and the
// reflection would come out whiter than the sky itself, so zone_water.gd turns it down by the hour.
uniform float mirror_gain : hint_range(0.0, 2.0) = 1.0;
uniform float reflect_min : hint_range(0.0, 1.0) = 0.1;
uniform float reflect_strength : hint_range(0.0, 1.0) = 0.88;
// The path of the sun (or the moon) on the water: a broad warm band, and the sparks on the ripples.
uniform float road_strength : hint_range(0.0, 2.0) = 0.14;
uniform float spark_strength : hint_range(0.0, 2.0) = 0.35;

// --- the waves: three gentle trains, and the swell that lifts the sheet ---
uniform float wave_scale = 0.33;        // 1 / wavelength (m)
uniform float wave_speed = 0.85;
uniform float wave_slope : hint_range(0.0, 1.0) = 0.3;
uniform float swell_scale = 0.09;       // the long swell the sheet rides on
uniform float swell_m = 0.05;
uniform float ripple_scale = 0.3;
// Where the sparks fade out, so they do not band along the skyline (m from the camera).
uniform float fade_begin_m = 45.0;
uniform float fade_end_m = 150.0;

// --- the foam ---
uniform float shore_foam_m = 0.13;      // depth of water the shore foam reaches
uniform float edge_foam_m = 0.45;       // metres of water around whatever pierces the surface
uniform float see_through_m = 0.55;     // this much water in front of the bed and it is opaque
uniform float alpha_shallow : hint_range(0.0, 1.0) = 0.42;
uniform float alpha_deep : hint_range(0.0, 1.0) = 0.94;

varying vec3 flat_world;   // the sheet before the swell lifts it: the bed is read here

const vec2 DIR_A = vec2(0.87, 0.5);
const vec2 DIR_B = vec2(-0.41, 0.91);
const vec2 DIR_C = vec2(0.6, -0.8);

float ground_at(vec2 w) {
	vec2 t = w / tile_m;
	return textureLod(ground_height, ((t - height_origin) * height_res + 0.5) / height_texels, 0.0).r;
}

// The three wave trains at `p` (m): x = their height, yz = their slope along x and z.
vec3 waves(vec2 p, float t) {
	float k1 = wave_scale;
	float k2 = wave_scale * 1.7;
	float k3 = wave_scale * 2.9;
	float p1 = dot(p, DIR_A) * k1 + t * wave_speed;
	float p2 = dot(p, DIR_B) * k2 - t * wave_speed * 1.25;
	float p3 = dot(p, DIR_C) * k3 + t * wave_speed * 1.8;
	vec2 slope = cos(p1) * k1 * DIR_A + cos(p2) * k2 * DIR_B * 0.55 + cos(p3) * k3 * DIR_C * 0.25;
	return vec3(sin(p1) + sin(p2) * 0.55 + sin(p3) * 0.25, slope);
}

void vertex() {
	flat_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// The swell only out in the open: at the shore the sheet stays put, so its edge keeps still.
	// It is far longer than the ripples, so a coarse sheet is enough to carry it.
	float depth = water_level - ground_at(flat_world.xz);
	float swell = sin(dot(flat_world.xz, DIR_A) * swell_scale + TIME * 0.5)
		+ 0.6 * sin(dot(flat_world.xz, DIR_B) * swell_scale * 1.4 - TIME * 0.37);
	VERTEX.y += swell * swell_m * smoothstep(0.0, 0.35, depth);
}

void fragment() {
	float bed = ground_at(flat_world.xz);
	float depth = water_level - bed;
	if (depth < -0.02) {
		discard;   // the ground stands above the water here
	}
	float d = clamp(depth / deep_m, 0.0, 1.0);

	// Far off, a spark is thinner than a pixel: letting them through there only makes bands along
	// the skyline, so they fade out with the distance.
	float near = 1.0 - smoothstep(fade_begin_m, fade_end_m, distance(flat_world, CAMERA_POSITION_WORLD));
	vec2 drift = flat_world.xz * ripple_scale + vec2(TIME * 0.016, TIME * -0.011);
	float ripple = texture(noise_tex, drift).r;

	// The surface: the three wave trains, roughened by the same slow drift of noise.
	vec3 wave = waves(flat_world.xz, TIME);
	float height = wave.x * 0.55;   // about -1 to 1
	vec2 slope = wave.yz;
	slope += (vec2(ripple) - 0.5) * 1.1;
	// Flat at the very shore, so the foam band is not shattered.
	vec3 n = normalize(vec3(-slope.x * wave_slope, 1.0, -slope.y * wave_slope));
	n = normalize(mix(vec3(0.0, 1.0, 0.0), n, smoothstep(0.0, 0.2, depth)));

	vec3 view_dir = normalize(flat_world - CAMERA_POSITION_WORLD);
	vec3 refl = reflect(view_dir, n);

	// The sky it mirrors: the horizon near the water line, the zenith straight up, a few clouds.
	// Along the skyline only the quarter the sun is in is ablaze; away from it the horizon keeps
	// the deeper colour of the zenith — that is what makes a sunset sea, bright one way, dark the
	// other, instead of one flat sheet of orange.
	vec2 flat_refl = refl.xz;
	vec2 flat_sun = sun_dir.xz;
	float facing = dot(flat_refl, flat_sun) / max(length(flat_refl) * length(flat_sun), 1e-4);
	vec3 skyline = mix(mix(sky_zenith, sky_horizon, 0.3), sky_horizon, smoothstep(-0.3, 0.9, facing));
	vec3 sky = mix(skyline, sky_zenith, smoothstep(0.0, 0.42, refl.y));
	float cloud = texture(noise_tex, refl.xz / max(abs(refl.y), 0.14) * 0.02 + vec2(TIME * 0.003, 0.0)).r;
	sky *= sky_level * (1.0 + 0.18 * smoothstep(0.58, 0.98, cloud) * cloudiness * near);
	// …and over it, if there is one, the real mirror: the trees, the cliffs, Chloé. Its picture is
	// already lit and exposed, so it goes on after sky_level, never multiplied by it. The ripples
	// bend what it shows, which is what makes it read as water and not as a pane of glass.
	if (mirror_mix > 0.0) {
		vec2 ruv = vec2(1.0 - SCREEN_UV.x, SCREEN_UV.y) + slope * mirror_wobble;
		vec3 shown = textureLod(mirror_tex, clamp(ruv, vec2(0.002), vec2(0.998)), 0.0).rgb;
		// The small viewport hands back a finished picture, in screen colours; bring it back to
		// light before it goes into ALBEDO, or the whole sea washes out white.
		shown = mix(pow((shown + vec3(0.055)) / 1.055, vec3(2.4)), shown / 12.92, step(shown, vec3(0.04045)));
		shown *= mirror_gain;
		// Only near the shore, where there is something to reflect: far out it is sky anyway, and
		// the sky worked out above holds the colours of the hour better than a twice-exposed copy.
		sky = mix(sky, shown, mirror_mix * near);
	}
	float fresnel = pow(1.0 - clamp(dot(-view_dir, n), 0.0, 1.0), 4.0);
	float mirror = mix(reflect_min, 1.0, fresnel) * reflect_strength;

	// The body of the water: three franc bands, in the colour of the hour, with the wave trains
	// reading on it as broad light and dark stripes.
	vec3 body = mix(shallow, mid, smoothstep(band_near - band_soft, band_near + band_soft, d));
	body = mix(body, deep, smoothstep(band_far - band_soft, band_far + band_soft, d));
	body *= body_tint * light_level * mix(0.88, 1.14, clamp(height * 0.5 + 0.5, 0.0, 1.0));

	// No pale caps on the crests: whichever way they were drawn they read as light lines running
	// right across the water, and clean water without them is the better trade (Greg, 04/10).
	vec3 col = mix(body, sky, mirror);

	// The path of the sun (or the moon) on the water: a broad warm road towards it, and sparks
	// where a ripple turns its face to it. Both narrow, or a low sun would whiten the whole sea.
	float towards = clamp(dot(refl, sun_dir), 0.0, 1.0);
	float road = pow(towards, 40.0);
	float spark = smoothstep(0.72, 0.9, ripple) * pow(towards, 220.0) * near;
	col += glint_colour * (road * road_strength + spark * spark_strength) * sky_level;

	// What pierces the surface (rocks, the bed close under it): how much water is in front of it.
	float scene_raw = texture(depth_tex, SCREEN_UV).r;
	vec4 scene_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene_raw, 1.0);
	float gap = -(scene_view.z / scene_view.w) + VERTEX.z;   // metres of water under this pixel

	// Foam: a band lapping the shore, breathing, and a ring around whatever stands in the water.
	float lap = shore_foam_m * (1.0 + 0.3 * sin(TIME * 1.1 + (flat_world.x + flat_world.z) * 0.5)) + 0.05 * ripple;
	float froth = 1.0 - smoothstep(0.0, lap, depth);
	froth = max(froth, 1.0 - smoothstep(0.0, edge_foam_m, gap));
	froth *= 0.55 + 0.45 * smoothstep(0.35, 0.72, texture(noise_tex, flat_world.xz * 0.55 + vec2(TIME * 0.05, 0.0)).r);
	col = mix(col, foam_colour * max(light_level, 0.35), froth * 0.85);

	// It never goes black: it keeps at least this much of the sky it reflects.
	col = max(col, sky * sky_floor);

	ALBEDO = col;
	// See-through in the shallows (the bed shows), opaque out in the deep.
	float thickness = min(d, clamp(gap / see_through_m, 0.0, 1.0));
	float alpha = mix(alpha_shallow, alpha_deep, smoothstep(0.0, 0.72, thickness));
	ALPHA = max(alpha, froth * 0.9) * smoothstep(-0.02, 0.04, depth);
}
