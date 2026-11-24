shader_type spatial;
render_mode cull_disabled;
uniform float wind_time=0.;
uniform vec2 burst_at=vec2(900.);
uniform float burst_age=8.;
varying float shine;
void vertex(){
	vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	float phase=mod(wind_time-dot(world.xz,vec2(.40,.9165))/10.,8.6);
	float press=smoothstep(.12,1.65,phase)*(1.-smoothstep(3.,5.50,phase));
	float ring=exp(-abs(length(world.xz-burst_at)-burst_age*16.)*.75)*float(burst_age<2.5);
	float flick=sin(wind_time*4.7+world.x*2.11+world.z*1.71);
	float bend=UV.y*(.30*press+.64*ring+.07*flick);
	VERTEX.xz+=vec2(.42,.91)*bend;VERTEX.y+=.29*bend;
	shine=clamp(.15+.43*press+.91*ring+.29*flick,0.,1.);
}
void fragment(){
	vec3 silver=vec3(.41,.47,.32);
	ALBEDO=mix(COLOR.rgb,silver,shine*shine*.86);ROUGHNESS=.82;
}
