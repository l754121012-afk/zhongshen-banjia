extends RefCounted
const Art=preload("res://workshop.gd")
const B=preload("res://tide_art.gd")
var a:=Art.new()
var people:Array[Node3D]=[]
var homes:Array[Vector3]=[]
var goals:Array[Vector3]=[]
var cords:Array[Node3D]=[]
var pennants:Array[Node3D]=[]
var smoke_mat:=StandardMaterial3D.new()
var flutter:=0.
func flag_mesh()->ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v:Vector3 in [Vector3(0,0,-.32),Vector3(.045,0,.32),Vector3(.14,-.83,-.035)]:
		st.set_normal(Vector3.LEFT);st.add_vertex(v)
	return st.commit()
func string_lights(mill:Node3D,begin:Vector3,end:Vector3)->void:
	var n:=a.group(mill,begin);cords.append(n)
	var mesh:=flag_mesh();var off:=end-begin
	for i in 12:
		var u:=float(i)/12.;var v:=float(i+1)/12.
		var q:=off*u-Vector3.UP*sin(u*PI)*.64
		var r:=off*v-Vector3.UP*sin(v*PI)*.64
		a.beam(n,q,r,.035,"#967f5b")
		var f:=MeshInstance3D.new();f.mesh=mesh
		var m:=a.material(["#347e80","#e6c27e","#aa6149","#e3cfaa"][i%4]).duplicate() as StandardMaterial3D
		m.cull_mode=BaseMaterial3D.CULL_DISABLED;f.material_override=m;n.add_child(f);f.position=q.lerp(r,.52)
		pennants.append(f)
func build(land)->void:
	var mill:Node3D=land.tower_root
	string_lights(mill,Vector3(-2.74,5.10,-1.68),Vector3(-3.91,4.57,-10.32))
	string_lights(mill,Vector3(-2.88,4.85,-1.85),Vector3(-6.87,3.74,-8.23))
	var pole:=a.beam(mill,Vector3(-6.87,0,-8.23),Vector3(-6.87,3.88,-8.23),.075,"#907557")
	for i in 3:
		var citizen:=a.courier(mill);people.append(citizen);land.people.costume(citizen,"priest" if i==0 else ("baker" if i==1 else "miller"))
		citizen.scale=Vector3.ONE*[.91,.70,.95][i]
		var start:Vector3=[Vector3(-2.3,0,-10.3),Vector3(-3.1,0,-9.7),Vector3(-2.8,0,-8.2)][i]
		var dest:Vector3=[Vector3(-5.3,0,-6.9),Vector3(-6.2,0,-7.82),Vector3(-4.7,0,-6.1)][i]
		homes.append(start);goals.append(dest);citizen.position=start
		if i==0:
			var basket:=a.cyl(citizen,Vector3(.41,.82,.21),.21,.31,.36,"#aa8554",10)
			a.ring(citizen,Vector3(.41,1.03,.22),.22,.035,"#9a7444").rotation.x=PI/2
	# A translucent pressure plume anchored in the chimney diffuses into sea air.
	var grad:=Gradient.new();grad.offsets=PackedFloat32Array([0.,.39,.76,1.]);grad.colors=PackedColorArray([Color(.85,.82,.73,.45),Color(.87,.85,.77,.34),Color(.88,.87,.80,.11),Color(.85,.84,.8,0)])
	var tex:=GradientTexture2D.new();tex.gradient=grad;tex.width=96;tex.height=96;tex.fill=GradientTexture2D.FILL_RADIAL;tex.fill_from=Vector2(.50,.50);tex.fill_to=Vector2(1.,.50)
	smoke_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;smoke_mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	smoke_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;smoke_mat.albedo_texture=tex;smoke_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	var puff:=QuadMesh.new();puff.size=Vector2(2.,1.76)
	for plume:MeshInstance3D in land.bakery_smoke:plume.mesh=puff;plume.material_override=smoke_mat;plume.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func tick(t:float,level:float)->void:
	var open:=smoothstep(1.03,1.97,level)
	for i in cords.size():
		cords[i].visible=open>.05;cords[i].scale.y=.44+.56*open
		cords[i].position.y=(5.10 if i==0 else 4.85)-1.4*(1.-open)
	for i in pennants.size():
		pennants[i].scale.y=.06+.94*open
		pennants[i].rotation.z=-.24-.18*sin(t*4+i*.72)
	for i in people.size():
		var n:=people[i];var walk:=smoothstep(i*.12,.84+i*.075,open)
		n.visible=walk>.04
		if not n.visible:continue
		n.position=homes[i].lerp(goals[i],walk);n.rotation.y=-2.05+i*.29
		var stride:=sin(walk*17)*sin(walk*PI)
		n.get_node("LegL").rotation.x=stride*.52;n.get_node("LegR").rotation.x=-stride*.52
		n.get_node("ArmR").rotation.x=-.55-.29*sin(t*2.1+i)
