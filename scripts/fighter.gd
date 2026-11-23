extends Node2D
const Rules = preload("res://scripts/rules.gd")
const Rig = preload("res://scripts/rig.gd")
var playable:=false
var kind: String
var hp: int
var max_hp: int
var mana := 100.
var speed: float
var face := 1
var state := "idle"
var move := ""
var elapsed := 0.
var cooldown := 0.
var invincible := 0.
var lift := 0.
var rise := 0.
var jump_held := false
var jump_buffer := 0.0
var air_spent := false
var ember_time := 0.0

func release_jump():
	jump_held = false
	if rise > 170.: rise = 170.

func attack_damage(base:int) -> int:
	return roundi(base * 1.5) if ember_time > 0. else base
var last_tap := 0
var tap_left := 0.0
var run_dir := 0
var run_distance := 0.0
var shoulder_contact := false

func tap_horizontal(dir:int):
	if kind!="warden" or hp<=0 or lift>0 or state not in ["idle","walk"]: return
	if dir==last_tap and tap_left>0:
		run_dir=dir
		run_distance=0.
		tap_left=0.
	else:
		run_dir=0
		last_tap=dir
		tap_left=Rules.RUN_TAP_WINDOW

func reset_run():
	run_dir=0
	run_distance=0.
	tap_left=0.

var knockback_side := 1.0
var recoil := 0.
var combo := 0
var chain := 0.
var queued := ""
var buffer := 0.
var did_hit := false
var impact_hold := 0.0
var contact_targets := {}
var cut_reaction := 0.0
var phase_two := false
var pattern := 0
var stride := 0.
var arena
var rig
var hurt: Area2D
var hit: Area2D

func configure(type: String, level):
	kind = type
	playable=kind in Rules.HEROES
	arena = level
	var data: Array = Rules.UNITS[kind]
	max_hp = data[0]
	hp = max_hp
	speed = data[1]
	rig = Rig.new()
	add_child(rig)
	rig.actor = self
	rig.install_frames(kind)
	rig.scale = Vector2.ONE * float(data[2])
	hurt = box(1 if playable else 2, Vector2(39,24))
	hit = box(0, Vector2(1,1))
	hit.collision_mask = 2 if playable else 1

func box(layer: int, dimensions: Vector2) -> Area2D:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = dimensions
	shape.shape = rect
	area.add_child(shape)
	area.collision_layer = layer
	area.collision_mask = 0
	add_child(area)
	return area

func can_be_countered_by(attacker) -> bool:
	if state!="attack" or did_hit or move not in ["jab","crush","reap"]: return false
	var data:Array=Rules.MOVES[move]
	var until_hit:float=data[0]-elapsed
	var gap:Vector2=attacker.position-position
	return until_hit>=0 and until_hit<=0.22 and gap.x*face>=-8 and absf(gap.x)<=data[2]+12 and absf(gap.y)<=data[3] and attacker.face==-face and attacker.lift<35

func command(action: String):
	if hp <= 0: return
	if action=="jump":
		jump_held=true
		jump_buffer=.16
		return
	queued = action
	buffer = .32

func start_move(action: String):
	reset_run()
	shoulder_contact=false
	state = "attack"
	move = action
	elapsed = 0.
	did_hit = false
	contact_targets.clear()
	var data: Array = Rules.MOVES[move]
	var radial := move in ["magic","quake","bolt","plunge"]
	var width: float = data[2] * (2. if radial else 1.)
	hit.get_child(0).shape.size = Vector2(width,data[3]*2.)
	hit.position.x = 0. if radial else face * width * .5

