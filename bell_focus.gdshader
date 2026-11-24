shader_type canvas_item;
render_mode unshaded;
uniform vec2 focus = vec2(0.5);
uniform float shade = 0.0;
void fragment() {
	vec2 delta = (UV - focus) * vec2(1.55, 1.0);
	float edge = smoothstep(0.13, 0.46, length(delta));
	COLOR = vec4(0.035, 0.075, 0.082, shade * edge);
}
