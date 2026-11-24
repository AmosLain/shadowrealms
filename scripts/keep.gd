extends Node2D
const Crosswind = preload("res://scripts/crosswind.gd")
const Furnace = preload("res://scripts/furnace.gd")
const Actor = preload("res://scripts/fighter.gd")
const Rules = preload("res://scripts/rules.gd")
const Effect = preload("res://scripts/effect.gd")
const Sound = preload("res://scripts/sound.gd")
var hero
var ward_links
var raider_marker
var enemies: Array=[]
var shots: Array=[]
var moving_shots:Array=[]
var loot: Array=[]
var level_state:="title"
var save_path := "user://cinder-v1.cfg"
var counters := 0
var counter_notice := 0.0
var dust_timer:=0.
var wave:=-1
var checkpoint:=0
var checkpoint_counters:=0
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
		if event.is_action_pressed("left"): hero.tap_horizontal(-1)
		if event.is_action_pressed("right"): hero.tap_horizontal(1)
		if event.is_action_released("jump"): hero.release_jump()
		for action in ["attack","jump","magic","special"]:
			if event.is_action_pressed(action): hero.command(action)

func _notification(what:int):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and level_state=="play":
		pause_game()

func pause_game():
	if level_state=="play":
		hero.clear_pending_input()
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
	var count=cfg.get_value("journey","counters",0)
	return {"role":role,"stage":stage,"counters":maxi(0,count) if typeof(count)==TYPE_INT else 0}

func save_journey():
	if save_path.is_empty(): return
	var cfg:=ConfigFile.new()
	cfg.set_value("journey","role",selected)
	cfg.set_value("journey","gate",checkpoint)
	cfg.set_value("journey","counters",checkpoint_counters)
	if cfg.save(save_path+".tmp")==OK:
		DirAccess.rename_absolute(save_path+".tmp",save_path)

func resume_journey():
	var slot:=read_journey()
	if slot.is_empty(): return
	selected=slot.role
	begin(slot.stage,slot.counters)

func begin(stage:=0, banked_counters:=0):
	counter_notice = 0.0
	counters = banked_counters
	checkpoint_counters = banked_counters
	for vent in $Floor.get_children():
		$Floor.remove_child(vent)
		vent.queue_free()
	for node in road.get_children():
		road.remove_child(node)
		node.queue_free()
	enemies.clear()
	shots.clear()
	moving_shots.clear()
	loot.clear()
	ward_links=null
	checkpoint=stage
	wave=stage-1
	locked=false
	left_bound=10.
	right_bound=Rules.END_X
	level_state="play"
	touch_vector=Vector2.ZERO
	hero=spawn(selected,Vector2(135 if stage==0 else Rules.GATES[stage]-300,405))
	raider_marker=preload("res://scripts/raider_marker.gd").new()
	raider_marker.arena=self
	raider_marker.z_index=2
	road.add_child(raider_marker)
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
	if ward_links: ward_links.queue_redraw()
	raider_marker.queue_redraw()
	step_objects(dt)
	counter_notice = maxf(0.0,counter_notice-dt)
	var enraged:bool = wave==2 and not enemies.is_empty() and enemies[0].phase_two
	for vent in $Floor.get_children():
		if vent is Crosswind:
			vent.step(dt)
		elif vent is Furnace and absf(hero.position.x-vent.position.x)<500:
			vent.step(dt,enraged)
	if hero.hp<=0 and hero.elapsed>1.1:
		level_state="lost"
		ui.menu("lost")
		return
	if not locked and wave+1<Rules.WAVES.size() and hero.position.x>=Rules.GATES[wave+1]-240.:
		start_wave()
	elif locked and enemies.is_empty():
		locked=false
		if wave==4:
			for hazard in $Floor.get_children():
				if hazard is Crosswind:
					$Floor.remove_child(hazard)
					hazard.queue_free()
		if wave==Rules.WAVES.size()-1:
			if not save_path.is_empty() and FileAccess.file_exists(save_path): DirAccess.remove_absolute(save_path)
			level_state="won"
			ui.menu("won")
		else:
			drop(hero.position+Vector2(36,-5),"health")
			drop(hero.position+Vector2(86,6),"mana")
			if wave in [0,2,4]: drop(hero.position+Vector2(125,-4),"ember")
			checkpoint=wave+1
			checkpoint_counters=counters
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
	if wave==4:
		var gust:=Crosswind.new()
		gust.arena=self
		gust.position.x=left_bound
		$Floor.add_child(gust)
	var n:=0
	for type in Rules.WAVES[wave]:
		var e=spawn(type,Vector2(center+120+n*58,365.+(n%3)*34.))
		if type=="chime":
			e.position=Vector2(center+(-145 if n%2 else 148),355 if n%2 else 438)
		e.cooldown=.4+n*.3
		enemies.append(e)
		n+=1
	if wave==Rules.WAVES.size()-1:
		ward_links=preload("res://scripts/crown_ward.gd").new()
		for enemy in enemies:
			if enemy.kind=="cantor": ward_links.cantor=enemy
			if enemy.kind=="chime": ward_links.seals.append(enemy)
		$Floor.add_child(ward_links)

