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

	var limit := Time.get_ticks_msec() + 20000
	while game.network_peer_ids.size() < 2 and Time.get_ticks_msec() < limit:
		await create_timer(0.05).timeout
	assert(game.network_peer_ids.size() == 2)
	game._start_lan_match_host()
	assert(game.game_active)
	assert(game.network_round_accepting)

	while game.scores[1] == 0 and Time.get_ticks_msec() < limit:
		await create_timer(0.05).timeout
	assert(game.scores[1] == 1)
	assert(game.player_piles[1].size() == 19)
	print("LAN_SERVER_OK: cliente descartó y el servidor confirmó el estado.")
	await create_timer(0.25).timeout
	game.lan_manager.leave()
	quit(0)
