shader_type spatial;
render_mode cull_disabled;
uniform vec4 base:source_color=vec4(.71,.61,.49,1);
uniform vec4 mortar:source_color=vec4(.52,.46,.39,1);
varying vec3 pt;
varying vec3 norm;
float h(vec2 a){return fract(sin(dot(a,vec2(123.43,47.17)))*3214.48);}
void vertex(){pt=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;norm=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){vec3 n=abs(norm);vec2 uv=n.y>0.67?pt.xz:(n.z>n.x?pt.xy:pt.zy);uv/=vec2(1.19,0.53);uv.x+=0.5*mod(floor(uv.y),2.);vec2 f=fract(uv);vec2 e=min(f,1.-f);float edge=smoothstep(0.018,0.055,min(e.x*1.9,e.y));float gr=h(floor(uv*42.));ALBEDO=mix(mortar.rgb,base.rgb*(0.85+0.22*h(floor(uv))),edge)*(.97+.05*gr);ROUGHNESS=.9;}
