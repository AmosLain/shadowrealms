extends RefCounted
const HEROES = ["warden","seer","swift"]
const NAMES = {"warden":"Orra Venn","seer":"Edrin Vey","swift":"Vessa Rill"}
const UNITS = {
	"chime": [58, 0, 1.18, "c7ad78", "597483"],
	"cantor": [204, 82, 1.32, "ece0b9", "3d6670"],
	"seer": [95, 200, 0.98, "adbdba", "374d73"],
	"swift": [115, 229, 0.94, "b9b0a3", "413657"],
	"warden": [150, 186, 1.05, "c69954", "244e53"],
	"raider": [40, 139, 0.89, "948572", "8c392e"],
	"brute": [86, 76, 1.24, "a88a71", "594052"],
	"cultist": [42, 104, 0.97, "91acac", "4a416a"],
	"headsman": [250, 91, 1.46, "dba96d", "662c39"]
}
# windup, recovery, reach, lane tolerance, damage, knockdown
const MOVES = {
	"toll": [.42,.87,320,25,18,false],
	"peal": [.88,.90,340,20,12,false],
	"spark": [.16,.26,360,24,19,false],
	"blink": [.09,.32,85,26,14,false],
	"bolt": [.26,.43,302,54,47,true],
	"nick": [.07,.15,86,22,12,false],
	"cross": [.09,.17,91,24,15,false],
	"rend": [.14,.22,103,29,23,true],
	"lunge": [.09,.31,98,27,26,true],
	"cut": [.12,.22,103,25,16,false],
	"return": [.10,.25,109,26,19,false],
	"cleave": [.22,.35,122,32,29,true],
	"special": [.38,.51,145,40,38,true],
	"magic": [.20,.44,225,74,35,true],
	"jab": [.36,.51,72,23,9,false],
	"crush": [.68,.76,104,32,19,true],
	"cast": [.64,.80,320,22,12,false],
	"reap": [.55,.68,131,38,21,true],
	"quake": [.90,.85,160,64,27,true]
}
const WAVES = [
	["raider","raider"],
	["brute","cultist","raider"],
	["headsman"],
	["chime","brute","cultist"],
	["raider","brute","chime","raider"],
	["cantor","chime","chime"]
]
const PLACES = ["The Ash Causeway","The Broken Choir","The Sentence Gate","The Pilgrim Stairs","The Wind Gallery","The Bell Crown"]
const GATES = [540.,1350.,2190.,3000.,3840.,4650.]
const END_X = 5080.
const CAMERA_END = END_X - 960.

