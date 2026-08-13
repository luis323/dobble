extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var limit := Time.get_ticks_msec() + 20000
	# La difusión UDP no atraviesa el aislamiento del entorno de pruebas.
	# La app conserva la búsqueda automática y siempre ofrece IP manual.
	game._join_lan_address("127.0.0.1")

	while not game.game_active and Time.get_ticks_msec() < limit:
		await create_timer(0.05).timeout
	assert(game.game_active)
	assert(game.network_player_index == 1)
	assert(game.player_piles[1].size() == 20)
	var personal_before: Array[int] = game.player_symbols.duplicate()
	var match_id: int = game._common_symbol(game.player_symbols, game.center_symbols)
	assert(match_id >= 0)
	var wrong_id: int = game.player_symbols[0] if game.player_symbols[0] != match_id else game.player_symbols[1]
	game.submit_network_symbol.rpc_id(1, wrong_id)
	while not game.human_locked and Time.get_ticks_msec() < limit:
		await create_timer(0.05).timeout
	assert(game.human_locked)
	# El servidor ignora un acierto enviado durante los cinco segundos.
	game.submit_network_symbol.rpc_id(1, match_id)
	await create_timer(0.25).timeout
	assert(game.scores[1] == 0)
	await create_timer(5.15).timeout
	assert(not game.human_locked)
	game.submit_network_symbol.rpc_id(1, match_id)

	while game.scores[1] == 0 and Time.get_ticks_msec() < limit:
		await create_timer(0.05).timeout
	assert(game.scores[1] == 1)
	assert(game.player_piles[1].size() == 19)
	assert(game.center_symbols == personal_before)
	print("LAN_CLIENT_OK: conexión directa, penalización sincronizada y descarte confirmado.")
	await create_timer(0.15).timeout
	game.lan_manager.leave()
	quit(0)
