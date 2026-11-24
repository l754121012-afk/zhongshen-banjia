shader_type spatial;
render_mode cull_disabled;
uniform sampler2D atlas:source_color,filter_linear_mipmap_anisotropic,repeat_disable;
uniform vec2 tile=vec2(0.);
uniform float span=4.0;
uniform bool fixed_space=true;
uniform vec4 pigment:source_color=vec4(.7,.62,.48,1.);
uniform float contrast=.65;
varying vec3 place;
varying vec3 axis;
void vertex(){
	if(fixed_space){place=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;axis=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
	else {place=VERTEX*vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));axis=NORMAL;}
}
void fragment(){
	vec3 n=abs(normalize(axis));vec2 raw=n.y>.62?place.xz:(n.z>n.x?place.xy:place.zy);
	raw/=span;
	vec2 uv=tile*.5+vec2(.002)+fract(raw)*.496;
	vec3 tex=textureGrad(atlas,uv,dFdx(raw)*.496,dFdy(raw)*.496).rgb;
	float val=dot(tex,vec3(.30,.54,.16));float mid=tile.x>.5&&tile.y<.5?.13:.47;
	float dye=clamp(pow(max(.001,val/mid),.73),.41,1.55);
	ALBEDO=pigment.rgb*mix(1.0,dye,contrast);
	ROUGHNESS=.82+.1*(1.-min(dye,1.));
}
