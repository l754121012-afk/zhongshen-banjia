shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
uniform vec4 track_color:source_color=vec4(.67,.53,.38,1);
uniform vec4 herb:source_color=vec4(.34,.44,.28,1);
uniform vec4 scree:source_color=vec4(.51,.49,.43,1);
uniform vec4 clay:source_color=vec4(.70,.57,.42,1);
uniform vec4 chalk:source_color=vec4(.69,.66,.54,1);

float hash(vec2 id){vec3 p=fract(vec3(id.xyx)*vec3(.1031,.11369,.13787));p+=dot(p,p.yzx+19.19);return fract((p.x+p.y)*p.z);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
	vec2 p=world.xz;
	float d=min(abs(UV.x),abs(UV.y));
	float broad=noise2(p*.066),med=noise2(p*.47),grain=noise2(p*5.4);
	float fade_detail=1.-smoothstep(38.,100.,length(VERTEX));
	float region=smoothstep(264.,316.,p.x)*(1.-smoothstep(472.,504.,p.x))+.89*smoothstep(1040.,1120.,p.x)*(1.-smoothstep(1300.,1356.,p.x));
	vec3 outside=mix(herb.rgb, scree.rgb,clamp(region*.77+broad*.29,0.,1.))*(.79+.32*broad+.13*med);
	outside=mix(outside,chalk.rgb,(.32+.44*region)*smoothstep(.43,.8,med+.14*broad));
	float edge=d+.65*(med-.5)+.39*(grain-.5)*fade_detail;
	float width=mix(4.4,3.25,step(abs(UV.y)+.12,abs(UV.x)));
	float is_road=1.-smoothstep(width-.7,width+.45,edge);
	float rut_offset=abs(d-(1.17+.12*sin(p.x*.29)+.10*(med-.5)));
	float rut=(1.-smoothstep(.12,.39,rut_offset))*(.46+.54*noise2(p*.89));
	vec3 road=mix(track_color.rgb,clay.rgb,med)*(.84+.24*broad+.08*grain*fade_detail);
	road*=1.-.30*rut;
	road=mix(road,herb.rgb,(1.-smoothstep(.22,.85,d))*(.07+.24*broad));
	// Individually spaced worn limestone chips in the wheel ruts and verges.
	vec2 cell=p*2.6, id=floor(cell);
	vec2 o=vec2(hash(id),hash(id+31.))*.60+.2;
	float pebble=(1.-smoothstep(.08,.16,length((fract(cell)-o)*vec2(.85,1.7))))*step(.43,hash(id+4.))*fade_detail;
	ALBEDO=mix(outside,road,is_road)*(1.+.25*pebble+.09*(grain-.5)*fade_detail);
	ROUGHNESS=.96;SPECULAR=.08;
}
