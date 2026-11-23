extends Node2D
const Furnace = preload("res://scripts/furnace.gd")
const Actor = preload("res://scripts/fighter.gd")
const Rules = preload("res://scripts/rules.gd")
const Effect = preload("res://scripts/effect.gd")
const Sound = preload("res://scripts/sound.gd")
var hero
var enemies: Array=[]
var shots: Array=[]
var loot: Array=[]
var level_state:="title"
var save_path := "user://cinder-v1.cfg"
var counters := 0
var counter_notice := 0.0
var dust_timer:=0.
var wave:=-1
var checkpoint:=0
var selected:="warden"
var locked:=false
var left_bound:=10.
var right_bound:=2850.
var scroll:=0.
var shake:=0.
var touch_vector:=Vector2.ZERO
var sound
var bindings={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"attack":[KEY_J],"jump":[KEY_K],"magic":[KEY_L],"special":[KEY_SHIFT],"pause":[KEY_ESCAPE]}
@onready var road=$Road
@onready var ui=$Interface
@onready var landscape=$Landscape

func _ready():
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in bindings[action]:
			var e:=InputEventKey.new()
			e.physical_keycode=key
			InputMap.action_add_event(action,e)
	sound=Sound.new()
	add_child(sound)
	ui.setup(self)
	ui.menu("title")

func _unhandled_input(event):
	if event.is_action_pressed("pause") and level_state in ["play","pause"]:
		pause_game()
	elif level_state=="play":
		for action in ["attack","jump","magic","special"]:
			if event.is_action_pressed(action): hero.command(action)

func pause_game():
	if level_state=="play":
		level_state="pause"
		ui.menu("pause")
	elif level_state=="pause":
		level_state="play"
		ui.menu("play")
	touch_vector=Vector2.ZERO

func read_journey() -> Dictionary:
	var cfg:=ConfigFile.new()
	if save_path.is_empty() or cfg.load(save_path)!=OK: return {}
	var role=cfg.get_value("journey","role","")
	var stage=cfg.get_value("journey","gate",-1)
	if role not in Rules.HEROES or typeof(stage)!=TYPE_INT or stage<0 or stage>=Rules.GATES.size(): return {}
	return {"role":role,"stage":stage}

func save_journey():
	if save_path.is_empty(): return
	var cfg:=ConfigFile.new()
	cfg.set_value("journey","role",selected)
	cfg.set_value("journey","gate",checkpoint)
	if cfg.save(save_path+".tmp")==OK:
		DirAccess.rename_absolute(save_path+".tmp",save_path)

func resume_journey():
	var slot:=read_journey()
	if slot.is_empty(): return
	selected=slot.role
	begin(slot.stage)

func begin(stage:=0):
	counter_notice = 0.0
	counters = 0
	for vent in $Floor.get_children():
		$Floor.remove_child(vent)
		vent.queue_free()
	for node in road.get_children():
		road.remove_child(node)
		node.queue_free()
	enemies.clear()
	shots.clear()
	loot.clear()
	checkpoint=stage
	wave=stage-1
	locked=false
	left_bound=10.
	right_bound=Rules.END_X
	level_state="play"
	touch_vector=Vector2.ZERO
	hero=spawn(selected,Vector2(135 if stage==0 else Rules.GATES[stage]-300,405))
	place_vent(Vector2(274,354),0.25)
	place_vent(Vector2(1390,399),0.55)
	place_vent(Vector2(2130,374),0.35)
	place_vent(Vector2(2290,425),2.25)
	scroll=clampf(hero.position.x-360,0,Rules.CAMERA_END)
	save_journey()
	ui.menu("play")

func place_vent(point: Vector2, delay: float):
	var vent = Furnace.new()
	vent.arm(self, point, delay)
	$Floor.add_child(vent)

func counter(attacker) -> bool:
	for enemy in enemies:
		if not enemy.can_be_countered_by(attacker): continue
		enemy.state = "hurt"
		enemy.elapsed = -0.60
		enemy.cooldown = 1.0
		attacker.mana = minf(100, attacker.mana + 15)
		attacker.invincible = maxf(attacker.invincible, 0.35)
		counter_notice = 0.95
		counters += 1
		sound.play("bell")
		fx(enemy.position - Vector2(0,55), "counter")
		return true
	return false

func spawn(type: String,p: Vector2):
	var unit=Actor.new()
	road.add_child(unit)
	unit.configure(type,self)
	unit.position=p
	return unit

func _physics_process(dt):
	if level_state!="pause":
		landscape.clock+=dt
		landscape.queue_redraw()
	if level_state!="play": return
	var direction:=Input.get_vector("left","right","up","down")+touch_vector
	var height_before:float=hero.lift
	hero.step(dt,direction.limit_length())
	dust_timer-=dt
	if (height_before>0 and hero.lift<=0) or (hero.state=="walk" and hero.lift<=0 and dust_timer<=0):
		fx(hero.position,"dust")
		dust_timer=.33
	for enemy in enemies.duplicate():
		enemy.step(dt,Vector2.ZERO)
		if enemy.hp==0 and enemy.elapsed>1.6:
			enemies.erase(enemy)
			enemy.queue_free()
	step_objects(dt)
	counter_notice = maxf(0.0,counter_notice-dt)
	var enraged:bool = wave==2 and not enemies.is_empty() and enemies[0].phase_two
	for vent in $Floor.get_children():
		if vent is Furnace and absf(hero.position.x-vent.position.x)<500:
			vent.step(dt,enraged)
	if hero.hp<=0 and hero.elapsed>1.1:
		level_state="lost"
		ui.menu("lost")
		return
	if not locked and wave+1<Rules.WAVES.size() and hero.position.x>=Rules.GATES[wave+1]-240.:
		start_wave()
	elif locked and enemies.is_empty():
		locked=false
		if wave==Rules.WAVES.size()-1:
			if not save_path.is_empty() and FileAccess.file_exists(save_path): DirAccess.remove_absolute(save_path)
			level_state="won"
			ui.menu("won")
		else:
			drop(hero.position+Vector2(36,-5),"health")
			drop(hero.position+Vector2(86,6),"mana")
			checkpoint=wave+1
			save_journey()
			left_bound=maxf(10.,Rules.GATES[wave]-330.)
			right_bound=Rules.END_X
	var target:=clampf(hero.position.x-360.,0.,Rules.CAMERA_END)
	scroll=lerpf(scroll,target,1.-exp(-8.*dt))
	shake=move_toward(shake,0.,dt*20.)
	road.position=Vector2(-scroll+sin(landscape.clock*100)*shake,0)
	$Floor.position=road.position
	landscape.scroll=scroll
	ui.refresh()

