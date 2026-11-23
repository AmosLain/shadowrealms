extends Node2D

var friendly := false
var velocity := Vector2.ZERO
var altitude := 0.0
var damage := 0
var age := 0.0
var facing := 1

func configure(falling: bool, origin: Vector2, direction: int, lane: int, lift: float, power: int):
	friendly = falling
	facing = direction
	position = origin
	velocity = Vector2(direction * (355 if falling else 225), lane * 88)
	altitude = lift + 54 if falling else 9.0
	damage = power

func advance(dt: float, targets: Array) -> bool:
	age += dt
	position += velocity * dt
	if friendly: altitude -= 185 * dt
	queue_redraw()
	for unit in targets:
		if unit.hp <= 0: continue
		var offset: Vector2 = unit.position - position
		if absf(offset.x) > 23 or absf(offset.y) > 16: continue
		if altitude < unit.lift or altitude > unit.lift + 92: continue
		if unit.damage(damage, facing * 125., not friendly):
			unit.arena.fx(position - Vector2(0,altitude), "impact")
		return true
	return altitude <= 0.0 or age > 1.18

func _draw():
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.27))
	draw_circle(Vector2.ZERO,9,Color(.13,.12,.14,.52))
	draw_set_transform(Vector2(0,-altitude),0,Vector2(facing,1))
	if friendly:
		draw_colored_polygon(PackedVector2Array([Vector2(-22,-12),Vector2(4,-3),Vector2(8,4),Vector2(-2,3)]),Color("#ff994e"))
		draw_line(Vector2(-12,-6),Vector2(5,2),Color("#fff1bc"),3,true)
	else:
		for i in range(3):
			var x := -i*9.
			var h := 20.0 + 7.0*sin(age*19+i) - i*3.0
			draw_colored_polygon(PackedVector2Array([Vector2(x-7,8),Vector2(x+3,-h),Vector2(x+6,8)]),Color("#bf866e"))
			draw_line(Vector2(x+3,-h),Vector2(x+6,7),Color("#ffe0ac"),1.5,true)
