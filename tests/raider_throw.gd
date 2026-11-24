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

func spawn(kind: String, point: Vector2):
	var enemy = game.spawn(kind, point)
	game.enemies.append(enemy)
	return enemy

func touch(index: int, point: Vector2, pressed: bool):
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)

func attack(use_touch: bool):
	if use_touch:
		touch(1, game.ui.touch.BUTTONS.attack, true)
		touch(1, game.ui.touch.BUTTONS.attack, false)
	else:
		game.hero.command("attack")

func trial(side: int, lane: float, directional: bool, use_touch := false, interrupt := false):
	game.begin()
	game.ui.touch.visible = use_touch
	game.hero.position = Vector2(470, 395)
	game.hero.face = side
	# Keep the test in a locked encounter so automatic progression cannot spawn other targets.
	game.wave = 0
	game.locked = true
	var victim = spawn("raider", game.hero.position + Vector2(side * 30, 0))
	victim.cooldown = 2.0
	# A stationary chime makes the collision lane and number of contacts unambiguous.
	var obstacle = spawn("chime", game.hero.position + Vector2(side * 140, lane))
	obstacle.cooldown = 5.0
	var moves: Array[String] = []
	var hp_events := 0
	var return_queued := false
	var finisher_queued := false
	var started_throw := false
	var launched := false
	var interrupted := false
	var launch_origin := 0.0
	var max_travel := 0.0
	var action := "right" if side > 0 else "left"
	attack(use_touch)
	for tick in 110:
		var hero = game.hero
		if hero.state == "attack" and hero.did_hit:
			if hero.move == "cut" and not return_queued:
				attack(use_touch)
				return_queued = true
			elif hero.move == "return" and not finisher_queued:
				if use_touch and directional:
					touch(0, game.ui.touch.ORIGIN + Vector2(side * 43, 0), true)
				elif directional:
					Input.action_press(action)
				attack(use_touch)
				finisher_queued = true
		if interrupt and not interrupted and victim.state == "held" and hero.elapsed >= .07:
			interrupted = hero.damage(3, 0.0, false)
		var old_hp: int = obstacle.hp
		# The scene steps hero, both bodies, and any post-movement collision pass in play order.
		game._physics_process(STEP)
		if hero.state == "attack" and (moves.is_empty() or moves.back() != hero.move):
			moves.append(hero.move)
			if hero.move == "throw":
				started_throw = true
				launch_origin = victim.position.x
				if use_touch:
					touch(0, game.ui.touch.ORIGIN, false)
				else:
					Input.action_release(action)
		if started_throw and is_instance_valid(victim):
			launched = launched or victim.state == "thrown"
			max_travel = maxf(max_travel, side * (victim.position.x - launch_origin))
		if started_throw and obstacle.hp < old_hp:
			hp_events += 1
	Input.action_release(action)
	if interrupt:
		check(interrupted and started_throw, "attacker takes a hit while the grip is held")
		check(victim.thrower == null and victim.state != "held", "interruption releases the victim")
		check(not launched and hp_events == 0, "interrupted grip cannot launch or damage another target")
	elif directional:
		check(moves == ["cut", "return", "throw"], "directional strike completes a throw in direction %d" % side)
		check(launched and max_travel > 60.0, "thrown raider physically crosses the lane")
		check(hp_events == (1 if is_zero_approx(lane) else 0), "body impact count matches target lane (%d events, offset %d)" % [hp_events, lane])
	else:
		check(moves == ["cut", "return", "cleave"], "neutral third strike retains Orra's cleave")

func run():
	game = load("res://scenes/Keep.tscn").instantiate()
	game.save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	trial(1, 0.0, true)
	trial(-1, 0.0, true)
	trial(1, 56.0, true)
	trial(1, 56.0, false)
	trial(1, 0.0, true, true)
	trial(-1, 0.0, true, true, true)
	game.free()
	await process_frame
	quit(1 if failures else 0)
