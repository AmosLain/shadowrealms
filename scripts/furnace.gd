extends Node2D

# A fixed floor vent. The same footprint drives the warning, fire and damage.
const RADIUS := Vector2(81, 26)
const WARNING := 1.10
const FLAME := 0.48
const CLEARANCE := 39.0
var arena
var remaining := 1.0
var state := "rest"
var victims := {}

func arm(level, point: Vector2, delay: float):
	arena = level
	position = point
	remaining = delay

func contains_floor(point: Vector2) -> bool:
	return ((point - position) / RADIUS).length_squared() <= 1.0

func step(dt: float, enraged: bool):
	remaining -= dt
	if remaining <= 0.0:
		match state:
			"rest":
				state = "warning"
				remaining = WARNING
				arena.sound.play("bell")
			"warning":
				state = "fire"
				remaining = FLAME
				victims.clear()
				arena.sound.play("vent")
			"fire":
				state = "rest"
				remaining = 1.5 if enraged else 3.1
	if state == "fire":
		burn(arena.hero)
		for enemy in arena.enemies:
			burn(enemy)
	queue_redraw()

func burn(unit):
	if unit.hp <= 0 or unit.lift >= CLEARANCE or victims.has(unit.get_instance_id()):
		return
	if contains_floor(unit.position) and unit.damage(12 if unit.playable else 25, 0, false):
		victims[unit.get_instance_id()] = true
		arena.fx(unit.position - Vector2(0, 25), "impact")

func _draw():
	var heat := 0.0
	if state == "warning":
		heat = 1.0 - remaining / WARNING
	elif state == "fire":
		heat = 1.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, RADIUS.y / RADIUS.x))
	draw_circle(Vector2.ZERO, RADIUS.x, Color("#25272b"))
	draw_arc(Vector2.ZERO, RADIUS.x, 0, TAU, 48, Color("#a48c6c"), 3, true)
	var glow := Color("#473a38").lerp(Color("#ffb457"), heat)
	for i in range(-4, 5):
		var x := i * 16.0
		var h := sqrt(RADIUS.x * RADIUS.x - x * x) - 8
		draw_line(Vector2(x,-h), Vector2(x,h), glow, 6, true)
	if state == "warning":
		draw_arc(Vector2.ZERO, RADIUS.x-4, -PI/2, -PI/2 + TAU*heat, 48, Color("#ffe5a5"), 5, true)
	draw_set_transform(Vector2.ZERO)
	if state == "fire":
		for i in range(-3,4):
			var x := i*19.0
			var tip := 24.0 + absf(sin(remaining*19+i*1.7))*37.0
			draw_colored_polygon(PackedVector2Array([Vector2(x-9,3),Vector2(x-5,-17),Vector2(x+3,-tip),Vector2(x+8,-11),Vector2(x+7,3)]), Color("#f08243"))
			draw_colored_polygon(PackedVector2Array([Vector2(x-4,2),Vector2(x+1,-tip*.62),Vector2(x+4,2)]), Color("#ffe49a"))
