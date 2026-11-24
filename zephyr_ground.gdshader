shader_type spatial;
render_mode cull_disabled;
varying vec3 p;
float hash(vec2 a){return fract(sin(dot(a,vec2(127.1,311.7)))*43758.545);}
float noise2(vec2 a){vec2 i=floor(a),f=fract(a);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),mix(hash(i+vec2(0.,1.)),hash(i+1.),f.x),f.y);}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
	float mottled=noise2(p.xz*.72);float grit=noise2(p.xz*9.);
	float wear=UV.x;
	vec2 row=p.xz*vec2(1.30,2.05);
	row.x+=.47*mod(floor(row.y),2.0)+.12*(mottled-.5);
	vec2 cell=fract(row);
	float edge=min(min(cell.x,1.-cell.x),min(cell.y,1.-cell.y));
	float stone=smoothstep(.025,.115,edge)*(.85+.22*hash(floor(row)));
	float pattern=mix(1.,.80+.31*stone,wear*(.35+.65*noise2(p.xz*.22))*(1.-smoothstep(.05,.18,fwidth(row.x))));
	ALBEDO=COLOR.rgb*(.79+.28*mottled+.10*grit)*pattern;
	ROUGHNESS=.93;
}
