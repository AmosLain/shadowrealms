extends Node2D

# A floor-level gale crosses one half of the Gallery. Its etched boundary,
# arrows and force all use the same band. The opposite band stays sheltered.
const WIDTH := 675.
const BAND_DEPTH := 52.
const WARNING := 1.25
const PULSE := .50
const REST := 2.6
const FORCE := 112.
const CLEARANCE := 26.
var arena
var phase := "warning"
var remaining := WARNING
var forward := true

func band() -> Rect2:
	return Rect2(0.,332. if forward else 461.-BAND_DEPTH,WIDTH,BAND_DEPTH)

func step(dt:float):
	while dt>0.:
		var interval:=minf(remaining,dt)
		if phase=="gust":
			push(arena.hero,interval)
			for enemy in arena.enemies: push(enemy,interval)
		dt-=interval
		remaining-=interval
		if remaining<=0.:
			match phase:
				"warning":
					phase="gust"
					remaining=PULSE
					arena.sound.play("vent")
				"gust":
					phase="rest"
					remaining=REST
				"rest":
					forward=not forward
					phase="warning"
					remaining=WARNING
	queue_redraw()

func push(unit,dt:float):
	if unit.hp<=0 or unit.kind=="chime" or unit.lift>=CLEARANCE or unit.impact_hold>0.: return
	var foot:Vector2=unit.position-position
	var strip:=band()
	if foot.y<strip.position.y or foot.y>strip.end.y or foot.x<0. or foot.x>WIDTH: return
	var dx:=FORCE*dt if forward else -FORCE*dt
	unit.position.x=clampf(unit.position.x+dx,arena.left_bound,arena.right_bound)

func _draw():
	if phase=="rest": return
	var strip:=band()
	var gust:=phase=="gust"
	var charge:=1.-remaining/WARNING if not gust else 1.
	var ink:=Color(.66,.95,1.,.26+.54*charge)
	draw_rect(strip,Color(.24,.65,.72,.09+.13*charge))
	for y in [strip.position.y,strip.end.y]:
		draw_dashed_line(Vector2(0,y),Vector2(WIDTH,y),ink,2.,12.)
	var direction:=1. if forward else -1.
	var shift:float=direction*(PULSE-remaining)*84. if gust else 0.
	for row in 2:
		for i in 10:
			var x:=fposmod(i*66.+row*31.+shift,WIDTH-30.)+15.
			var y:=strip.position.y+15.+row*22.
			var tip:=Vector2(x,y)
			draw_line(tip-Vector2(direction*10.,5.),tip,ink,2.,true)
			draw_line(tip-Vector2(direction*10.,-5.),tip,ink,2.,true)
			if gust: draw_line(tip-Vector2(direction*21.,0.),tip,ink,1.,true)
