extends Node3D

const Art=preload("res://workshop.gd")
var a:=Art.new()
var job
var token:Node3D
var pennant:Node3D
var plaque:MeshInstance3D
var coins:Node3D
var age:=-1.
var landing:=false
var first:=true
var ended:=false
var pose:=preload("res://speaker_pose.gd").new()
var start_view:Transform3D

func build(n)->void:
	job=n
	token=a.group(job.worker.get_node("ArmL"),Vector3(0,-.49,.06))
	var ring:=a.ring(token,Vector3(0,-.07,0),.095,.019,"#a48149");ring.rotation.x=PI*.5
	var disk:=a.cyl(token,Vector3(0,-.20,0),.115,.115,.042,"#cf995b",18);disk.rotation.x=PI*.5
	a.box(token,Vector3(0,-.19,-.024),Vector3(.12,.017,.012),"#815a3c")
	token.visible=job.worker_aboard
	pennant=a.group(job.quay,Vector3(3.84,2.41,-.48))
	a.beam(pennant,Vector3(-.60,0,-.04),Vector3(.6,0,-.04),.043,"#bca17c")
	plaque=a.box(pennant,Vector3(0,-.37,0),Vector3(.88,.72,.075),"#ab644e")
	for x in [-.28,.28]:a.beam(pennant,Vector3(x,.08,-.07),Vector3(x,-.13,-.07),.018,"#cab180")
	for i in 3:a.box(pennant,Vector3((i-1)*.19,-.40,-.05),Vector3(.075,.21+.11*i,.023),"#e5c893")
	a.box(pennant,Vector3(0,-.65,-.05),Vector3(.63,.031,.022),"#d4b584")
	pennant.visible=job.worker_signed
	coins=a.group(job.boat,Vector3(-.63,.84,.28))
	for i in 3:
		var obol:=a.cyl(coins,Vector3(i*.095-.10,.027*i,0),.13,.13,.036,"#d9ae69",18);obol.rotation.z=.15*i
	coins.visible=job.worker_signed
	pose.bind(job.worker,1.05)

func begin(home:bool,first_time:bool)->void:
	age=0.;landing=home;first=first_time;ended=false
	start_view=job.cam.global_transform;token.show()
	if home:coins.hide()

func active()->bool:return age>=0. and not ended and first

func tick(dt:float)->void:
	if age<0.:return
	age+=dt
	if not landing and job.worker.visible:
		job.worker.get_node("ArmL").rotation.x=-.47-.78*smoothstep(.0,.85,age)+.53*smoothstep(1.4,2.4,age)
		pose.perform(dt,age,Vector2(-.18,.06),.63,age<2.4)
	if landing:
		if age>=.87:coins.show();token.hide()
		if age>=1.3:
			pennant.show();pennant.scale.y=.34+.66*smoothstep(1.3,2.28,age)
	if not first or absf(job.speed)>1.15 or job.chart.large or job.harbour_charter.visible:ended=true
	if active() and age<4.6:
		var focus:Vector3
		var off:Vector3
		if landing and age>1.26:
			focus=job.quay.local_worker.global_position+Vector3.UP*1.18
			off=Vector3(-2.75,1.30,-3.62)
		else:
			focus=job.worker.global_position+Vector3.UP*.87
			off=Vector3(2.65,1.42,-3.85)
		var view:=Transform3D(Basis.looking_at(-off,Vector3.UP),focus+off)
		var blend:=smoothstep(0.,.42,age)*(1.-smoothstep(3.43,4.53,age))
		job.cam.global_transform=job.cam.global_transform.interpolate_with(view,blend)
	if age>=4.6:
		age=-1.;ended=true
		if landing:pennant.scale.y=1.;pennant.show()

func subtitle()->String:
	if landing:return "数数，八枚。以前要摸黑走回去，今天还能赶上吃饭。" if age<2.45 else "明晚还在这儿等我吧。我把末班的牌子挂上。"
	return "我还以为错过末班了。看，船钱我留着呢。" if age<2.3 else "送我去那三盏灯下面吧。"
