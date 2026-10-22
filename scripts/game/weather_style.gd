class_name WeatherStyle
extends Resource
## Change 13: one weather's look (resources/game/weather_*.tres), tuned in the inspector. Particles
## are world-anchored (season_weather.gd lays them on a fixed world grid); weather never affects play.
## Animation sheet: `frames` cells of frame_size, left to right; leaves also use rows (frame_rows).
@export var texture: Texture2D
@export var frame_size:=Vector2(52,216)
@export var frames:=15
@export var frame_rows:=1
@export var fps:=10.0
## Drawn size of one particle in world units.
@export var draw_size:=Vector2(26,108)
## Particles per period cell, the cell size and the drift (world units per second).
@export var period:=Vector2(440,500)
@export var particles_per_period:=12
@export var drift:=Vector2(8,28)
@export var color:=Color(1,1,1,.4)
## Multiplies the map's own art (terrain, scenery, props) while this weather is active. White keeps
## the map as authored; rain darkens it slightly toward an overcast sky. Actors, loot, effects, HP
## bars, fog and camp markers are never tinted.
@export var ambient_tint:=Color.WHITE
