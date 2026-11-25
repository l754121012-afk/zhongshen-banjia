shader_type spatial;
render_mode cull_disabled;
uniform float wave_front=-999.0;
uniform float wave_strength=0.0;
varying float crest;
void vertex(){
	vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	float passed=wave_front-world.x;
	crest=smoothstep(-3.,3.,passed)*(1.-smoothstep(5.,36.,passed))*wave_strength;
	float gust=.13+.16*sin(TIME*2.-world.x*.46+world.z*.11)+.05*sin(TIME*3.7+world.z*.6);
	float weight=UV.y*UV.y;
	VERTEX.x+=(gust+.91*crest)*weight;
	VERTEX.y-=crest*.31*weight;
}
void fragment(){
	ALBEDO=mix(COLOR.rgb,COLOR.rgb*1.13,crest*UV.y);
	ROUGHNESS=.96;
	SPECULAR=.08;
}
