shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint:source_color=vec4(.66,.57,.47,1.);
varying vec3 world;
varying float tone;
float h(vec3 p){return fract(sin(dot(p,vec3(13.789,64.37,83.11)))*4321.67);}
float grain(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(mix(h(i),h(i+vec3(1,0,0)),f.x),mix(h(i+vec3(0,0,1)),h(i+vec3(1,0,1)),f.x),f.z),mix(mix(h(i+vec3(0,1,0)),h(i+vec3(1,1,0)),f.x),mix(h(i+vec3(0,1,1)),h(i+vec3(1,1,1)),f.x),f.z),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;tone=COLOR.r;}
void fragment(){
	float seed=grain(world*.37);float band=fract(world.y*1.66+world.x*.09+world.z*.13+seed*1.1);
	float crev=smoothstep(.007,.10,band);
	float damp=smoothstep(-.48,1.40,world.y);
	vec3 base=tint.rgb*(.72+.23*tone+.16*seed);
	base*=mix(.75,1.0,crev)*(.97+.045*grain(world*11.));
	ALBEDO=mix(base*vec3(.67,.80,.78),base,damp);
	ROUGHNESS=.92;
}
