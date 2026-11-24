extends RefCounted
const W=preload("res://workshop.gd")
var w=W.new()
var d=preload("res://district.gd").new()
var truck: Node3D
var trolley: Node3D
var hook: Node3D
var cable: MeshInstance3D
var shadow: MeshInstance3D
var target_rings: Array[Node3D]=[]
var customers: Array[Node3D]=[]
var lanterns: Array[Node3D]=[]
var slots: Array[float]=[1.52,4.97]

func build(p: Node3D,expert: bool) -> void:
	var sea=w.box(p,Vector3(0,-1.68,0),Vector3(120,0.25,42),"#539aa2")
	var waves:=ShaderMaterial.new()
	waves.shader=preload("res://coast.gdshader")
	sea.material_override=waves
	w.box(p,Vector3(0,-0.45,0.12),Vector3(17.6,0.72,7.04),"#947a68")
	for k in 27:
		w.box(p,Vector3(-8.47+k*0.654,-0.025,0.18),Vector3(0.625,0.16,6.93),"#bb946e" if k%3==0 else "#cfa982")
	for x in [-8,-4,0,4,8]:
		for z in [-3.1,3.41]:
			w.cyl(p,Vector3(x,-0.8,z),0.19,0.20,2.24,W.WOOD)
			w.ring(p,Vector3(x,0.14,z),0.21,0.041,W.SAND)
	for i in 5:
		w.box(p,Vector3(-7.9+i*3.67,0.33,3.35),Vector3(0.36,0.62,0.36),W.WOOD)
		if i<4: w.beam(p,Vector3(-7.9+i*3.67,0.50,3.35),Vector3(-4.23+i*3.67,0.50,3.35),0.042,W.SAND)
	truck=w.truck(p)
	truck.position=Vector3(-4.1,0.09,0.26)
	for x in [0.0,3.4,6.94]:
		w.column(p,Vector3(x,0.1,-2.93),2.87)
	w.box(p,Vector3(3.43,3.09,-2.95),Vector3(7.87,0.37,1.4),W.CREAM)
	d.house(p,Vector3(8.16,0.1,-2.85),0.86,"#f0ceaa")
	w.tile_roof(p,Vector3(3.43,3.47,-3.03),8.0,2.43)
	for i in 2:
		var x: float=slots[i]
		var pad=w.cyl(p,Vector3(x,0.12,0.55),1.35,1.35,0.17,W.TEAL if i==0 else W.RED,36)
		pad.scale.z=0.79
		var ring=w.ring(p,Vector3(x,0.225,0.55),1.18,0.065,W.CREAM)
		ring.scale.z=0.79
		target_rings.append(ring)
		var plate=w.box(p,Vector3(x,0.46,1.95),Vector3(2.15,0.54,0.14),W.TEAL if i==0 else W.RED)
		d.sign_text(p,("酒神" if expert else "睡神") if i==0 else "风神",Vector3(x,0.48,2.034),0.0058)
		customers.append(patron(p,Vector3(x,0.12,-1.49),i,expert))
	for x in [-7.70,7.20]:
		w.cyl(p,Vector3(x,2.82,-1.44),0.19,0.115,5.58,W.TEAL)
		w.box(p,Vector3(x,0.25,-1.44),Vector3(0.68,0.38,0.66),W.CREAM)
		w.beam(p,Vector3(x,4.45,-1.44),Vector3(x+(-0.91 if x>0 else 0.91),5.43,-1.44),0.087,W.GOLD)
	w.box(p,Vector3(-0.25,5.58,-1.44),Vector3(15.59,0.23,0.29),W.TEAL)
	w.box(p,Vector3(-0.25,5.71,-1.44),Vector3(15.60,0.054,0.33),W.GOLD)
	trolley=w.group(p)
	w.box(trolley,Vector3(0,0,0),Vector3(0.59,0.37,0.46),W.RED)
	w.beam(trolley,Vector3(0,0.02,0),Vector3(0,0.02,1.98),0.068,W.GOLD)
	hook=w.group(p)
	w.cyl(hook,Vector3.ZERO,0.15,0.16,0.22,W.GOLD)
	cable=w.cyl(p,Vector3.ZERO,0.024,0.024,1.0,W.DARK,8)
	shadow=w.cyl(p,Vector3.ZERO,0.68,0.68,0.015,"#968168",32)
	shadow.scale.z=0.67
	for j in 4:
		var x=-7.25+j*0.82
		w.crate(p,Vector3(x,0.06,-2.54),0.59+j%2*0.19)
	w.jar(p,Vector3(6.55,0.09,1.74),0.75,W.RED)
	w.cypress(p,Vector3(7.8,0.1,1.75),1.06)

func patron(p: Node3D,pos: Vector3,id: int,expert: bool) -> Node3D:
	var n: Node3D=w.hero(p,"patron_wind" if id==1 else "patron_wine") if id==1 or expert else w.courier(p)
	n.position=pos
	n.scale=Vector3.ONE*1.03
	n.rotation.y=-0.19 if id==1 else 0.16
	if id==0 and not expert:
		var clipboard=w.box(n,Vector3(-0.32,0.97,0.28),Vector3(0.35,0.49,0.048),W.WOOD)
		clipboard.rotation.z=-0.15
		w.box(clipboard,Vector3(0,0,0.51),Vector3(0.81,0.82,0.15),W.CREAM)
	return n

func rope(x: float,tip: Vector3) -> void:
	trolley.position=Vector3(x,5.45,-1.44)
	var top:=Vector3(x,5.42,0.54)
	var vector:=top-tip
	cable.position=(top+tip)*0.5
	cable.quaternion=Quaternion(Vector3.UP,vector.normalized())
	cable.scale.y=maxf(0.02,vector.length())
	hook.position=tip
	shadow.position=Vector3(tip.x,0.23,tip.z)


