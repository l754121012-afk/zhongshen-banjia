shader_type spatial;
render_mode cull_disabled;
uniform float wind_time=0.;
varying vec2 field_pos;
uniform bool port_cut=false;
void vertex(){
	vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	field_pos=p.xz;float phase=mod(wind_time-dot(p.xz,vec2(.40,.9165))/10.,8.60);
	float wave=smoothstep(.12,1.65,phase)*(1.-smoothstep(3.,5.50,phase));
	VERTEX.xz+=vec2(.15,.27)*(wave+.12*sin(wind_time*2.1+p.x*.69))*UV.y*UV.y;
}
void fragment(){
 if(port_cut && field_pos.x>88. && field_pos.y>-20.){discard;}
	ALBEDO=COLOR.rgb*(.76+.24*UV.y);ROUGHNESS=.95;
}
