extends RefCounted

static var library:Dictionary={}
static func sample(index:int,tint:String,scale_m:float,world:=true,contrast:=.65)->ShaderMaterial:
	var token:=str([index,tint,scale_m,world,contrast])
	if not library.has(token):
		var mat:=ShaderMaterial.new();mat.shader=preload("res://harbour_surface.gdshader")
		mat.set_shader_parameter("atlas",preload("res://art/harbour_materials.png"))
		mat.set_shader_parameter("tile",Vector2(index%2,index/2))
		mat.set_shader_parameter("pigment",Color(tint));mat.set_shader_parameter("span",scale_m)
		mat.set_shader_parameter("fixed_space",world);mat.set_shader_parameter("contrast",contrast)
		library[token]=mat
	return library[token]
