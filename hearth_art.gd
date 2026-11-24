extends RefCounted
const A=preload("res://workshop.gd")
var a:=A.new()
var flame:Node3D
var embers:Array[MeshInstance3D]=[]
func build(p:Node3D)->Node3D:
	var n:=a.group(p)
	for x in [-.4,.4]:
		for z in [-.37,.37]:a.box(n,Vector3(x,.14,z),Vector3(.14,.28,.15),"#494544")
	a.box(n,Vector3.UP*.67,Vector3(.99,.84,.91),"#544a43")
	for j in 4:
		for i in 3:
			a.box(n,Vector3((i-1)*.325,.36+j*.18,-.47),Vector3(.30,.16,.06),"#a96143" if (i+j)%3 else "#c07a56")
	for x in [-.51,.51]:
		a.box(n,Vector3(x,.69,0),Vector3(.08,.91,1.02),"#69513d")
		for z in [-.43,.43]:a.ball(n,Vector3(x*1.09,.97,z),Vector3.ONE*.095,"#d1a168")
	for z in [-1,1]:
		a.beam(n,Vector3(0,.67,z*.43),Vector3(0,.67,z*1.19),.067,"#474947")
		a.beam(n,Vector3(-.20,.67,z*1.19),Vector3(.20,.67,z*1.19),.069,"#ab8055")
	a.box(n,Vector3.UP*1.14,Vector3(1.14,.10,1.01),"#a67c51")
	a.cyl(n,Vector3(.26,1.39,-.23),.13,.11,.48,"#454846")
	flame=a.group(n,Vector3(-.535,.67,0))
	a.box(flame,Vector3(.011,0,0),Vector3(.105,.53,.77),"#2e302e")
	a.box(flame,Vector3(-.068,-.19,.0),Vector3(.36,.065,.82),"#957153")
	for i in 5:
		var e:=a.ball(flame,Vector3(-.091,.03*sin(i),(.12*i)-.24),Vector3(.11,.32,.14),"#ffc65c",true)
		var mat:=StandardMaterial3D.new();mat.emission_enabled=true;e.material_override=mat;embers.append(e)
	for j in 3:
		a.beam(flame,Vector3(-.172,-.19,(j-1)*.19),Vector3(-.172,.21,(j-1)*.19),.026,"#554b3c")
	var door:=a.group(flame,Vector3(-.10,-.18,.37));door.rotation.y=.7
	a.box(door,Vector3(-.18,.13,.02),Vector3(.38,.38,.07),"#67513b")
	return n
func glow(heat:float,t:float)->void:
	for i in embers.size():
		var e:=embers[i];var m:=e.material_override as StandardMaterial3D
		var c:=Color("#433c39").lerp(Color("#d4572d"),smoothstep(0,40,heat)).lerp(Color("#ffad45"),smoothstep(45,85,heat))
		m.albedo_color=c;m.emission=c;m.emission_energy_multiplier=heat*.0076
		e.scale.y=.09+.30*(heat/100.)*(.83+.17*sin(t*8+i))
