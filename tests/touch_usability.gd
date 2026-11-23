extends SceneTree

const STEP := 1.0 / 60.0
var game
var errors := 0

func _initialize():
	call_deferred("run")

func verify(ok: bool, description: String):
	if ok:
		print("PASS ", description)
	else:
		errors += 1
		push_error(description)

func press(index: int, point: Vector2, pressed: bool):
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)

func drag(index: int, point: Vector2):
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	root.push_input(event, true)

func run():
	game = load("res://scenes/Keep.tscn").instantiate()
	game.save_path = ""
	root.add_child(game)
	game.begin()
	game.set_physics_process(false)
	var pad = game.ui.touch
	pad.visible = true
	var hero = game.hero
	var origin: Vector2 = hero.position
	hero.face = 1

	press(0, pad.ORIGIN + Vector2(-6, 0), true)
	for tick in 30:
		hero.step(STEP, game.touch_vector)
	verify(hero.position.is_equal_approx(origin) and hero.face == 1,
		"resting thumb keeps the hero planted and facing the opponent")

	drag(0, pad.ORIGIN + Vector2(17, 0))
	var slow: float = game.touch_vector.x
	drag(0, pad.ORIGIN + Vector2(31, 0))
	verify(slow > 0.0 and slow < game.touch_vector.x and game.touch_vector.x < 1.0,
		"partial stick travel gives progressive movement")
	drag(0, pad.ORIGIN + Vector2(60, -60))
	verify(game.touch_vector.is_equal_approx(Vector2(1, -1).normalized()),
		"full diagonal travel preserves direction and maximum speed")

	drag(0, pad.ORIGIN + Vector2(0, 5))
	press(1, pad.BUTTONS.attack, true)
	hero.step(STEP, game.touch_vector)
	verify(game.touch_vector == Vector2.ZERO and hero.move == "cut" and pad.finger == 0,
		"drifting into neutral allows an independent standing strike")
	press(1, pad.BUTTONS.attack, false)
	press(0, pad.ORIGIN, false)
	verify(game.touch_vector == Vector2.ZERO and pad.finger == -1,
		"lifting the stick thumb clears movement ownership")

	game.free()
	await process_frame
	quit(1 if errors else 0)
