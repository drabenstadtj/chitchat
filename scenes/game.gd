extends Node3D

const PLAYER_SCENE = preload("res://scenes/player.tscn")

@onready var players: Node3D = $Players
@onready var spawn_points: Node3D = $SpawnPoints
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready():
	spawner.spawn_function = _spawn_player  # must run on every peer
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(1)

func add_player(id: int):
	var index = players.get_child_count() % spawn_points.get_child_count()
	var pos = spawn_points.get_child(index).global_position
	spawner.spawn({"id": id, "pos": pos})

func _spawn_player(data: Dictionary) -> Node:
	var player = PLAYER_SCENE.instantiate()
	player.name = str(data.id)
	player.position = data.pos
	return player

func remove_player(id: int):
	var player = players.get_node_or_null(str(id))
	if player:
		player.queue_free()
