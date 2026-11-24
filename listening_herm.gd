extends RefCounted

const Art:=preload("res://workshop.gd")
const LIMESTONE:="#cfbb94"
const WARM:="#b39d7a"
const COOL:="#77928b"
const DARK:="#5d7067"
const GOLD:="#c4a269"
var art:=Art.new()

# The harbor's herm faces the water with a hand cupped around one ear.
# A single stepped plinth and the leaning bronze shell form its silhouette at sea.
func build(parent:Node3D,at:Vector3,yaw:float,factor:float)->Node3D:
	var monument:=art.group(parent,at);monument.rotation.y=yaw;monument.scale=Vector3.ONE*factor
	art.box(monument,Vector3.UP*.16,Vector3(2.30,.32,1.95),WARM)
	art.box(monument,Vector3.UP*.43,Vector3(1.98,.24,1.67),LIMESTONE)
	art.box(monument,Vector3.UP*.74,Vector3(1.58,.45,1.36),COOL)
	art.box(monument,Vector3.UP*.99,Vector3(1.76,.14,1.51),GOLD)
	for side in [-1,1]:
		art.box(monument,Vector3(side*.69,.76,.696),Vector3(.08,.34,.06),GOLD)
	var torso:=art.group(monument,Vector3.UP*1.02)
	var folds:=[Vector3(.02,0,0),Vector3(.03,.20,0),Vector3(.01,.82,-.02),Vector3(-.04,1.38,-.01),Vector3(-.08,1.60,.01),Vector3(-.12,1.70,.02)]
	var widths:=[.76,.80,.68,.79,.60,.28]
	var depths:=[.50,.55,.42,.43,.39,.23]
	sculpt(torso,folds,widths,depths,true)
	var head:=art.group(torso,Vector3(-.10,1.65,.02));head.rotation=Vector3(-.06,-.22,.19)
	var skull:=[Vector3(0,0,.12),Vector3(0,.12,.06),Vector3(0,.28,.03),Vector3(0,.52,0),Vector3(0,.71,-.01),Vector3(0,.83,-.02),Vector3(0,.89,-.03)]
	sculpt(head,skull,[.14,.25,.34,.38,.34,.23,.045],[.18,.27,.31,.32,.31,.24,.055],false)
	for side in [-1.,1.]:
		var brow:=art.ball(head,Vector3(side*.155,.52,.282),Vector3(.22,.069,.073),WARM);brow.rotation.z=side*.14
		art.beam(head,Vector3(side*.063,.46,.319),Vector3(side*.225,.49,.271),.015,DARK)
	art.ball(head,Vector3(.008,.36,.322),Vector3(.094,.23,.135),LIMESTONE)
	art.beam(head,Vector3(-.073,.215,.30),Vector3(.071,.207,.30),.016,WARM)
	for j in 12:
		var a:=TAU*j/12.
		if cos(a)>.58:continue
		var lock:=art.ball(head,Vector3(sin(a)*.30,.52,cos(a)*.26),Vector3(.20,.62,.19),WARM)
		lock.rotation.z=-.23*sin(a)
	var crown:=art.ring(head,Vector3.UP*.70,.33,.037,GOLD);crown.scale.z=.84
	# Shell opening and a spiral remain legible when backlit.
	var shell:=art.group(head,Vector3(-.43,.43,.11));shell.rotation=Vector3(.18,-.58,.22)
	var rim:=art.ring(shell,Vector3.ZERO,.27,.067,COOL);rim.rotation.x=PI/2;rim.scale.y=1.32
	for i in 11:
		var u:=i/11.;var v:=(i+1)/11.
		var a:=u*TAU*1.19;var b:=v*TAU*1.19
		var from:=Vector3(cos(a)*(.22-.18*u),sin(a)*(.27-.22*u),.03+.06*u)
		var to:=Vector3(cos(b)*(.22-.18*v),sin(b)*(.27-.22*v),.03+.06*v)
		art.beam(shell,from,to,.032,GOLD)
	art.beam(torso,Vector3(-.58,1.36,0),Vector3(-.88,1.10,.30),.162,LIMESTONE)
	art.beam(torso,Vector3(-.88,1.10,.30),Vector3(-.67,1.94,.27),.129,WARM)
	var palm:=art.ball(torso,Vector3(-.62,1.99,.29),Vector3(.21,.285,.125),LIMESTONE);palm.rotation.z=-.33
	for i in 3:art.beam(torso,Vector3(-.71+i*.046,2.025,.30),Vector3(-.72+i*.048,2.18-i*.012,.25),.025,LIMESTONE)
	return monument

func sculpt(parent:Node3D,centers:Array,widths:Array,depths:Array,draped:bool)->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in centers.size()-1:
		for j in 36:
			for v:Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var row:=i+v.x;var az:=TAU*(j+v.y)/36.
				var crease:=maxf(0.,sin(az*8.+row*.49))
				var r:=1.+(.085*crease if draped else 0.)
				var c:Vector3=centers[row]
				st.set_normal(Vector3(sin(az),.09 if row<4 else .38,cos(az)).normalized())
				st.set_color(Color(LIMESTONE).darkened((.105*crease if draped else .04)*(.45+.55*cos(az))))
				st.add_vertex(c+Vector3(float(widths[row])*sin(az),0,float(depths[row])*cos(az))*r)
	var m:=StandardMaterial3D.new();m.vertex_color_use_as_albedo=true;m.cull_mode=BaseMaterial3D.CULL_DISABLED;m.roughness=.90
	var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=m;parent.add_child(mesh)

