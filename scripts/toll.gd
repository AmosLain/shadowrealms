extends Node2D

# The cantor marks the ground once. Players can leave it while the rings converge.
const WINDUP := 1.12
const RADIUS := Vector2(69, 30)
var arena
var age := 0.0
var released := false

func _physics_process(dt):
	if arena.level_state != "play": return
	age += dt
	if age >= WINDUP and not released:
		released = true
		arena.fx(position, "bolt")
		arena.sound.play("magic")
		var offset: Vector2 = arena.hero.position-position
		if (offset/RADIUS).length_squared() <= 1.0:
			arena.hero.damage(18,0,true)
	if age > WINDUP+0.28: queue_free()
	queue_redraw()

func _draw():
	var progress := clampf(age/WINDUP,0,1)
	draw_set_transform(Vector2.ZERO,0,Vector2(1,RADIUS.y/RADIUS.x))
	draw_circle(Vector2.ZERO,RADIUS.x,Color(.12,.16,.29,.38))
	draw_arc(Vector2.ZERO,RADIUS.x,0,TAU,48,Color("#b7ecf2"),2,true)
	draw_arc(Vector2.ZERO,maxf(2,RADIUS.x*(1-progress)),0,TAU,48,Color("#f5d494"),3,true)
	for i in 8:
		var axis := Vector2.from_angle(i*TAU/8)
		draw_line(axis*(RADIUS.x-7),axis*(RADIUS.x+4),Color("#b7ecf2"),2,true)
