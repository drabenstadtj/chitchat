extends Node

const PORT = 7777
signal message_received(sender_id: int, text: String)

func host() -> Error:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	return err

func join(address: String) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(address, PORT)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	return err


@rpc("any_peer", "call_local", "reliable")
func send_message(text: String):
	var sender = multiplayer.get_remote_sender_id()
	message_received.emit(sender, text.left(200))
