// The dark brown outline of the 3D models (docs/migration-3d.md, phase 4), as the 2.5D's pictures
// have it: the next pass of the toon material (world3d/render/toon_style.gd).
// An inverted hull: the model drawn again, its back faces only, each vertex pushed out along its
// normal. The push is worked out on the screen, in pixels (per 720 px of screen height, the 2.5D's
// reference), so the line keeps about the same width near and far; past `far_start` it thins a
// little with distance, so a far-off dino is not a brown blob. Skinned (animated) meshes too: the
// engine has already moved their vertices by the bones when this runs.
// Drawn after the opaque pass and never into the depth buffer (depth_draw_never), so it casts no
// shadow and the model it outlines hides its inner part: only the rim around it shows, and the lines
// where one part (an arm, the tail) passes in front of another. The hull is also pushed back from
// the camera by `depth_push` (along the line of sight, so it stays at the same place on screen):
// shallow creases (lips, nose, a strap on the vest) draw no line, only real overlaps do.
// `toon_fade` (per mesh, set by toon_style.gd from GeometryInstance3D.transparency): the line
// thins as the model fades out and is gone past 0.2 (a see-through model would show the hull
// inside it); with `dither_fade` it is also dithered like the model (toon.gdshader), on the same
// pixels, so the hull never shows through the model's holes.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.165, 0.094, 0.047, 1.0);
uniform float width_px : hint_range(0.0, 8.0) = 2.0;
uniform float far_start = 12.0;
uniform float min_scale : hint_range(0.0, 1.0) = 0.4;
uniform float depth_push = 0.04;   // metres
uniform bool dither_fade = true;
// A mesh with hard edges (low-poly, flat-shaded): each face pushed along its own normal would
// leave gaps in the line. toon_style.gd then gives it smoothed normals in its TANGENT channel
// (moved by the bones like the normal), used here instead.
uniform bool smooth_normal_in_tangent = false;
instance uniform float toon_fade = 0.0;

const float FADE_GONE = 0.2;
const float REFERENCE_HEIGHT = 720.0;

// 4×4 ordered dither threshold, 0..1 (the same as toon.gdshader's)
float bayer2(vec2 a) {
	a = floor(a);
	return fract(a.x * 0.5 + a.y * a.y * 0.75);
}

float bayer4(vec2 a) {
	return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

void vertex() {
	if (toon_fade >= FADE_GONE) {
		POSITION = vec4(2.0, 2.0, 2.0, 1.0);   // every vertex on one point: nothing drawn
	} else {
		vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
		view.xyz += normalize(view.xyz) * depth_push;
		vec4 clip = PROJECTION_MATRIX * view;
		vec3 normal = normalize(MODELVIEW_NORMAL_MATRIX * (smooth_normal_in_tangent ? TANGENT : NORMAL));
		vec2 dir = (PROJECTION_MATRIX * vec4(normal, 0.0)).xy * VIEWPORT_SIZE;   // on screen, in pixels
		float len = length(dir);
		dir = len > 1e-6 ? dir / len : vec2(0.0);
		float dist = max(-view.z, 1e-3);
		float px = width_px * VIEWPORT_SIZE.y / REFERENCE_HEIGHT;
		px *= clamp(far_start / dist, min_scale, 1.0);
		px *= 1.0 - smoothstep(0.0, FADE_GONE, toon_fade);
		clip.xy += dir * px * 2.0 / VIEWPORT_SIZE * clip.w;
		POSITION = clip;
	}
}

void fragment() {
	if (dither_fade && toon_fade > 0.0 && bayer4(FRAGCOORD.xy) < toon_fade) {
		discard;
	}
	ALBEDO = outline_color.rgb;
}
