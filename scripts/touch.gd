extends Control
var arena
var finger:=-1
var jump_finger:=-1
var stick_side:=0
var knob:=Vector2.ZERO
const ORIGIN=Vector2(97,447)
const STICK_RADIUS:=48.0
const STICK_DEAD_ZONE:=8.0
const BUTTONS={"attack":Vector2(874,437),"jump":Vector2(806,482),"magic":Vector2(798,398),"special":Vector2(906,349)}
func _input(event):
	if not visible or arena.level_state!="play": return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(ORIGIN)<88 and finger<0:
				finger=event.index
				drag(event.position)
			else:
				for a in BUTTONS:
					if event.position.distance_to(BUTTONS[a])<35:
						if a=="jump":
							if jump_finger>=0: break
							jump_finger=event.index
						arena.hero.command(a)
						break
		elif event.index==finger:
			finger=-1
			drag(ORIGIN)
		elif event.index==jump_finger:
			jump_finger=-1
			arena.hero.release_jump()
	elif event is InputEventScreenDrag and event.index==finger: drag(event.position)
func reset():
	stick_side=0
	if jump_finger>=0 and arena.hero: arena.hero.release_jump()
	jump_finger=-1
	finger=-1
	knob=Vector2.ZERO
	arena.touch_vector=Vector2.ZERO
	queue_redraw()
func drag(p:Vector2):
	knob=(p-ORIGIN).limit_length(STICK_RADIUS)
	if absf(knob.x)>=27 and (stick_side==0 or signf(knob.x)!=stick_side):
		stick_side=int(signf(knob.x))
		arena.hero.tap_horizontal(stick_side)
	elif absf(knob.x)<12: stick_side=0
	var strength:=maxf(0.,(knob.length()-STICK_DEAD_ZONE)/(STICK_RADIUS-STICK_DEAD_ZONE))
	arena.touch_vector=knob.normalized()*strength
	queue_redraw()
func _draw():
	draw_circle(ORIGIN,61,Color(.06,.10,.12,.55))
	draw_arc(ORIGIN,61,0,TAU,60,Color("#acafa2"),1.5,true)
	draw_circle(ORIGIN+knob,22,Color(.69,.73,.68,.55))
	for a in BUTTONS:
		var p:Vector2=BUTTONS[a]
		draw_circle(p,32 if a=="attack" else 29,Color(.08,.11,.14,.79))
		draw_arc(p,32 if a=="attack" else 29,0,TAU,40,Color("#cab992"),1.5,true)
		draw_string(ThemeDB.fallback_font,p+Vector2(-30,5),a.to_upper(),HORIZONTAL_ALIGNMENT_CENTER,60,12,Color("#f4e3c4"))