func start_wave():
	wave+=1
	checkpoint=wave
	locked=true
	var center: float=Rules.GATES[wave]
	left_bound=center-335.
	right_bound=center+340.
	var n:=0
	for type in Rules.WAVES[wave]:
		var e=spawn(type,Vector2(center+120+n*58,365.+(n%3)*34.))
		if type=="chime":
			e.position=Vector2(center+(-145 if n%2 else 148),355 if n%2 else 438)
		e.cooldown=.4+n*.3
		enemies.append(e)
		n+=1

func chimes_alive() -> bool:
	for enemy in enemies:
		if enemy.kind=="chime" and enemy.hp>0: return true
	return false

func strike(source):
	var data: Array=Rules.MOVES[source.move]
	if source.move=="toll":
		var rune=preload("res://scripts/toll.gd").new()
		rune.position=hero.position
		rune.arena=self
		$Floor.add_child(rune)
		sound.play("bell")
		return
	if source.move in ["cast","spark","peal"]:
		var mark:=Polygon2D.new()
		mark.polygon=PackedVector2Array([Vector2(-13,0),Vector2(-3,-6),Vector2(11,0),Vector2(-3,6)])
		mark.color=Color("#ffa45b") if source==hero else Color("#db9bd9")
		road.add_child(mark)
		mark.position=source.position
		mark.offset.y=-40
		shots.append([mark,source.face,1.85,source==hero,data[4]])
		if source.move=="peal":
			for offset in [-34,34]:
				var echo=mark.duplicate()
				road.add_child(echo)
				echo.position.y+=offset
				shots.append([echo,source.face,1.85,false,data[4]])
		sound.play("magic")
		return
	var radial: bool=source.move in ["magic","quake","bolt"]
	sound.play("magic" if radial else "swing")
	if radial: fx(source.position,source.move)
	var targets: Array=enemies if source==hero else [hero]
	for target in targets:
		if target.hp<=0 or (target.lift>40 and (not radial or source.move=="quake")): continue
		# Foot-plane shape query uses this tick's transforms, including the new attack volume.
		if (source.hit.collision_mask & target.hurt.collision_layer)==0: continue
		var attack_shape: CollisionShape2D=source.hit.get_child(0)
		var hurt_shape: CollisionShape2D=target.hurt.get_child(0)
		if attack_shape.shape.collide(attack_shape.global_transform,hurt_shape.shape,hurt_shape.global_transform):
			var dir:=signf(target.position.x-source.position.x)
			var damage:int=data[4]
			if source.kind=="swift" and source.move=="rend" and target.state=="attack": damage+=12
			if target.damage(damage,dir*(200 if data[5] else 90),data[5]):
				fx(target.position-Vector2(0,49),"impact")
				sound.play("impact")
				shake=4. if data[5] else 2.

func fx(p: Vector2,type: String):
	var e=Effect.new()
	e.kind=type
	e.position=p
	e.z_index=3
	road.add_child(e)

func drop(p:Vector2,type:String):
	var item:=Polygon2D.new()
	item.polygon=PackedVector2Array([Vector2(-3,-16),Vector2(3,-16),Vector2(3,-12),Vector2(8,-7),Vector2(6,0),Vector2(-5,0),Vector2(-8,-6),Vector2(-3,-12)])
	item.color=Color("#e99c85") if type=="health" else Color("#83d3d1")
	road.add_child(item)
	item.position=p
	loot.append([item,type])

func step_objects(dt:float):
	for s in shots.duplicate():
		s[0].position.x+=s[1]*(395. if s[3] else 268.)*dt
		s[2]-=dt
		var targets:Array=enemies if s[3] else [hero]
		for target in targets:
			if target.hp<=0: continue
			var delta_pos:Vector2=target.position-s[0].position
			if absf(delta_pos.x)<24 and absf(delta_pos.y)<20 and target.lift<38:
				if target.damage(s[4],s[1]*110,false): fx(target.position-Vector2(0,44),"impact")
				s[2]=0.
				break
		if s[2]<=0:
			shots.erase(s)
			s[0].queue_free()
	for item in loot.duplicate():
		item[0].offset.y=-3.+sin(landscape.clock*4)*3.
		if hero.position.distance_to(item[0].position)<32 and hero.hp>0:
			if item[1]=="health": hero.hp=mini(hero.max_hp,hero.hp+52)
			else: hero.mana=minf(100,hero.mana+40)
			sound.play("pickup")
			item[0].queue_free()
			loot.erase(item)

