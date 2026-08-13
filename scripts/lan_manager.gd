class_name LanManager
extends Node

signal lobby_changed(peer_ids: Array[int])
signal connected_to_host
signal connection_error(message: String)
signal room_found(address: String, players: int)
signal server_lost(message: String)

const GAME_PORT := 7359
const DISCOVERY_PORT := 7360
const MAX_CLIENTS := 3
const ROOM_MAGIC := "SIMBOLOS_RELAMPAGO_140"

var mode := "offline"
var peer_ids: Array[int] = []
var discovery_sender: PacketPeerUDP
var discovery_listener: PacketPeerUDP
var broadcast_elapsed := 0.0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(delta: float) -> void:
	if mode == "host" and discovery_sender != null:
		broadcast_elapsed += delta
		if broadcast_elapsed >= 0.75:
			broadcast_elapsed = 0.0
			_broadcast_room()
	if discovery_listener != null:
		while discovery_listener.get_available_packet_count() > 0:
			var raw := discovery_listener.get_packet().get_string_from_utf8()
			var sender_ip := discovery_listener.get_packet_ip()
			var data = JSON.parse_string(raw)
			if data is Dictionary and data.get("magic", "") == ROOM_MAGIC:
				var advertised_ip := str(data.get("ip", sender_ip))
				if advertised_ip.is_empty() or advertised_ip == "0.0.0.0":
					advertised_ip = sender_ip
				room_found.emit(advertised_ip, int(data.get("players", 1)))


func create_room() -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(GAME_PORT, MAX_CLIENTS)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	mode = "host"
	peer_ids = [1]
	_start_broadcasting()
	lobby_changed.emit(peer_ids.duplicate())
	return OK


func join_room(address: String) -> Error:
	var clean_address := address.strip_edges()
	if clean_address.is_empty():
		return ERR_INVALID_PARAMETER
	leave()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(clean_address, GAME_PORT)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	mode = "client"
	return OK


func start_search() -> Error:
	stop_search()
	discovery_listener = PacketPeerUDP.new()
	discovery_listener.set_broadcast_enabled(true)
	var error := discovery_listener.bind(DISCOVERY_PORT, "0.0.0.0")
	if error != OK:
		discovery_listener = null
	return error


func stop_search() -> void:
	if discovery_listener != null:
		discovery_listener.close()
	discovery_listener = null


func stop_broadcasting() -> void:
	if discovery_sender != null:
		discovery_sender.close()
	discovery_sender = null


func leave() -> void:
	stop_search()
	if discovery_sender != null:
		discovery_sender.close()
	discovery_sender = null
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	mode = "offline"
	peer_ids.clear()


func local_ip() -> String:
	var fallback := "127.0.0.1"
	for address in IP.get_local_addresses():
		if ":" in address or address.begins_with("127."):
			continue
		fallback = address
		if address.begins_with("192.168.") or address.begins_with("10.") or _is_private_172(address):
			return address
	return fallback


func _is_private_172(address: String) -> bool:
	if not address.begins_with("172."):
		return false
	var parts := address.split(".")
	return parts.size() == 4 and int(parts[1]) >= 16 and int(parts[1]) <= 31


func _start_broadcasting() -> void:
	discovery_sender = PacketPeerUDP.new()
	discovery_sender.set_broadcast_enabled(true)
	discovery_sender.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	broadcast_elapsed = 1.0


func _broadcast_room() -> void:
	if discovery_sender == null:
		return
	var message := JSON.stringify({
		"magic": ROOM_MAGIC,
		"ip": local_ip(),
		"players": peer_ids.size(),
	})
	discovery_sender.put_packet(message.to_utf8_buffer())


func _on_peer_connected(peer_id: int) -> void:
	if mode != "host":
		return
	if not peer_ids.has(peer_id):
		peer_ids.append(peer_id)
		peer_ids.sort()
	lobby_changed.emit(peer_ids.duplicate())


func _on_peer_disconnected(peer_id: int) -> void:
	if mode == "host":
		peer_ids.erase(peer_id)
		lobby_changed.emit(peer_ids.duplicate())


func _on_connected_to_server() -> void:
	connected_to_host.emit()


func _on_connection_failed() -> void:
	connection_error.emit("No se pudo conectar con la sala.")
	leave()


func _on_server_disconnected() -> void:
	server_lost.emit("El anfitrión cerró la sala.")
	leave()
