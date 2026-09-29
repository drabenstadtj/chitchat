extends Control

@onready var ip_input: LineEdit = $CenterContainer/VBoxContainer/IPLineEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_host_button_pressed() -> void:
	if Network.host() == OK:
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_join_button_pressed() -> void:
	var address = ip_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	if Network.join(address) == OK:
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
