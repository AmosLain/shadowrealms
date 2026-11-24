extends Node2D

var cantor
var seals:Array=[]

func _draw():
	if not is_instance_valid(cantor) or cantor.hp<=0: return
	var target:Vector2=cantor.position-Vector2(0,65)
	for seal in seals:
		if not is_instance_valid(seal) or seal.hp<=0: continue
		var start:Vector2=seal.position-Vector2(0,53)
		var bend:=start.lerp(target,.5)-Vector2(0,34)
		var path:=PackedVector2Array()
		for step in 17:
			path.append(start.bezier_interpolate(bend,bend,target,step/16.))
		draw_polyline(path,Color("#263840"),4.,true)
		draw_polyline(path,Color("#8ab8b8"),1.6,true)
		var pulse:=fposmod(cantor.stride*.19,1.)
		draw_circle(start.bezier_interpolate(bend,bend,target,pulse),3.,Color("#f1deaa"))