func chimes_alive() -> bool:
	for enemy in enemies:
		if enemy.kind=="chime" and enemy.hp>0: return true
	return false

func shoulder_hit(source) -> bool:
	var nearest=null
	var distance:=INF
	for enemy in enemies:
		if enemy.hp<=0 or enemy.invincible>0. or enemy.lift>30 or source.contact_targets.has(enemy.get_instance_id()): continue
		var gap:Vector2=enemy.position-source.position
		var forward:float=gap.x*source.face
		if forward < -4 or forward>Rules.MOVES.shoulder[2]+19 or absf(gap.y)>Rules.MOVES.shoulder[3]+12: continue
		if forward<distance:
			distance=forward
			nearest=enemy
	if nearest==null: return false
	if nearest.damage(source.attack_damage(Rules.MOVES.shoulder[4]),source.face*315.,true):
		source.impact_hold=.05
		nearest.impact_hold=.05
		sound.play("impact")
		fx(source.position+Vector2(source.face*25,-65),"impact")
		shake=4.
		return true
	# A ward can reject contact on several consecutive active frames.
	source.contact_targets[nearest.get_instance_id()]=true
	return false

func opening_cut(source, time:float):
	var reach:float=(73. if Rules.cut_frame(time)==1 else 96.) * absf(source.rig.scale.y)
	var volume:CollisionShape2D=source.hit.get_child(0)
	volume.shape.size=Vector2(reach,Rules.MOVES.cut[3]*2.)
	source.hit.position.x=source.face*reach*.5
	for target in enemies:
		var id:int=target.get_instance_id()
		if source.contact_targets.has(id) or target.hp<=0 or target.lift>40.: continue
		var body:CollisionShape2D=target.hurt.get_child(0)
		if not volume.shape.collide(volume.global_transform,body.shape,body.global_transform): continue
		if not target.damage(source.attack_damage(Rules.MOVES.cut[4]),source.face*145.,false): continue
		source.contact_targets[id]=true
		source.impact_hold=Rules.CUT_FREEZE
		target.impact_hold=Rules.CUT_FREEZE
		target.cut_reaction=.17
		target.rig.queue_redraw()
		var along:float=clampf((target.position.x-source.position.x)*source.face-8.,0.,reach)
		var point:Vector2=source.position+Vector2(along*source.face,-74.*absf(source.rig.scale.y))
		fx(point,"blade",source.face)
		sound.play("impact")
		shake=1.5

