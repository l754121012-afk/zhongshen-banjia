extends Node3D
const Art=preload("res://workshop.gd")
var art:=Art.new()
var town=preload("res://district.gd").new()
func build()->void:
	# Back the waterfront with staggered limestone shelves; the skyline guides the return drive.
	for i in 22:
		var x:=float(i*10-14)
		var shelf:=Vector3(x,-2.7,-42-4*sin(i*0.8))
		var rise:=8.0+5.0*sin(i*0.43+0.5)
		art.ball(self,shelf,Vector3(23,rise*2,21),"#c4ae90",true)
		art.ball(self,shelf+Vector3(0,rise-1.15,0),Vector3(14,2.4,13),"#92a075",true)
		for j in 2:
			var lot:=shelf+Vector3(-2+j*4,rise-0.35,-j*2)
			town.house(self,lot,0.95+0.3*j,"#f2dec1" if i%2 else "#e5d3ae")
			art.cypress(self,lot+Vector3(1.9,0,1.2),1.2)
	for i in 5:
		var p:=Vector3(16+i*15,-2.26,-25-i%2*4)
		var boat:=art.group(self,p)
		boat.rotation.y=0.42+i*0.55
		art.ball(boat,Vector3.ZERO,Vector3(4.8,0.70,1.64),Art.WOOD,true)
		art.beam(boat,Vector3.ZERO,Vector3(0,3.8,0),0.06,Art.WOOD)
		var sail:=SurfaceTool.new()
		sail.begin(Mesh.PRIMITIVE_TRIANGLES)
		for pt:Vector3 in [Vector3(0,3.65,0),Vector3(-1.85,0.65,0.05),Vector3(0,0.72,0.29)]:
			sail.set_normal(Vector3.BACK)
			sail.add_vertex(pt)
		var sheet:=MeshInstance3D.new()
		sheet.mesh=sail.commit()
		var cotton:=art.material(Art.CREAM).duplicate() as StandardMaterial3D
		cotton.cull_mode=BaseMaterial3D.CULL_DISABLED
		sheet.material_override=cotton
		boat.add_child(sheet)
	# Blue shade cloth, flowering vines and terracotta at playable stops.
	for site in [Vector3(-5,0,-2.65),Vector3(3,0,11.9),Vector3(175,0,10.1)]:
		for j in 8:
			var awning:=art.box(self,site+Vector3(-1.96+j*0.55,2.75,0),Vector3(0.56,0.12,1.30),Art.CREAM if j%2 else "#367c98")
			awning.rotation.x=-0.14
		for side in [-1,1]:
			var foot:Vector3=site+Vector3(side*2.25,0,0)
			art.jar(self,foot,0.84,"#b96f54")
			for j in 6:
				var stem:=foot+Vector3(sin(j*1.4)*0.26,0.98+j*0.30,cos(j)*0.20)
				art.ball(self,stem,Vector3(0.65,0.48,0.52),"#608659",true)
				art.ball(self,stem+Vector3(0.12,0.12,0.15),Vector3(0.38,0.27,0.28),"#cc5981",true)
	var beacon:=Vector3(169,-2.0,20.5)
	art.ball(self,beacon,Vector3(11,4,9),"#beab88",true)
	art.cyl(self,beacon+Vector3.UP*5,2.0,1.2,7,Art.CREAM)
	art.cyl(self,beacon+Vector3.UP*8.9,1.55,1.55,0.45,Art.TEAL)
	art.ball(self,beacon+Vector3.UP*9.8,Vector3(1.55,1.8,1.55),Art.GOLD)
	art.cyl(self,beacon+Vector3.UP*10.9,1.70,0.05,1.25,Art.RED)

	# The port rises behind the temple, so the destination reads from the bridge.
	for row in 3:
		var x:=212.0+row*8.0
		for lot in range(-2,3):
			var z:=lot*7.5+row%2*2.3
			var h:=3.5+row*3.1+1.3*cos(lot*0.8)
			art.ball(self,Vector3(x,-2.7,z),Vector3(20,h*2.0,13),"#bda58a",true)
			var terrace:=Vector3(x,h-3.2,z)
			art.box(self,terrace,Vector3(7.2,0.68,6.8),"#d6c3a1")
			town.house(self,terrace+Vector3.UP*0.3,1.25+0.12*((lot+3)%3),"#f2e0c3")
			art.cypress(self,terrace+Vector3(-2.8,0.35,1.9),1.12)
	for k in 8:
		art.ball(self,Vector3(252+10*sin(k),-3,-64+k*16),Vector3(39,33+9*cos(k),32),"#8ca9a5",true)
	for site in [Vector3(-6,0.071,2),Vector3(185,0.071,1),Vector3(3,0.071,9),Vector3(167,0.071,11)]:
		var paving:=art.box(self,site,Vector3(9.8,0.040,5.8),"#cdc3a4")
		town.pave(paving,"#c9ba9e","#a89d8b")
		for dx in [-4.72,4.72]:
			art.box(self,site+Vector3(dx,0.030,0),Vector3(0.11,0.035,5.65),Art.TEAL)
		for dz in [-2.73,2.73]:
			art.box(self,site+Vector3(0,0.030,dz),Vector3(9.45,0.035,0.11),Art.TEAL)