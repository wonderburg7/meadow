shader_type canvas_item;

// Fog-of-war mask shader. AUDIT_PLAN.md Bundle F: replaces the old
// per-tile draw_rect run-merging in fog_of_war.gd with a single textured
// quad. fog_of_war.gd keeps one persistent mask_tex covering the whole
// meadow (0 = unexplored, ~half = explored/unlit, full = lit, one byte
// per fog tile) and issues one draw call per frame the camera's view
// actually changed; this shader turns that single-channel mask back into
// the same two-colour, three-state fog picture the old draw_rect version
// drew, entirely on the GPU.
//
// The draw call always covers the camera's *whole* current view, not
// just whatever part mask_tex has real data for -- camera_view.gd never
// clamps camera position (only zoom), so the view can reach past
// mask_tex's world coverage at low zoom near a field edge. Rather than
// relying on Godot's own UV clipping (draw_texture_rect_region's clip_uv
// stretches the boundary texel across any leftover space instead of just
// stopping, which read as fog "lifting into infinity" toward an edge) or
// skipping the draw for the uncovered part (which read as that edge
// being pre-revealed, since skipping a draw leaves nothing there at
// all), this fragment shader converts each pixel's own world position
// back to a mask_tex UV itself and explicitly treats anything outside
// [0, 1] as unexplored -- the actually-correct answer for ground nothing
// has ever revealed, rather than an artifact of how the draw was clipped.

uniform sampler2D mask_tex : filter_nearest, repeat_disable;
uniform bool permanent_reveal = false;
// The old draw_rect version's UNEXPLORED_COLOR/EXPLORED_DIM_COLOR both used
// this same RGB (18, 11, 15) and only differed by alpha -- see the state
// bands below, which reproduce that.
uniform vec3 fog_rgb = vec3(0.0706, 0.0431, 0.0588);

// World-space rect this draw call covers (the camera's current view) --
// set every draw in fog_of_war.gd::_draw_fog_body.
uniform vec2 view_world_pos;
uniform vec2 view_world_size;
// World-space rect mask_tex itself covers -- constant once the texture
// is built, set once in fog_of_war.gd::_build_layer.
uniform vec2 tex_world_pos;
uniform vec2 tex_world_size;

void fragment() {
	vec2 world_pos = view_world_pos + UV * view_world_size;
	vec2 tex_uv = (world_pos - tex_world_pos) / tex_world_size;

	float state = 0.0; // outside mask_tex's coverage -- treat as unexplored
	if (tex_uv.x >= 0.0 && tex_uv.x <= 1.0 && tex_uv.y >= 0.0 && tex_uv.y <= 1.0) {
		state = texture(mask_tex, tex_uv).r;
	}

	float a;
	if (state < 0.25) {
		a = 1.0; // unexplored -- fully opaque
	} else if (state < 0.75) {
		a = permanent_reveal ? 0.0 : (140.0 / 255.0); // explored, not lit
	} else {
		a = 0.0; // lit right now
	}
	COLOR = vec4(fog_rgb, a);
}
