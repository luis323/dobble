extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._join_lan_address("127.0.0.1")

	var limit := Time.get_ticks_msec() + 15000
	while not game.game_active and Time.get_ticks_msec() < limit:
		await create_timer(0.05).timeout
	assert(game.game_active)
	assert(game.total_players == 4)
	assert(game.network_player_index >= 1 and game.network_player_index <= 3)
	assert(game.player_piles.size() == 4)
	print("LAN_4_CLIENT_OK: jugador %d recibió la partida de cuatro teléfonos." % [game.network_player_index + 1])
	await create_timer(0.35).timeout
	game.lan_manager.leave()
	quit(0)
