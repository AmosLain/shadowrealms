extends SceneTree

const STEP := 1.0 / 60.0
var game
var failures := 0

func _initialize():
	call_deferred("run")

func check(ok: bool, description: String):
	if ok:
		print("PASS ", description)
	else:
		failures += 1
		push_error(description)

func setup_arena(role := "warden"):
	game.selected = role
	game.begin()
	game.hero.position = Vector2(470, 395)
	game.wave = 0
	game.locked = true

func spawn(kind: String, offset: Vector2):
	var enemy = game.spawn(kind, game.hero.position + offset)
	enemy.cooldown = 5.0
	game.enemies.append(enemy)
	return enemy

func stick(offset: Vector2, pressed: bool):
	game.ui.touch.visible = true
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = pressed
	event.position = game.ui.touch.ORIGIN + offset
	root.push_input(event, true)

func throw_trial(side: int, secondary_lane: float, interrupt := false):
	setup_arena()
	game.hero.face = -side
	var victim = spawn("raider", Vector2(side * 30, 0))
	# A stationary chime makes the bystander's lane and number of hits unambiguous.
	var secondary = spawn("chime", Vector2(side * 140, secondary_lane))
	var initial_x: float = victim.position.x
	game._physics_process(STEP)
	check(game.hero.move == "throw" and game.hero.state == "attack" and victim.state == "held",
		"idle Orra grabs a raider behind her on side %d without attack input" % side)
	var launched := false
	var interrupted := false
	var released_on_interrupt := false
	var contacts := 0
	var travel := 0.0
	for tick in 48:
		var gripping: bool = interrupt and not interrupted and victim.state == "held" and game.hero.elapsed >= .07
		if gripping:
			interrupted = game.hero.damage(3, 0.0, false)
		var previous_hp: int = secondary.hp
		game._physics_process(STEP)
		if gripping:
			released_on_interrupt = victim.thrower == null and victim.state == "down"
		launched = launched or victim.state == "thrown"
		travel = maxf(travel, side * (victim.position.x - initial_x))
		if secondary.hp < previous_hp:
			contacts += 1
	if interrupt:
		check(interrupted and released_on_interrupt, "hit during grip frees the victim on the next physics tick")
		check(not launched and contacts == 0, "interrupted grab never launches or deals body damage")
	else:
		check(launched and travel > 60.0, "throw carries the raider away from the hero")
		check(contacts == (1 if is_zero_approx(secondary_lane) else 0),
			"body contacts %d bystanders at lane offset %d" % [contacts, secondary_lane])

func run():
	game = load("res://scenes/Keep.tscn").instantiate()
	game.save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	throw_trial(1, 0.0)
	throw_trial(-1, 0.0)
	throw_trial(1, 56.0)
	throw_trial(-1, 0.0, true)

	setup_arena()
	var guard = spawn("raider", Vector2(43, 0))
	guard.face = -1
	guard.start_move("jab")
	stick(Vector2(48, 0), true)
	game._physics_process(STEP)
	check(game.hero.state == "walk" and guard.state == "attack", "outside horizontal contact the windup continues")
	game._physics_process(STEP)
	stick(Vector2.ZERO, false)
	check(game.hero.move == "throw" and guard.state == "held", "walking into a windup with the stick alone triggers the grab")

	setup_arena()
	guard = spawn("raider", Vector2(40, 0))
	guard.recoil = -120.0
	game._physics_process(STEP)
	check(guard.state == "held", "raider moving into a stationary hero is grabbed that same physics tick")

	setup_arena()
	guard = spawn("raider", Vector2(20, 25))
	guard.start_move("jab")
	game._physics_process(STEP)
	check(guard.state == "attack" and game.hero.move != "throw", "adjacent lane outside 24 units is safe")
	guard.position.y = game.hero.position.y + 23.5
	game._physics_process(STEP)
	check(guard.state == "held", "inside lane boundary counts as contact")

	setup_arena()
	guard = spawn("raider", Vector2(0, 0))
	game.hero.command("jump")
	game._physics_process(STEP)
	check(game.hero.rise > 0.0 and guard.state != "held", "taking off at contact preserves jump")

	setup_arena("swift")
	guard = spawn("raider", Vector2(20, 0))
	game._physics_process(STEP)
	check(guard.state != "held" and game.hero.move != "throw", "contact throw belongs to Orra")

	game.free()
	await process_frame
	quit(1 if failures else 0)
