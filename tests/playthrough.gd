extends SceneTree
var game
var moves_seen: Dictionary={}
var frame:=0
var took_damage:=false
var phase_seen:=false
func _initialize():
	call_deferred("run")
func press_button(words:String) -> void:
	for child in game.ui.panel.get_children():
		if child is Button and child.text==words:
			child.pressed.emit()
			return
	push_error("Missing button "+words)
	quit(2)
func tap(action:String):
	var ev:=InputEventAction.new()
	ev.action=action
	ev.pressed=true
	game._unhandled_input(ev)
func run():
	game=load("res://scenes/Keep.tscn").instantiate()
	root.add_child(game)
	press_button("Enter the keep")
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty(): press_button(game.Rules.NAMES[args[0]])
	press_button("Begin with "+game.Rules.NAMES[game.selected])
	tap("pause")
	assert(game.level_state=="pause")
	press_button("Resume")
	tap("jump")
	await physics_frame
	await physics_frame
	await physics_frame
	assert(game.hero.lift>0)
	while game.level_state=="play" and frame<12000:
		await physics_frame
		frame+=1
		var h=game.hero
		took_damage=took_damage or h.hp<h.max_hp
		if h.state=="attack": moves_seen[h.move]=true
		var target
		var best:=INF
		for e in game.enemies:
			if e.hp<=0: continue
			phase_seen=phase_seen or e.phase_two
			var dist:float=h.position.distance_to(e.position)
			if dist<best:
				target=e
				best=dist
		var aim:=Vector2.RIGHT
		if target:
			var gap:Vector2=target.position-h.position
			aim=Vector2(signf(gap.x),signf(gap.y) if absf(gap.y)>8 else 0.)
			if absf(gap.x)<98 and absf(gap.y)<30:
				if frame%8==0:
					tap("magic" if frame%152==0 and h.mana>=30 else ("special" if frame%104==0 else "attack"))
		for action in ["left","right","up","down"]: Input.action_release(action)
		if aim.x>0: Input.action_press("right")
		if aim.x<0: Input.action_press("left")
		if aim.y>0: Input.action_press("down")
		if aim.y<0: Input.action_press("up")
		if frame%1200==0: print("tick ",frame," wave ",game.wave," hp ",h.hp)
	print("RESULT ",game.level_state," ticks=",frame," hp=",game.hero.hp," moves=",moves_seen," damage=",took_damage," phase2=",phase_seen)
	quit(0 if game.level_state=="won" and phase_seen else 1)

