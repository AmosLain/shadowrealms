extends Control
var arena
var finger:=-1
var knob:=Vector2.ZERO
const ORIGIN=Vector2(97,447)
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
						arena.hero.command(a)
						break
		elif event.index==finger:
			reset()
	elif event is InputEventScreenDrag and event.index==finger: drag(event.position)
func reset():
	finger=-1
	knob=Vector2.ZERO
	arena.touch_vector=Vector2.ZERO
	queue_redraw()
func drag(p:Vector2):
	knob=(p-ORIGIN).limit_length(48)
	arena.touch_vector=knob/48.
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

