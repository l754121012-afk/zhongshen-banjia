extends RefCounted

const CLAY:=preload("res://votive_clay.gdshader")
const PROFILE:=[Vector2(.02,.02),Vector2(.27,.02),Vector2(.31,.078),Vector2(.30,.12),Vector2(.23,.16),Vector2(.26,.235),Vector2(.38,.30),Vector2(.435,.35),Vector2(.47,.48),Vector2(.469,.56),Vector2(.445,.64),Vector2(.425,.70),Vector2(.403,.85),Vector2(.37,.975),Vector2(.375,1.08),Vector2(.409,1.10),Vector2(.41,1.15),Vector2(.35,1.18),Vector2(.28,1.23),Vector2(.19,1.29),Vector2(.123,1.315),Vector2(.088,1.285)]
static var shell:ArrayMesh
static var handle_mesh:ArrayMesh
static var glaze:ShaderMaterial
static var brass:StandardMaterial3D

static func shell_point(i:int,j:int)->Vector3:
	var az:=TAU*j/72.0
	var r:float=PROFILE[i].x
	return Vector3(r*cos(az),PROFILE[i].y,r*sin(az))

static func make_shell()->ArrayMesh:
	var surf:=SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in PROFILE.size()-1:
		for j in 72:
			# Twelve openings pierced through the clay. The wick is visible behind them.
			if row in [11,12] and j%6 in [2,3]:continue
			for pair:Vector2i in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
				var i:=row+pair.x;var k:=j+pair.y
				var slope:Vector2=PROFILE[mini(i+1,PROFILE.size()-1)]-PROFILE[maxi(0,i-1)]
				var az:=TAU*k/72.
				surf.set_normal(Vector3(cos(az)*slope.y,-slope.x,sin(az)*slope.y).normalized())
				surf.add_vertex(shell_point(i,k))
	return surf.commit()

static func loop_point(t:float,side:int)->Vector3:
	return Vector3(side*(.345+.25*sin(PI*t)),.64+.52*t-.10*sin(TAU*t),.014)

static func make_handles()->ArrayMesh:
	var surf:=SurfaceTool.new();surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1,1]:
		for i in 18:
			for j in 7:
				for v:Vector2i in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(1,0)]:
					var u:float=(i+v.x)/18.;var c:=loop_point(u,side)
					var tangent:Vector3=(loop_point(u+.001,side)-loop_point(u-.001,side)).normalized()
					var az:=TAU*(j+v.y)/7.
					var normal:=Vector3.BACK*cos(az)+tangent.cross(Vector3.BACK)*sin(az)
					surf.set_normal(normal);surf.add_vertex(c+normal*(.053+.018*pow(absf(u*2.-1.),3.)))
	return surf.commit()

static func build(parent:Node3D,at:Vector3,art)->Node3D:
	if shell==null:
		shell=make_shell();handle_mesh=make_handles()
		glaze=ShaderMaterial.new();glaze.shader=CLAY
		brass=StandardMaterial3D.new();brass.albedo_color=Color("#ba854d");brass.metallic=.49;brass.roughness=.41;brass.cull_mode=BaseMaterial3D.CULL_DISABLED
	var jar:Node3D=art.group(parent,at)
	var body:=MeshInstance3D.new();body.mesh=shell;body.material_override=glaze;jar.add_child(body)
	var loops:=MeshInstance3D.new();loops.mesh=handle_mesh;loops.material_override=brass;jar.add_child(loops)
	art.cyl(jar,Vector3.UP*.77,.30,.24,.48,"#302c2b",18)
	var lug:Node3D=art.ring(jar,Vector3.UP*1.40,.124,.031,"#9d754b")
	lug.rotation.x=PI/2.
	return jar

