extends Node2D

var arena

# This layer is above the Y-sorted actors, so the supporting raider cannot
# cover the windup marker when the fighters cross in the same lane.
func _draw():
	for raider in arena.enemies:
		if raider.kind!="raider" or raider.state!="attack" or raider.did_hit: continue
		var tip:Vector2=raider.position+Vector2(0,-101)
		var marker:=PackedVector2Array([tip+Vector2(-8,-13),tip+Vector2(8,-13),tip])
		draw_colored_polygon(marker,Color("#ffdc98"))
		marker.append(marker[0])
		draw_polyline(marker,Color("#342723"),2.,true)
