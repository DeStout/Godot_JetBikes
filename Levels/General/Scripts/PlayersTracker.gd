extends Node

signal race_finished

var npc
var player = load("res://Racers/SinglePlayer_Player/Player.tscn")
var crash_bike = load("res://Racers/General/Bike/Assets/Models/CrashBike.tscn")
var players : Array
var path_nodes_size : int

func _ready() -> void:
	if Globals.NPC_number != 0:
		npc = load("res://Racers/SinglePlayer_NPC/NPC.tscn")
	_spawn_players()
	players = get_children()
	players.erase($CrashBikes)
	
func _process(delta : float) -> void:
	players.sort_custom(self, "_sort_placement")
	_alert_players()
		
func _spawn_players():
	player = player.instance()
	player.connect("finished_race", self, "finish_race")
	add_child(player)
	player.global_transform = get_node("PlayerSpawn"+str(Globals.NPC_number+1)).global_transform
	
	crash_bike = crash_bike.instance()
	player.crash_bike = crash_bike
	$CrashBikes.add_child(crash_bike)
	
	if Globals.NPC_number > 0:
		for NPC_num in range(Globals.NPC_number):
			var new_NPC = npc.instance()
			new_NPC.name = "NPC" + str(NPC_num + 1)
			new_NPC.global_transform = get_node("PlayerSpawn"+str(NPC_num+1)).global_transform
			new_NPC.connect("finished_race", self, "finish_race")
			add_child(new_NPC)
			get_node("PlayerSpawn"+str(NPC_num+1)).free()
	
	for spawn in range(Globals.NPC_number+1, 13):
		get_node("PlayerSpawn"+str(spawn)).free()

func setup_players(track_navigation, path_nodes):
	player.navigation = track_navigation
	player.path_nodes = path_nodes
	player.current_path_node = path_nodes[0]
	
	for npc_temp in players:
		if npc_temp is NPC:
			npc_temp.navigation = track_navigation
			npc_temp.path_nodes = path_nodes
			npc_temp.current_path_node = path_nodes[0]
			npc_temp.pathfind_next_node()
	
func start_race() -> void:
	for racer in players:
		racer.start_race()
	
func finish_race() -> void:
	emit_signal("race_finished")
	for racer in players:
		racer.finish_race()
	
func _alert_players() -> void:
	if get_child_count() - 1 == players.size():
		for new_placement in range(players.size()):
			players[new_placement].placement = new_placement + 1
			if players[new_placement] is Player:
				player.HUD.set_placement(new_placement + 1)
	else:
		push_error("Player Tracker child count does not match array size")

func _sort_placement(player1 : KinematicBody, player2 : KinematicBody) -> bool:
	if !path_nodes_size:
		path_nodes_size = player.path_nodes.size()
		
	if player1.lap_number > player2.lap_number:
		return true
	elif player2.lap_number > player1.lap_number:
		return false
	else:
		var player1_serial = player1.current_path_node.serial
		var player2_serial = player2.current_path_node.serial
		if player1_serial == 0:
			player1_serial = path_nodes_size
		if player2_serial == 0:
			player2_serial = path_nodes_size
			
		if player1_serial > player2_serial:
			return true
		elif player2_serial > player1_serial:
			return false
		else:
			if player1.path_node_distance < player2.path_node_distance:
				return true
			else:
				return false
