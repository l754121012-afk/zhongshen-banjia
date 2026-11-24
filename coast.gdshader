shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_point;
uniform vec4 shade : source_color=vec4(0.18,0.51,0.54,1);
uniform vec4 light_water : source_color=vec4(0.48,0.73,0.72,1);
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
	vec2 q=world_point.xz;
	float ripple=sin(q.x*1.35+sin(q.y*2.8+TIME*0.6)+TIME*0.65);
	float patch=sin(q.y*3.0-q.x*0.22+TIME*0.39);
	float gleam=smoothstep(0.90,0.985,ripple)*smoothstep(0.54,0.92,patch);
	ALBEDO=mix(shade.rgb,light_water.rgb,0.19+0.12*sin(q.y*0.35)+gleam*0.58);
	ROUGHNESS=0.50;
	SPECULAR=0.24;
}
