extends RefCounted
## One spatial pressure field drives flags, vegetation, cross traffic and cargo.
const PERIOD:=8.6
const FLOW:=Vector2(.40,.9165)
static func pressure(at:Vector2,t:float)->float:
	var phase:=fposmod(t-at.dot(FLOW)/10.0,PERIOD)
	return smoothstep(.12,1.65,phase)*(1.0-smoothstep(3.0,5.5,phase))
static func breeze(at:Vector2,t:float)->float:
	return .16+.84*pressure(at,t)