func step(dt: float, direction: Vector2):
	tap_left=maxf(0.,tap_left-dt)
	ember_time=maxf(0.,ember_time-dt)
	if impact_hold>0.:
		var held:=minf(dt,impact_hold)
		impact_hold-=held
		dt-=held
		if dt<=0.000001: return
	cut_reaction=move_toward(cut_reaction,0.,dt)
	elapsed += dt
	invincible = maxf(0.,invincible-dt)
	cooldown -= dt
	chain -= dt
	buffer -= dt
	jump_buffer -= dt
	if lift > 0. or rise > 0.:
		rise -= 800.*dt
		lift = maxf(0.,lift+rise*dt)
	if lift<=0.: air_spent=false
	position.x += recoil*dt
	recoil = move_toward(recoil,0.,680.*dt)
	if state == "dead":
		modulate.a = clampf(1.7-elapsed,0.,1.)
	elif state in ["hurt","down"]:
		if elapsed > (.68 if state=="down" else .24):
			state = "idle"
	elif state == "attack":
		var data: Array = Rules.MOVES[move]
		var ready_to_hit := elapsed >= float(data[0]) and (move!="plunge" or lift<=0.)
		if move=="shoulder":
			# Drive in the committed lane, then brake even if the input reverses.
			var velocity_x:=465.*lerpf(.22,1.,smoothstep(.025,.09,elapsed))*(1.-smoothstep(.22,.44,elapsed))
			if shoulder_contact: velocity_x*=.16
			position.x=clampf(position.x+face*velocity_x*dt,arena.left_bound,arena.right_bound)
			if ready_to_hit:
				if not did_hit: arena.sound.play("swing")
				did_hit=true
				if not shoulder_contact and elapsed<=.30:
					shoulder_contact=arena.shoulder_hit(self)
		elif move=="cut":
			var previous:=elapsed-dt
			var travel:=Rules.cut_travel(elapsed)-Rules.cut_travel(previous)
			position.x=clampf(position.x+face*travel,arena.left_bound,arena.right_bound)
			if ready_to_hit and previous<Rules.CUT_RELEASE:
				if not did_hit: arena.sound.play("swing")
				did_hit=true
				arena.opening_cut(self,minf(elapsed,Rules.CUT_RELEASE-.0001))
		elif ready_to_hit and not did_hit:
			did_hit = true
			arena.strike(self)
			if move=="plunge": elapsed=data[0]
		var ending := float(data[0])+float(data[1])
		if (did_hit and elapsed >= ending) or (playable and move in ["cut","return","nick","cross"] and queued=="attack" and buffer>0 and elapsed>ending-.09):
			state = "idle"
			chain = .36
			cooldown = 3.0 if kind=="chime" else (.43 if phase_two else .70)
	else:
		if playable:
			if run_dir!=0 and direction.x*run_dir<.45: run_dir=0
			if absf(direction.x)>.1: face = 1 if direction.x>0 else -1
			if jump_buffer>0. and lift<=0. and rise<=0.:
				reset_run()
				rise=390. if jump_held else 170.
				jump_buffer=0.
			var taking_off := rise>0. and lift<=0.
			if buffer>0 and not (taking_off and queued=="attack"):
				match queued:
					"attack":
						if lift>0.:
							if not air_spent:
								air_spent=true
								start_move(Rules.AIR_ATTACK[kind])
								if move=="plunge": rise=-360.
								if move=="gale":
									recoil=face*500.
									rise=minf(rise,-80.)
						elif run_dir!=0 and run_distance>=Rules.SHOULDER_RUNUP:
							start_move("shoulder")
							combo=0
						else:
							if chain<=0.: combo=0
							if kind=="seer": start_move("spark")
							elif kind=="swift": start_move(["nick","cross","rend"][combo])
							else: start_move(["cut","return","cleave"][combo])
							combo=(combo+1)%3
					"special":
						arena.counter(self)
						if kind=="warden": start_move("special")
						else:
							start_move("blink" if kind=="seer" else "lunge")
							invincible=.30
							recoil=face*(460. if kind=="seer" else 360.)
					"magic":
						if mana>=30:
							mana-=30
							start_move("bolt" if kind=="seer" else "magic")
				buffer=0.
				queued=""
			mana = minf(100.,mana+dt*3.5)
		else:
			direction = think()
		if state!="attack":
			var previous_x:=position.x
			var pace:=Rules.RUN_SPEED if run_dir!=0 else speed
			position += direction * Vector2(pace,speed*.66)*dt
			if run_dir!=0:
				run_distance+=absf(clampf(position.x,arena.left_bound,arena.right_bound)-previous_x)
			state = "walk" if direction.length()>.1 else "idle"
			stride += dt * (14. if run_dir!=0 else (9. if state=="walk" else 2.6))
	position.y = clampf(position.y,332.,461.)
	position.x = clampf(position.x,arena.left_bound,arena.right_bound)
	rig.position.y = -lift
	rig.queue_redraw()
	queue_redraw()

