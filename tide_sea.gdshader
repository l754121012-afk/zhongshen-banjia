shader_type spatial;
render_mode diffuse_burley;
uniform vec4 shallows:source_color=vec4(.25,.62,.61,1);
uniform vec4 deep:source_color=vec4(.10,.34,.49,1);
varying vec2 coast;

float surface_height(vec2 p,float t) {
	float swell=sin(p.y*2.25+p.x*.38+sin(p.x*.44+p.y*.11+t*.16)*1.15+t*.76);
	float cross_chop=sin(p.y*4.14-p.x*.71+sin(p.x*.61-t*.22)*.92+t*1.37);
	return swell*.67+cross_chop*.33;
}
void vertex() {
	coast=(MODEL_MATRIX*vec4(VERTEX,1.)).xz;
}
void fragment() {
	vec2 p=coast;
	float t=TIME;
	float h=surface_height(p,t);
	float dx=surface_height(p+vec2(.11,0.),t)-h;
	float dz=surface_height(p+vec2(0.,.11),t)-h;
	NORMAL=normalize((VIEW_MATRIX*vec4(normalize(vec3(-dx*.25,1.,-dz*.25)),0.)).xyz);
	float depth=.41+.16*sin(p.x*.073+p.y*.049)+.08*sin(p.y*.115-p.x*.036);
	vec3 body=mix(deep.rgb,shallows.rgb,depth);
	float patch=.5+.5*sin(p.x*.63+p.y*.34+sin(p.y*.47+t*.24)*1.4);
	float glint=smoothstep(.73,.98,h)*smoothstep(.39,.88,patch);
	ALBEDO=body*(.97+.035*h)+vec3(.09,.16,.16)*glint;
	ROUGHNESS=.53;
	SPECULAR=.23;
}