func strike(source):
	if source.move=="cut":
		if source.elapsed>=Rules.MOVES.cut[0] and source.elapsed<Rules.CUT_RELEASE:
			opening_cut(source,source.elapsed)
		return
	var data: Array=Rules.MOVES[source.move]
	if source.move=="toll":
		var rune=preload("res://scripts/toll.gd").new()
		rune.position=hero.position
		rune.arena=self
		$Floor.add_child(rune)
		sound.play("bell")
		return
	if source.move in ["starfall","fault"]:
		launch_volley(source)
		return
	if source.move in ["cast","spark","peal"]:
		var mark:=Polygon2D.new()
		mark.polygon=PackedVector2Array([Vector2(-13,0),Vector2(-3,-6),Vector2(11,0),Vector2(-3,6)])
		mark.color=Color("#ffa45b") if source==hero else Color("#db9bd9")
		road.add_child(mark)
		mark.position=source.position
		mark.offset.y=-40
		shots.append([mark,source.face,1.85,source==hero,source.attack_damage(data[4])])
		if source.move=="peal":
			for offset in [-34,34]:
				var echo=mark.duplicate()
				road.add_child(echo)
				echo.position.y+=offset
				shots.append([echo,source.face,1.85,false,data[4]])
		sound.play("magic")
		return
	var radial: bool=source.move in ["magic","quake","bolt","plunge"]
	sound.play("magic" if radial else "swing")
	if radial: fx(source.position,"quake" if source.move=="plunge" else source.move)
	var targets: Array=enemies if source==hero else [hero]
	for target in targets:
		if target.hp<=0 or (target.lift>40 and source.move!="hook" and (not radial or source.move=="quake")): continue
		# Foot-plane shape query uses this tick's transforms, including the new attack volume.
		if (source.hit.collision_mask & target.hurt.collision_layer)==0: continue
		var attack_shape: CollisionShape2D=source.hit.get_child(0)
		var hurt_shape: CollisionShape2D=target.hurt.get_child(0)
		if attack_shape.shape.collide(attack_shape.global_transform,hurt_shape.shape,hurt_shape.global_transform):
			var dir:=signf(target.position.x-source.position.x)
			var damage:int=data[4]
			if source.kind=="swift" and source.move=="rend" and target.state=="attack": damage+=12
			if target.damage(source.attack_damage(damage),dir*(200 if data[5] else 90),data[5]):
				if not radial:
					var hold:=.050 if data[5] else .033
					source.impact_hold=maxf(source.impact_hold,hold)
					target.impact_hold=maxf(target.impact_hold,hold)
				fx(target.position-Vector2(0,49),"impact")
				sound.play("impact")
				shake=4. if data[5] else 2.

func launch_volley(source):
	var falling:bool=source.move=="starfall"
	var lanes:Array=[-1,0,1] if falling else [0]
	for lane in lanes:
		var shot=preload("res://scripts/arc_shot.gd").new()
		shot.configure(falling,source.position,source.face,lane,source.lift,source.attack_damage(Rules.MOVES[source.move][4]))
		road.add_child(shot)
		moving_shots.append(shot)
	sound.play("magic" if falling else "impact")

func fx(p: Vector2,type: String,facing:=1):
	var e=Effect.new()
	e.kind=type
	e.direction=facing
	e.position=p
	e.z_index=3
	road.add_child(e)

func drop(p:Vector2,type:String):
	var item:=Polygon2D.new()
	item.polygon=PackedVector2Array([Vector2(-3,-16),Vector2(3,-16),Vector2(3,-12),Vector2(8,-7),Vector2(6,0),Vector2(-5,0),Vector2(-8,-6),Vector2(-3,-12)])
	item.color=Color("#e99c85") if type=="health" else Color("#83d3d1")
	if type=="ember":
		item.color=Color("#ffbb53")
		item.polygon=PackedVector2Array([Vector2(-8,-10),Vector2(0,-25),Vector2(8,-10),Vector2(0,1)])
		var core:=Polygon2D.new()
		core.color=Color("#fff3be")
		core.polygon=PackedVector2Array([Vector2(0,-19),Vector2(3,-10),Vector2(0,-5),Vector2(-3,-10)])
		item.add_child(core)
	road.add_child(item)
	item.position=p
	loot.append([item,type])

func step_objects(dt:float):
	for shot in moving_shots.duplicate():
		if shot.advance(dt,enemies if shot.friendly else [hero]):
			moving_shots.erase(shot)
			shot.queue_free()
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
			elif item[1]=="ember": hero.ember_time=Rules.EMBER_SECONDS
			else: hero.mana=minf(100,hero.mana+40)
			sound.play("pickup")
			item[0].queue_free()
			loot.erase(item)