func think() -> Vector2:
	var delta_pos: Vector2 = arena.hero.position-position
	face = 1 if delta_pos.x>=0 else -1
	if kind=="chime":
		if cooldown<=0. and absf(delta_pos.x)<175. and absf(delta_pos.y)<28.:
			start_move("cast")
		return Vector2.ZERO
	var ranged := kind in ["cultist","cantor"]
	var reach := 245. if ranged else (96. if kind=="headsman" else 58.)
	if kind=="brute" and cooldown<=0 and absf(delta_pos.x)>100 and absf(delta_pos.x)<228 and absf(delta_pos.y)<22 and arena.hero.hp>0:
		start_move("fault")
		return Vector2.ZERO
	var direction := Vector2.ZERO
	if absf(delta_pos.x)>reach: direction.x = face
	if ranged and absf(delta_pos.x)<140.: direction.x = -face
	if absf(delta_pos.y)>9.: direction.y = signf(delta_pos.y)
	for other in arena.enemies:
		if other==self or other.hp<=0: continue
		var separation: Vector2 = position-other.position
		if separation.length()<45.:
			direction += separation.normalized()*.85
	if absf(delta_pos.x)<=reach+12 and absf(delta_pos.y)<23. and cooldown<=0 and arena.hero.hp>0:
		pattern+=1
		match kind:
			"brute": start_move("crush")
			"cultist": start_move("cast")
			"cantor": start_move("toll" if pattern%3==1 else ("peal" if phase_two or pattern%2==0 else "cast"))
			"headsman": start_move("quake" if pattern%3==0 else ("jab" if phase_two and pattern%2==0 else "reap"))
			_: start_move("hook" if pattern%2==0 else "jab")
	return direction.limit_length()

func damage(amount: int, push: float, knockdown: bool) -> bool:
	if hp<=0 or invincible>0.: return false
	if kind=="cantor" and arena.chimes_alive():
		arena.fx(position-Vector2(0,61),"counter")
		return false
	reset_run()
	hp = maxi(0,hp-amount)
	phase_two = kind in ["headsman","cantor"] and hp<=max_hp/2
	knockback_side = signf(push) if push != 0. else -float(face)
	rig.queue_redraw()
	queue_redraw()
	recoil = 0.0 if kind=="chime" else push
	if hp==0: state="dead"
	elif kind!="headsman" or state!="attack":
		state="down" if knockdown else "hurt"
	if state!="attack": elapsed=0.
	invincible = (.75 if playable else .16)
	return true

func _draw():
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.24))
	draw_circle(Vector2.ZERO,maxf(14.,32.-lift*.10),Color(0.025,.025,.035,.42))


	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if state=="attack" and not playable and not did_hit:
		var d:Array=Rules.MOVES[move]
		var r:float=d[2]
		var start:float=-r if face<0 or move=="quake" else 0.
		var span:=r*2 if move=="quake" else r
		var lane:float=d[3]
		if move in ["jab","crush","reap"] and float(d[0])-elapsed<=0.22:
			draw_arc(Vector2(0,-118),13,-PI,PI,24,Color("#b7fff0"),3,true)
		if move=="hook":
			draw_line(Vector2(face*42,-45),Vector2(face*63,-103),Color("#f3a7d7"),3.,true)
		var danger:=Color(.92,.36,.22,.14)
		draw_rect(Rect2(start,-lane,span,lane*2.),danger)
		draw_line(Vector2(start,lane),Vector2(start+span*clampf(elapsed/d[0],0,1),lane),Color(.97,.59,.34,.75),2)
	if kind=="cantor" and hp>0 and arena.chimes_alive():
		draw_arc(Vector2(0,-66),62.,-PI,PI,56,Color(.58,.91,.92,.65),2,true)
	if not playable and hp>0 and hp<max_hp and kind!="headsman":
		draw_rect(Rect2(-18,-132,36,3),Color("#272427"))
		draw_rect(Rect2(-18,-132,36.*hp/max_hp,3),Color("#d6956f"))
