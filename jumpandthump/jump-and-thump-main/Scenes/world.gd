extends Node2D

var players  = []
const PLAYER_BLUE = preload("res://Scenes/player_blue.tscn")
const PLAYER_GREEN = preload("res://Scenes/player_green.tscn")
const PLAYER_RED = preload("res://Scenes/player_red.tscn")
const PLAYER_YELLOW = preload("res://Scenes/player_yellow.tscn")
@onready var spawn1 = $spawn1
@onready var spawn2 = $spawn2
@onready var spawn3 = $spawn3
@onready var spawn4 = $spawn4
const SPEED_UP = preload("res://Scenes/speed_up.tscn")
@onready var spawnlocations = $PowerUps.get_children()
func _ready():
	if Globals.players == 4:
		create_player(PLAYER_RED, spawn1)
		create_player(PLAYER_BLUE, spawn2)
		create_player(PLAYER_GREEN, spawn3)
		create_player(PLAYER_YELLOW, spawn4)
	if Globals.players ==3:
		create_player(PLAYER_RED, spawn1)
		create_player(PLAYER_BLUE, spawn2)
		create_player(PLAYER_GREEN, spawn3)
	if Globals.players == 2:
		create_player(PLAYER_BLUE, spawn2)
		create_player(PLAYER_RED, spawn1)
	

func create_player(color,spawn):
	var player = color.instantiate()
	player.global_position = spawn.global_position
	add_child(player)
	players.append(player)
		
func _process(delta):
	for player in players:
		if player.score >= 9:
			print(player.name + " wins")
	
		
		
	


func _on_timer_timeout():
	var powerup = SPEED_UP.instantiate()
	powerup.global_position = spawnlocations.pick_random().global_position
	add_child(powerup)
	
