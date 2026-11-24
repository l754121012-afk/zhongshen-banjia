extends RefCounted

static var ui:Font
static var display:Font
static func body()->Font:
	if ui==null:
		var font:=SystemFont.new();font.font_names=PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","Segoe UI"]);ui=font
	return ui
static func headings()->Font:
	if display==null:
		var font:=SystemFont.new();font.font_names=PackedStringArray(["SimSun","Microsoft YaHei UI"]);display=font
	return display
