extends Control

signal chat_toggled(open: bool)

@onready var chat_input: LineEdit = $ChatLineEdit

func _ready():
	chat_input.hide()
	chat_input.text_submitted.connect(_on_text_submitted)
	chat_input.gui_input.connect(_on_chat_gui_input)

func open_chat():
	chat_input.show()
	chat_input.grab_focus()
	chat_toggled.emit(true)

func close_chat():
	chat_input.clear()
	chat_input.release_focus()
	chat_input.hide()
	chat_toggled.emit(false)

func _on_text_submitted(text: String):
	text = text.strip_edges()
	if not text.is_empty():
		Network.send_message.rpc(text)
	close_chat()

func _on_chat_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		close_chat()
		chat_input.accept_event()
