shader_type spatial;
uniform bool mirror_on=false;
uniform vec3 pilot_0;
uniform vec3 pilot_1;
uniform vec3 pilot_2;
uniform vec3 pilot_3;
uniform vec2 vessel=vec2(0.0);
uniform float echo_radius=-10.;
uniform vec4 tug_trace=vec4(0.0);
uniform vec4 cargo_trace=vec4(0.0);
varying vec2 sea;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.55);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),mix(hash(i+vec2(0.,1.)),hash(i+1.),f.x),f.y);}
float wave(vec2 p,float t){return .52*sin(p.y*1.72+p.x*.43+4.3*noise2(p*.27+vec2(0.,t*.12))+t*.64)+.3*sin(p.y*2.92-p.x*1.2+2.6*noise2(p*.45)+t*.83)+.18*noise2(p*2.);}
float trail(vec2 p,vec4 craft,float t){
	vec2 dir=vec2(cos(craft.z),sin(craft.z));
	vec2 delta=p-craft.xy;
	float aft=-dot(delta,dir)-1.9;
	float side=abs(dot(delta,vec2(-dir.y,dir.x)));
	float envelope=smoothstep(0.,1.3,aft)*(1.-smoothstep(2.,11.,aft));
	float edge=abs(side-(.67+aft*.25+.11*sin(aft*1.9-t*2.)));
	return exp(-edge*edge*5.)*envelope*(.45+.55*noise2(p*2.+t*.15))*craft.w;
}
float pilot_reflection(vec2 point, vec3 lamp, vec2 eye, float time){
	vec2 toward=normalize(eye-lamp.xy+vec2(.0001));
	vec2 delta=point-lamp.xy;
	float down=dot(delta,toward);
	float across=dot(delta,vec2(-toward.y,toward.x));
	float bend=.13*sin(down*7.+time*1.4)+.07*sin(down*13.-time*.91);
	float width=.19+.22*smoothstep(0.,4.5,down);
	float streak=exp(-pow((across+bend)/width,2.));
	float slivers=.25+.75*smoothstep(.06,.68,sin(down*17.+across*3.-time*1.1));
	return lamp.z*streak*slivers*smoothstep(-.3,.12,down)*(1.-smoothstep(.4,4.5,down));
}
void vertex(){sea=(MODEL_MATRIX*vec4(VERTEX,1.)).xz;}
void fragment(){
	float t=TIME;vec2 p=sea;float h=wave(p,t);
	float dx=wave(p+vec2(.12,0.),t)-h;float dy=wave(p+vec2(0.,.12),t)-h;
	NORMAL=normalize((VIEW_MATRIX*vec4(normalize(vec3(-dx*.42,1.,-dy*.42)),0.)).xyz);
	float lane=exp(-abs(p.x-13.-3.*sin(p.y*.13))*.14);
	float shimmer=smoothstep(.53,.82,h)*smoothstep(.33,.78,noise2(p*.84))* (.13+.79*lane);
	float d=distance(p,vessel);float echo=exp(-abs(d-echo_radius)*2.9)*(1.-smoothstep(23.,33.,echo_radius));
	ALBEDO=mix(vec3(.012,.032,.062),vec3(.027,.078,.100),noise2(p*.085))+vec3(.17,.21,.21)*shimmer;
	EMISSION=vec3(.15,.65,.54)*echo+vec3(.18,.14,.11)*shimmer;
	float foam=trail(p,tug_trace,t)+trail(p,cargo_trace,t);
	ALBEDO+=vec3(.08,.16,.15)*foam;
	EMISSION+=vec3(.036,.093,.084)*foam;
	vec2 eye=INV_VIEW_MATRIX[3].xz;
	float beacons=pilot_reflection(p,pilot_0,eye,t)+pilot_reflection(p,pilot_1,eye,t)+pilot_reflection(p,pilot_2,eye,t)+pilot_reflection(p,pilot_3,eye,t);
	EMISSION+=vec3(1.0,.51,.17)*beacons*1.9;
	if(mirror_on){
		vec2 a=vec2(-4.64,26.21),b=vec2(-4.,19.);
		float u=clamp(dot(p-a,b-a)/dot(b-a,b-a),0.,1.);
		float dist=distance(p,mix(a,b,u));
		float glint=exp(-3.*dist*dist)*(.12+.42*smoothstep(.14,.76,h))*(.42+.58*u);
		EMISSION+=vec3(.89,.60,.25)*glint;
	}
	ROUGHNESS=.53;SPECULAR=.19;
}
