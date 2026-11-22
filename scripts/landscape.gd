extends Node2D
var scroll := 0.
var clock := 0.
var vista: Texture2D
var blocks := []
var rubble := []
var rng := RandomNumberGenerator.new()
func _ready():
	rng.seed=402198
	if ResourceLoader.exists("res://art/cinder_keep.jpg"):
		vista=load("res://art/cinder_keep.jpg")
	for row in 8:
		for col in 44:
			var w:=62.+row*9.
			var x:=col*w+fmod(row*37.,w)+rng.randf_range(-6.,6.)-120
			blocks.append([Vector2(x,318+row*15+row*row*1.25),w,rng.randf_range(.03,.19)])
	for i in 130:
		rubble.append(Vector2(rng.randf_range(0,3400),rng.randf_range(328,469)))
func _draw():
	if vista:
		draw_texture_rect_region(vista,Rect2(-scroll*.33,0,1610,322),Rect2(0,0,vista.get_width(),vista.get_height()*.76))
	else:
		draw_rect(Rect2(0,0,960,540),Color("#718389"))
		draw_circle(Vector2(245-scroll*.08,95),47,Color("#e9c998"))
		for i in 20:
			var x:=i*95.-scroll*.15-120
			draw_colored_polygon(PackedVector2Array([Vector2(x-130,314),Vector2(x,82+sin(i*2.71)*45),Vector2(x+180,314)]),Color("#525e69"))
	for i in 8:
		var x:=i*399.-scroll*.58+130
		if x< -60 or x>990: continue
		var wind:=sin(clock*2.+i)*2.7
		draw_line(Vector2(x,322),Vector2(x,242),Color("#3e3834"),3)
		draw_line(Vector2(x-3,246),Vector2(x+31,246),Color("#756654"),3)
		draw_colored_polygon(PackedVector2Array([Vector2(x+3,247),Vector2(x+27,247),Vector2(x+26+wind,276),Vector2(x+21+wind,290),Vector2(x+18,283),Vector2(x+11+wind,295),Vector2(x+10,282),Vector2(x+4+wind,285)]),Color("#663e39"))
		draw_arc(Vector2(x+15,260),5,0,TAU,12,Color("#ac8968"),1,true)
		draw_line(Vector2(x+15,253),Vector2(x+15+wind*.3,274),Color("#ac8968"),1)
	draw_rect(Rect2(0,318,960,222),Color("#48474a"))
	if vista:
		var tile_width:=1080.
		var offset:=fposmod(scroll,tile_width)
		for tile in 2:
			draw_texture_rect_region(vista,Rect2(tile*tile_width-offset,318,tile_width+1,222),Rect2(0,vista.get_height()*.758,vista.get_width(),vista.get_height()*.126))
	else:
		for b in blocks:
			var p: Vector2=b[0]-Vector2(scroll,0)
			if p.x < -140 or p.x>970: continue
			var w: float=b[1]
			var h: float=8.+(p.y-318)*.10
			var c:=Color("#636064").darkened(b[2]+(p.y-318)*.0010)
			draw_colored_polygon(PackedVector2Array([p+Vector2(6,0),p+Vector2(w-2,0),p+Vector2(w-6,h),p+Vector2(-4,h-1)]),c)
			draw_line(p+Vector2(6,0),p+Vector2(w-4,0),c.lightened(.13),1)
	for r in rubble:
		var p: Vector2=r-Vector2(scroll,0)
		if p.x>0 and p.x<960: draw_line(p,p+Vector2(3,-1),Color("#929091"),1)
	for i in 11:
		var x:=i*265.-scroll*.94+85
		if x< -35 or x>995: continue
		draw_line(Vector2(x,323),Vector2(x,281),Color("#252c33"),6)
		draw_colored_polygon(PackedVector2Array([Vector2(x-8,278),Vector2(x+8,278),Vector2(x+4,287),Vector2(x-4,287)]),Color("#52443d"))
		for n in 3:
			var tip:=Vector2(x+sin(clock*7+i+n)*4,259+n*5+sin(clock*9+n)*4)
			draw_colored_polygon(PackedVector2Array([Vector2(x-6+n,278),tip,Vector2(x+6-n,278)]),[Color("#da623c"),Color("#ff943e"),Color("#ffe8a0")][n])
	for i in 26:
		var p:=Vector2(fposmod(i*139.-scroll*.42+clock*8,990)-15,290-fposmod(i*67.+clock*13,104))
		draw_circle(p,1.1,Color(1,.72,.43,.45))
	# Near parapet silhouettes slide faster than the combat lane.
	for i in 11:
		var x:=i*299.-scroll*1.15
		draw_colored_polygon(PackedVector2Array([Vector2(x-62,540),Vector2(x-48,519),Vector2(x-15,517),Vector2(x,500),Vector2(x+23,503),Vector2(x+47,526),Vector2(x+82,540)]),Color("#262a31"))

