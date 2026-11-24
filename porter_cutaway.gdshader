shader_type spatial;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D paint : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float roughness = 0.9;
uniform float metallic = 0.0;
uniform vec3 subject;
uniform vec3 camera_eye;
uniform float actor_floor;
uniform float radius_scale;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 center = (VIEW_MATRIX * vec4(subject, 1.0)).xyz;
	if (distance(INV_VIEW_MATRIX[3].xyz, camera_eye) < 0.05 && dot(world_pos.xz - subject.xz, normalize(camera_eye.xz - subject.xz)) > -0.15 && world_pos.y > actor_floor + 0.08) {
		vec2 at_subject = VERTEX.xy * center.z / min(VERTEX.z, -0.001);
		float radius = length(at_subject - center.xy);
		float grain = fract(52.9829189 * fract(dot(floor(FRAGCOORD.xy), vec2(0.06711056, 0.00583715))));
		if (radius < (1.25 + 0.09 * grain) * radius_scale) { discard; }
	}
	ALBEDO = tint.rgb * texture(paint, UV).rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}
