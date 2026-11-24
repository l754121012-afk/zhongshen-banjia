shader_type spatial;
render_mode cull_disabled;
varying vec3 local_pos;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.55);}
float grain(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash21(i),hash21(i+vec2(1.,0.)),f.x),mix(hash21(i+vec2(0.,1.)),hash21(i+1.),f.x),f.y);}
float stripe(float v,float a,float b){return smoothstep(a-.006,a,v)*(1.-smoothstep(b,b+.006,v));}
void vertex(){local_pos=VERTEX;}
void fragment(){
	float az=atan(local_pos.z,local_pos.x)/6.2831853+.5;
	float y=local_pos.y;
	vec2 brush=vec2(az*46.,y*10.);
	float patina=grain(brush)+.24*grain(brush*5.);
	vec3 clay=mix(vec3(.28,.077,.033),vec3(.64,.242,.085),patina*.72);
	clay+=.012*sin(y*285.+3.*patina);
	vec3 glaze=mix(vec3(.018,.088,.107),vec3(.028,.222,.229),patina);
	vec3 gold=mix(vec3(.47,.219,.064),vec3(.79,.528,.213),patina);
	float belt=stripe(y,.34,.56)+stripe(y,.97,1.10)+stripe(y,.08,.13);
	vec3 pigment=mix(clay,glaze,clamp(belt,0.,1.));
	float gilt=stripe(y,.335,.35)+stripe(y,.55,.565)+stripe(y,.966,.98)+stripe(y,1.08,1.10);
	float motif=.447+.044*sin(az*6.2831853*8.);
	gilt+=stripe(y,motif-.009,motif+.009);
	float dotmark=length(vec2((fract(az*16.)-.5)*.43,(y-1.027)*2.));
	gilt+=1.-smoothstep(.014,.023,dotmark);
	ALBEDO=mix(pigment,gold,clamp(gilt,0.,1.));
	ROUGHNESS=mix(.86,.40,clamp(belt,0.,1.));METALLIC=.08*clamp(gilt,0.,1.);
}
