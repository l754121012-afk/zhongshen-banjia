extends RefCounted
const Art=preload("res://workshop.gd")
const Mat=preload("res://harbour_materials.gd")
const B=preload("res://tide_art.gd")
var art:=Art.new()
var leaf_mat:=ShaderMaterial.new()
var rng:=RandomNumberGenerator.new()
var god_winds:Array[MeshInstance3D]=[]
var region:Array[Vector2]=[]
var wind_material:StandardMaterial3D
var land
func mural(p:Node3D,point:Vector3,w:float,h:float,yaw:float,freestanding:=false)->void:
	var wall:=art.group(p,point);wall.rotation.y=yaw
	var backing:=art.box(wall,Vector3(0,h*.5+.20,0),Vector3(w+.32,h+.43,.33),"#b99c73")
	backing.material_override=Mat.sample(0,"#beaa87",2.6,true,.68)
	art.box(wall,Vector3(0,h+.44,0),Vector3(w+.64,.20,.54),"#ae7754")
	var picture:=MeshInstance3D.new();var mesh:=QuadMesh.new();mesh.size=Vector2(w,h)
	var patina:=StandardMaterial3D.new();patina.albedo_texture=preload("res://art/zephyr_fresco.png");patina.roughness=.99;patina.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	picture.mesh=mesh;picture.material_override=patina;wall.add_child(picture);picture.position=Vector3(0,h*.5+.21,.172)
	if freestanding:
		for s in [-1,1]:
			var foot:=art.box(wall,Vector3(s*(w*.5+.23),.39,0),Vector3(.71,.78,.76),"#ab9576");foot.material_override=Mat.sample(0,"#ae987b",1.7)
func leaves(terrain)->void:
	land=terrain;rng.seed=6779
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in land.leaves.size():
		var crown:Node3D=land.leaves[i]
		for j in 175:
			var lobe:=j%5;var ph:float=lobe*2.39+int(land.leaf_roots[i].x)
			# Leaf clusters are distributed over flattened, uneven volumes around the existing boughs.
			var point:=Vector3(cos(ph)*.75,.32+.27*sin(ph*2),sin(ph)*.64)
			var rad:=rng.randf_range(.36,1.05);var turn:=rng.randf_range(-PI,PI);var height:=rng.randf_range(-.39,.53)
			var center:=crown.to_global(point+Vector3(rad*cos(turn),height,rad*sin(turn)*.75))
			var axis:=Vector3(cos(turn),rng.randf_range(-.32,.40),sin(turn))*.24*rng.randf_range(.76,1.33)
			var side:=Vector3(-axis.z,.016,axis.x)*.30
			var tip:=center+axis;var middle:=center+axis*.47
			var tint:=Color("#496547").lerp(Color("#95a47b"),rng.randf()).srgb_to_linear()
			for v:Vector3 in [center,middle+side,tip,tip,middle-side,center]:
				st.set_color(tint);st.set_normal(Vector3.UP);st.set_uv(Vector2(0,center.distance_to(v)/maxf(.01,axis.length())));st.add_vertex(v)
	var n:=MeshInstance3D.new();n.mesh=st.commit();leaf_mat.shader=preload("res://zephyr_leaves.gdshader");n.material_override=leaf_mat
	land.add_child(n)
func sampler()->void:
	wind_material=StandardMaterial3D.new();wind_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;wind_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	wind_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;wind_material.albedo_color=Color(.85,.92,.80,.50);wind_material.vertex_color_use_as_albedo=true
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 12:
		var x:=i/12.;var y:=(i+1)/12.
		var a:=Vector3(x*4.4,.28*sin(x*PI*2),.23*sin(x*PI))
		var b:=Vector3(y*4.4,.28*sin(y*PI*2),.23*sin(y*PI))
		var wa:=Vector3.UP*(.004+.052*sin(x*PI));var wb:=Vector3.UP*(.004+.052*sin(y*PI))
		for pt:Vector3 in [a-wa,a+wa,b+wb,a-wa,b+wb,b-wb]:
			st.set_color(Color(1,1,1,.72));st.add_vertex(pt)
	var mesh:=st.commit()
	for i in 24:
		var n:=MeshInstance3D.new();n.mesh=mesh;n.material_override=wind_material;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		land.add_child(n);god_winds.append(n)
		var at:=Vector2(4.2+(i%12)*1.56,-1.5+sin(i*2.33)*3.1) if i<12 else Vector2(55.+(i%12)*1.82,12.1+sin(i*1.55)*2.72)
		region.append(at)
func tick(t:float,burst:Vector2,age:float)->void:
	leaf_mat.set_shader_parameter("wind_time",t);leaf_mat.set_shader_parameter("burst_at",burst);leaf_mat.set_shader_parameter("burst_age",age)
	for j in god_winds.size():
		var p:=region[j];var wind:=preload("res://zephyr_weather.gd").pressure(p,t)
		var n:=god_winds[j];n.visible=wind>.32
		if n.visible:
			var u:=fposmod(t*.49+j*.227,1.)
			var point:=p+Vector2(.40,.9165)*(u*5.6-2.75)
			n.position=land.surface(point)+Vector3.UP*(.66+(j%3)*.38+.3*sin(u*PI))
			n.rotation.y=-1.16;n.scale=Vector3(.38+.61*wind,clampf(1.4*sin(u*PI),.045,1.2),.70)
