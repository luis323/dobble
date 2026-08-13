extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.cards_option.select(0)
	game._create_lan_room()
	assert(game.lan_manager.mode == "host")

	var limit := Time.get_ticks_msec() + 15000
	while game.network_peer_ids.size() < 4 and Time.get_ticks_msec() < limit:
		await create_timer(0.05).timeout
	assert(game.network_peer_ids.size() == 4)
	game._start_lan_match_host()
	assert(game.game_active)
	assert(game.total_players == 4)
	assert(game.player_piles.size() == 4)
	await create_timer(1.0).timeout
	print("LAN_4_SERVER_OK: anfitrión inició una sala con cuatro jugadores.")
	game.lan_manager.leave()
	quit(0)
