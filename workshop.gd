extends RefCounted

# All gameplay props use the same toy-scale palette and matte surface finish.
const TEAL := "#176862"
const DARK := "#163e48"
const MINT := "#68b9a8"
const RED := "#d95e43"
const SAND := "#f5d49b"
const CREAM := "#fff0ca"
const GOLD := "#efa747"
const WOOD := "#885842"
const COBALT := "#455d93"
var mats := {}
var meshes := {}
var rng := RandomNumberGenerator.new()

func material(col: String) -> StandardMaterial3D:
	if not mats.has(col):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(col)
		m.roughness = 0.84
		mats[col] = m
	return mats[col]

func group(parent: Node3D, pos := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = pos
	return n

func shape(parent: Node3D, mesh: Mesh, pos: Vector3, col: String) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = material(col)
	parent.add_child(n)
	n.position = pos
	return n

func box(p: Node3D, pos: Vector3, size: Vector3, col: String) -> MeshInstance3D:
	if not meshes.has("box"):
		meshes.box = BoxMesh.new()
	var n := shape(p, meshes.box, pos, col)
	n.scale = size
	return n

func ball(p: Node3D, pos: Vector3, size: Vector3, col: String, faceted := false) -> MeshInstance3D:
	var key := "facet" if faceted else "ball"
	if not meshes.has(key):
		var mesh := SphereMesh.new()
		mesh.radial_segments = 9 if faceted else 20
		mesh.rings = 4 if faceted else 10
		meshes[key] = mesh
	var n := shape(p, meshes[key], pos, col)
	n.scale = size
	return n

func cyl(p: Node3D, pos: Vector3, bottom: float, top: float, height: float, col: String, sides := 16) -> MeshInstance3D:
	var key := str([bottom,top,height,sides])
	if not meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.bottom_radius = bottom
		mesh.top_radius = top
		mesh.height = height
		mesh.radial_segments = sides
		meshes[key] = mesh
	return shape(p, meshes[key], pos, col)

func beam(p: Node3D, a: Vector3, b: Vector3, radius: float, col: String) -> MeshInstance3D:
	var n := cyl(p, (a+b)*0.5, radius, radius, a.distance_to(b), col, 10)
	n.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
	return n

func ring(p: Node3D, pos: Vector3, radius: float, tube: float, col: String) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-tube
	mesh.outer_radius = radius+tube
	mesh.rings = 32
	mesh.ring_segments = 6
	return shape(p, mesh, pos, col)

func tile_roof(p: Node3D, center: Vector3, width: float, depth: float) -> void:
	for direction in [-1,1]:
		var roof := box(p, center+Vector3(0,0,direction*depth*0.25),Vector3(width,0.15,depth*0.54),RED)
		roof.rotation.x = direction*0.31
		var count := ceili(width/0.55)
		for i in count:
			var x := -width*0.5+(i+0.5)*width/count
			beam(p,center+Vector3(x,depth*0.08,0),center+Vector3(x,-depth*0.08,direction*depth*0.51),0.065,"#ec8058")

func window(p: Node3D, pos: Vector3, width: float, height: float) -> void:
	box(p,pos,Vector3(width+0.2,height+0.22,0.13),CREAM)
	box(p,pos+Vector3(0,0,0.09),Vector3(width,height,0.1),DARK)
	box(p,pos+Vector3(0,0,0.16),Vector3(0.07,height,0.05),SAND)
	box(p,pos+Vector3(0,0.09,0.16),Vector3(width,0.065,0.05),SAND)
	box(p,pos+Vector3(0,-height*0.54,0.11),Vector3(width+0.32,0.14,0.32),SAND)

func jar(p: Node3D, pos: Vector3, s: float, col: String) -> Node3D:
	var n := group(p,pos)
	n.scale = Vector3.ONE*s
	ball(n,Vector3(0,0.51,0),Vector3(0.86,1.02,0.86),col)
	cyl(n,Vector3(0,0.98,0),0.21,0.25,0.25,col)
	ring(n,Vector3(0,1.12,0),0.25,0.045,SAND)
	for d in [-1,1]:
		var handle := ring(n,Vector3(d*0.32,0.77,0),0.14,0.045,col)
		handle.rotation.x = PI/2
	return n

func cypress(p: Node3D, pos: Vector3, s: float) -> void:
	cyl(p,pos+Vector3.UP*s*0.41,0.13*s,0.08*s,0.82*s,WOOD)
	var crown := ball(p,pos+Vector3.UP*s*1.6,Vector3(0.97,2.9,0.99)*s,"#337c65",true)
	crown.rotation.z = 0.055*sin(pos.x*13)
	ball(p,pos+Vector3(-0.14,1.98,0.12)*s,Vector3(0.65,1.7,0.63)*s,"#559674",true)

func column(p: Node3D, pos: Vector3, h: float) -> void:
	box(p,pos+Vector3.UP*0.13,Vector3(0.85,0.26,0.85),SAND)
	cyl(p,pos+Vector3.UP*h*0.5,0.32,0.27,h,CREAM,12)
	cyl(p,pos+Vector3.UP*(h-0.19),0.35,0.4,0.18,SAND)
	box(p,pos+Vector3.UP*h,Vector3(0.78,0.2,0.78),CREAM)

func crate(p: Node3D, pos: Vector3, s: float) -> Node3D:
	var n := group(p,pos)
	n.scale = Vector3.ONE*s
	box(n,Vector3(0,0.43,0),Vector3(0.88,0.86,0.86),"#c68f56")
	for x in [-0.35,0.35]:
		box(n,Vector3(x,0.44,0.44),Vector3(0.11,0.88,0.05),WOOD)
	var brace := box(n,Vector3(0,0.46,0.465),Vector3(0.11,1.03,0.055),SAND)
	brace.rotation.z = -0.72
	return n

func moon(p: Node3D, pos: Vector3, s: float) -> void:
	# Golden crescent ornament with a real gap, visible in silhouette.
	var previous := Vector3.ZERO
	for i in 13:
		var a := lerpf(-1.18,3.84,i/12.0)
		var point := pos+Vector3(cos(a)*s,sin(a)*s,0)
		if i>0:
			beam(p,previous,point,s*(0.05+0.19*sin(PI*(i-0.5)/12.0)),GOLD)
		previous = point

func hero(parent: Node3D, id: String) -> Node3D:
	var scene: PackedScene=load("res://art/"+id+".glb")
	var n: Node3D=scene.instantiate()
	parent.add_child(n)
	return n

func bed(p: Node3D) -> Node3D:
	return hero(p,"moon_couch")

func sack(p: Node3D) -> Node3D:
	return hero(p,"wind_sack")

func courier(p: Node3D, speaking_role:=false) -> Node3D:
	var n:=group(p)
	hero(n,"courier_acting" if speaking_role else "courier_body")
	for side in [-1,1]:
		var leg:=group(n,Vector3(side*0.19,0.49,0))
		leg.name="LegL" if side<0 else "LegR"
		hero(leg,"courier_boot")
		var arm:=group(n,Vector3(side*0.38,1.18,0))
		arm.name="ArmL" if side<0 else "ArmR"
		hero(arm,"courier_arm_l" if side<0 else "courier_arm_r")
	return n

func trolley(p: Node3D) -> Node3D:
	var n:=group(p)
	box(n,Vector3(0,0.29,0),Vector3(1.36,0.19,2.73),TEAL)
	for k in 7:
		box(n,Vector3(0,0.4,-1.15+k*0.38),Vector3(1.34,0.08,0.366),"#b98455")
	for z in [-1.1,1.1]:
		for x in [-0.49,0.49]:
			var wheel:=cyl(n,Vector3(x,0.16,z),0.17,0.17,0.09,DARK)
			wheel.rotation.z=PI/2
	for j in 2:
		var amphora:=hero(n,"wine_urn")
		amphora.name="Amphora"+str(j)
		amphora.position=Vector3(0,0.43,-0.63+j*1.2)
		amphora.scale=Vector3.ONE*(0.83 if j==0 else 0.76)
	for side in [-1,1]:
		beam(n,Vector3(side*0.58,0.36,-1.28),Vector3(side*0.58,0.94,-1.39),0.059,GOLD)
	beam(n,Vector3(-0.58,0.94,-1.39),Vector3(0.58,0.94,-1.39),0.064,WOOD)
	return n

func truck(p: Node3D) -> Node3D:
	var n:=hero(p,"westwind")
	# A gilt delivery seal and featherwork read from the chase camera.
	var badge:=cyl(n,Vector3(-3.08,1.10,0),0.23,0.23,0.07,GOLD)
	badge.rotation.z=PI/2
	for side in [-1,1]:
		for j in 3:
			var feather:=ball(n,Vector3(-3.13,1.12+0.065*j,side*(0.24+j*0.11)),Vector3(0.07,0.11,0.28),CREAM,true)
			feather.rotation.x=side*0.32
	var chauffeur:=courier(n)
	chauffeur.name="Driver"
	chauffeur.position=Vector3(1.86,1.27,0.51)
	chauffeur.rotation.y=1.02
	chauffeur.scale=Vector3.ONE*0.57
	chauffeur.get_node("ArmL").rotation.x=-0.97
	chauffeur.get_node("ArmR").rotation.x=-0.97
	var wheel:=ring(n,Vector3(2.18,1.80,0.51),0.15,0.025,DARK)
	wheel.rotation.z=1.04
	for x in [-1.89,2.20]:
		for side in [-1,1]:
			var spokes:=group(n,Vector3(x,0.54,side*1.36))
			spokes.add_to_group("wheels")
			for angle in [0.0,PI/3,2*PI/3]:
				var spoke:=box(spokes,Vector3.ZERO,Vector3(0.36,0.038,0.013),GOLD)
				spoke.rotation.z=angle
	return n

func prop(p: Node3D, asset: String, pos: Vector3, height: float, yaw:=0.0) -> Node3D:
	var outer:=group(p,pos)
	var scene: PackedScene=load("res://art/"+asset+".glb")
	var body: Node3D=scene.instantiate()
	outer.add_child(body)
	var bounds:=AABB()
	var first:=true
	for n in body.find_children("*","MeshInstance3D",true,false):
		for surface in n.mesh.get_surface_count():
			var source: Material=n.mesh.surface_get_material(surface)
			if source is StandardMaterial3D:
				var key: String="kit_"+source.resource_name
				if not mats.has(key):
					var tuned: StandardMaterial3D=source.duplicate()
					tuned.metallic=0
					tuned.roughness=0.82
					var palette={"grass":"#638b51","leaf":"#517b56","leaves":"#548662","wood":"#9b704e","stone":"#918c87","rock":"#8d8b83","dirt":"#a77c57","flowerPurple":"#ad7cb3","flowerRed":"#ce6758"}
					if palette.has(source.resource_name): tuned.albedo_color=Color(palette[source.resource_name])
					mats[key]=tuned
				n.set_surface_override_material(surface,mats[key])
		var relative: Transform3D=outer.global_transform.affine_inverse()*n.global_transform
		var ab: AABB=relative*n.get_aabb()
		bounds=ab if first else bounds.merge(ab)
		first=false
	if not first:
		var s:=height/maxf(0.01,bounds.size.y)
		var center:=bounds.get_center()
		body.scale=Vector3.ONE*s
		body.position=-Vector3(center.x,bounds.position.y,center.z)*s
	outer.rotation.y=yaw
	return outer


