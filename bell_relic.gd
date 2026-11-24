extends RefCounted
# A clay listening horn. Both the hand-held rim and the missing portion use the same profile.
var art:=preload("res://workshop.gd").new()
const SEAM_A:=.23
const SEAM_B:=1.52
const SECTION:=[Vector2(.10,-.39),Vector2(.22,-.25),Vector2(.38,-.06),Vector2(.63,.115),Vector2(.84,.21),Vector2(.87,.24),Vector2(.86,.32),Vector2(.79,.32),Vector2(.66,.26),Vector2(.46,.15),Vector2(.29,-.018),Vector2(.17,-.18),Vector2(.09,-.31)]
const CLAY:=Color("#a86549")
const SAND:=Color("#ecbb80")
const ENAMEL:=Color("#407f78")
const DARK:=Color("#735544")

func vtx(radial:int,a:float)->Vector3:
	var q:Vector2=SECTION[radial]
	# A slightly uneven lip and curled upper ear keep the two sides identifiable.
	var radius:=q.x*(1.+.045*sin(2.*a+.33))
	return Vector3(cos(a)*radius*.91,sin(a)*radius*1.07,q.y+sin(a)*.066*q.x)

func tint(k:int,a:float)->Color:
	if k==4 or k==7:return SAND
	if k in [5,6]:return ENAMEL.lightened(.10 if int(floor(a*12.))%3==0 else 0.)
	if k>=9:return CLAY.lerp(DARK,(k-8)*.17)
	return CLAY.lightened((.08 if k>2 else 0.)+.025*sin(a*7.))

func segment(parent:Node3D,a0:float,a1:float,lo:int,hi:int)->Node3D:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count:=maxi(5,ceili((a1-a0)*10.5))
	for i in count:
		var a:=lerpf(a0,a1,float(i)/count)
		var b:=lerpf(a0,a1,float(i+1)/count)
		for k in range(lo,hi):
			for q:Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				st.set_color(tint(k,a));st.add_vertex(vtx(k+q.x,a if q.y==0 else b))
	# A raw terracotta surface is visible along a broken edge.
	for angle:float in [a0,a1]:
		for k in range(lo,hi):
			for point in [vtx(k,angle),vtx(k+1,angle),Vector3(.35*cos(angle),.35*sin(angle),-.02)]:
				st.set_color(SAND.darkened(.18));st.add_vertex(point)
	st.generate_normals();var mesh:=MeshInstance3D.new();mesh.mesh=st.commit()
	var glaze:=StandardMaterial3D.new();glaze.vertex_color_use_as_albedo=true;glaze.vertex_color_is_srgb=true
	glaze.cull_mode=BaseMaterial3D.CULL_DISABLED;glaze.roughness=.68;mesh.material_override=glaze
	parent.add_child(mesh);return mesh

func make_horn(parent:Node3D)->Node3D:
	var horn:=art.group(parent)
	segment(horn,SEAM_B,TAU+SEAM_A,0,12)
	segment(horn,SEAM_A,SEAM_B,0,2)
	segment(horn,SEAM_A,SEAM_B,10,12)
	art.ball(horn,Vector3(0,0,-.31),Vector3(.22,.22,.12),"#604739")
	# The traced spiral is an old potter's mark, visible even without the fragment.
	var last:=Vector3.ZERO
	for i in 21:
		var u:=i/20.;var a:=2.2+3.4*u;var r:=.19+.35*u
		var here:=Vector3(cos(a)*r*.91,sin(a)*r*1.07,-.17+.44*u)
		if i>0:art.beam(horn,last,here,.016,"#e4ad72")
		last=here
	return horn

func shard(parent:Node3D)->Node3D:
	var piece:=art.group(parent);segment(piece,SEAM_A,SEAM_B,2,10)
	return piece

