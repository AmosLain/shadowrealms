extends Node2D
var duration:=.35
var age:=0.
var kind:="impact"
var direction:=1
func _process(dt):
	if get_parent().get_parent().level_state=="pause": return
	age+=dt
	if age>=duration: queue_free()
	queue_redraw()
func _draw():
	var p:=age/duration
	var c:=Color("#8ce0d8") if kind=="magic" else Color("#f5c485")
	c.a=1.-p
	if kind=="dust":
		for i in 4:
			var x:float=sin(i*3.7+.5)*p*16.
			draw_circle(Vector2(x,-p*(3+i)),(1.+p)*1.9,Color(.64,.57,.47,.4*(1.-p)))
	elif kind=="bolt":
		for i in 5:
			var x:float=(i-2)*63.
			draw_polyline(PackedVector2Array([Vector2(x-17,-182),Vector2(x+8,-104),Vector2(x-5,-111),Vector2(x+13,-44),Vector2(x+1,-51),Vector2(x,0)]),Color(.68,.91,1.,1.-p),3.,true)
	elif kind=="counter":
		draw_arc(Vector2.ZERO,9.+p*48.,0,TAU,34,Color(.56,1.,.90,1.-p),3.,true)
	elif kind=="quake":
		draw_set_transform(Vector2.ZERO,0,Vector2(1,.4))
		for i in 12:
			var axis:=Vector2.from_angle(i*TAU/12.)
			var edge:=axis*(28.+p*130.)
			draw_polyline(PackedVector2Array([axis*12.,edge*.61+Vector2(6,6),edge]), Color(1,.61,.30,1.-p),3.,true)
	elif kind=="magic":
		draw_set_transform(Vector2.ZERO,0,Vector2(1,.32))
		draw_arc(Vector2.ZERO,12.+210.*p,0,TAU,52,c,4.*(1.-p)+1.,true)
		for i in 8:
			var v:=Vector2.from_angle(i*TAU/8+p)*p*180
			draw_line(v,v+Vector2(8,-32)*(1.-p),c,2,true)
	else:
		for i in 9:
			var v:=Vector2.from_angle(i*2.401)*Vector2(1.4,.8)
			draw_line(v*p*45.,v*(p*45.+8.*(1.-p)),c,2,true)

