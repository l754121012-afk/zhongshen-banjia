extends RefCounted
# Eye, brow, jaw and neck pivots are authored on the same sculpture as the courier.
var head:Node3D
var lids:Node3D
var pupils:Node3D
var smile:Node3D
var mouth:Node3D
var brow_l:Node3D
var brow_r:Node3D
var offset:=0.0

func bind(person:Node3D,blink_offset:float)->void:
	head=person.find_child("Gaze",true,false)
	lids=head.get_node("Lids");pupils=lids.get_node("Pupils")
	smile=head.get_node("Smile");mouth=head.get_node("Speech")
	brow_l=head.get_node("BrowL");brow_r=head.get_node("BrowR")
	offset=blink_offset;mouth.hide()
	# Hats, scarves and hair follow the neck. Costume props are authored in actor space.
	for prop in person.get_children():
		if prop is Node3D and prop.position.y>=1.305:prop.reparent(head,true)

func perform(dt:float,t:float,look:Vector2,mood:float,speaking:bool)->void:
	var ease:=1.-exp(-dt*10.)
	head.rotation.y=lerp_angle(head.rotation.y,look.x,ease)
	var beat:=maxf(0.,sin(t*12.4+offset)*.60+sin(t*19.3)*.37) if speaking else 0.
	head.rotation.x=lerp_angle(head.rotation.x,look.y+beat*.044,ease)
	head.rotation.z=lerpf(head.rotation.z,mood*.055,ease)
	var blink:=absf(fmod(t+offset,3.87)-.14)
	lids.scale.y=lerpf(.08,.96,smoothstep(.018,.12,blink))*(1.-maxf(0.,mood)*.15)
	pupils.position.x=look.x*.014
	brow_l.rotation.z=lerpf(brow_l.rotation.z,mood*.27+sin(t*4.1)*beat*.07,ease)
	brow_r.rotation.z=lerpf(brow_r.rotation.z,-mood*.27,ease)
	var talking:=beat>.22
	smile.visible=not talking;mouth.visible=talking
	if talking:mouth.scale=Vector3(.97,clampf(.5+beat,.5,1.4),1.)
	smile.scale.y=clampf(1.+mood*.65,.32,1.65)

