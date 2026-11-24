shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 stone : source_color = vec4(0.55,0.51,0.43,1);
uniform vec4 mortar : source_color = vec4(0.40,0.40,0.36,1);
uniform float block_size = 0.53;
varying vec3 point;
void vertex(){ point=VERTEX*vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz)); }
float hash(vec2 x){ return fract(sin(dot(x,vec2(71.37,83.13)))*32564.52); }
void fragment(){
	vec2 q=point.xz/vec2(block_size*1.8,block_size);
	q.x+=mod(floor(q.y),2.0)*0.5;
	vec2 id=floor(q);
	vec2 f=fract(q);
	float edge=min(min(f.x,1.-f.x)*1.45,min(f.y,1.-f.y));
	float line=smoothstep(0.018,0.053,edge);
	float speckle=hash(floor(point.xz*31.));
	vec3 c=mix(mortar.rgb,stone.rgb*(0.87+0.19*hash(id)),line);
	ALBEDO=c*(0.98+0.04*speckle);
	ROUGHNESS=0.94;
}
