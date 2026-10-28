shader_type canvas_item;
// Change 24: the fog veil in one draw (scripts/game/fog_layer.gd). The explored mask is an L8 texture,
// one texel per fog cell (non-zero = explored). Each unexplored cell gets the vision veil when its
// centre is within the momentary sight radius of the living player (the same cell-centred test as
// campaign.can_see), else the cover colour. Colours are passed raw, exactly as draw_rect used them.
uniform sampler2D explored : filter_nearest, repeat_disable;
uniform vec2 cells = vec2(1.0);
uniform float cell_size = 24.0;
uniform vec2 player = vec2(0.0);
// Negative while the player is dead: no vision veil.
uniform float radius = -1.0;
uniform vec4 cover_color = vec4(0.035, 0.05, 0.07, 1.0);
uniform vec4 vision_color = vec4(0.035, 0.05, 0.07, 0.5);

void fragment() {
	vec2 cell = min(floor(UV * cells), cells - 1.0);
	if (texture(explored, (cell + 0.5) / cells).r > 0.0) {
		COLOR = vec4(0.0);
	} else {
		vec2 centre = (cell + 0.5) * cell_size;
		COLOR = (radius > 0.0 && distance(centre, player) <= radius) ? vision_color : cover_color;
	}
}
