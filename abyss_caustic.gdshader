shader_type spatial;
uniform vec4 stone:source_color=vec4(0.17,0.39,0.42,1);
uniform vec4 pool_light:source_color=vec4(0.28,0.68,0.62,1);
varying vec3 place;
void vertex(){place=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=vec2(place.x,place.y+place.z*0.67);
	float a=sin(p.x*1.17+sin(p.y*1.47+TIME*0.56))+cos(p.y*1.33-p.x*0.26-TIME*0.37);
	float c=1.0-smoothstep(0.015,0.12,abs(a));
	ALBEDO=mix(stone.rgb,pool_light.rgb,c*0.44+0.10*sin(p.x*0.44+p.y*0.17));
	ROUGHNESS=0.77;
}
