extends Control
var font:=preload("res://harbour_fonts.gd").body()
var target:=Vector3.ZERO
var words:=""
var optional:=false
var beside:=false
var ink:=Color("#193436ee")
var ivory:=Color("#fff0d1")
var gold:=Color("#e9b864")
var mint:=Color("#a7cdb9")
var follow_camera:Camera3D

func _draw()->void:
	if follow_camera:draw_pin(follow_camera)

func draw_pin(camera:Camera3D)->void:
	var center:=size*.5
	var p:=camera.unproject_position(target)
	var safe:=Rect2(Vector2(105,128),size-Vector2(210,305))
	var behind:=camera.is_position_behind(target)
	var edge:=behind or not safe.has_point(p)
	var dir:Vector2=(p-center).normalized()
	if behind:
		var local:=camera.to_local(target)
		dir=Vector2(local.x,absf(local.z)*.60).normalized()
	if edge:
		var reach:=Vector2(safe.size.x*.5,safe.size.y*.5)
		var travel:=minf(reach.x/maxf(.01,absf(dir.x)),reach.y/maxf(.01,absf(dir.y)))
		p=safe.get_center()+dir*travel
	var tint:=mint if optional else gold
	var tip:=p.round()
	var elbow:=Vector2(0,-19)
	if beside and not edge:elbow=Vector2(98. if tip.x<size.x*.68 else -98.,5.)
	if edge:elbow=-dir*19.
	var anchor:=tip+elbow
	var label:=("顺路 · " if optional else "")+words
	var width:=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+24.
	var left:=clampf(anchor.x-width*.5,12.,size.x-width-12.)
	var top:=clampf(anchor.y-31.,108.,size.y-165.)
	var rect:=Rect2(left,top,width,30.)
	draw_line(tip,Vector2(clampf(tip.x,rect.position.x+5,rect.end.x-5),rect.end.y),tint,1.5,true)
	draw_rect(rect,ink);draw_rect(Rect2(rect.position,Vector2(3,30)),tint)
	draw_string(font,rect.position+Vector2(12,21),label,HORIZONTAL_ALIGNMENT_LEFT,-1,17,ivory)
	if edge:
		var side:=dir.orthogonal()*5.
		draw_colored_polygon(PackedVector2Array([tip+dir*5.,tip-dir*5.+side,tip-dir*5.-side]),tint)
	else:
		draw_circle(tip,4.2,ink,true);draw_circle(tip,2.8,tint,true)

