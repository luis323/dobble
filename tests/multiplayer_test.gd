extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	for participant_count in [2, 3, 4]:
		var game: Node = load("res://main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.players_option.select(participant_count - 2)
		game.start_game()
		await process_frame

		assert(game.total_players == participant_count)
		assert(game.scores.size() == participant_count)
		assert(game.cpu_symbols.size() == participant_count - 1)
		assert(game.prize_total == 31 - participant_count)
		assert(game.touch_buttons.size() == 6)

		# Cada participante tiene exactamente una coincidencia con la central.
		var human_matches := 0
		for symbol in game.player_symbols:
			if game.center_symbols.has(symbol):
				human_matches += 1
		assert(human_matches == 1)
		for cpu_card in game.cpu_symbols:
			var cpu_matches := 0
			for symbol in cpu_card:
				if game.center_symbols.has(symbol):
					cpu_matches += 1
			assert(cpu_matches == 1)

		# Una CPU puede ganar y su puntuación no modifica a los demás.
		var cpu_match: int = game._common_symbol(game.cpu_symbols[0], game.center_symbols)
		game._score_round(1, cpu_match)
		await process_frame
		assert(game.scores[0] == 0)
		assert(game.scores[1] == 1)
		assert(game.fx_root.get_node_or_null("XDerrotaRonda") != null)
		assert(game.audio_player.stream == game.cpu_win_sound)
		for index in range(2, participant_count):
			assert(game.scores[index] == 0)

		# Completa toda la partida alternando ganadores. Así se comprueba que cada
		# carta central se entrega una sola vez y que la suma final es correcta.
		var awarded := 1
		while game.deck_cursor < game.deck.size():
			game._start_round()
			var winner: int = awarded % int(participant_count)
			var personal_card: Array = game.player_symbols if winner == 0 else game.cpu_symbols[winner - 1]
			var match_id: int = game._common_symbol(personal_card, game.center_symbols)
			assert(match_id >= 0)
			var previous_score: int = game.scores[winner]
			game._score_round(winner, match_id)
			assert(game.scores[winner] == previous_score + 1)
			awarded += 1
		game._finish_game()
		var score_sum := 0
		for score in game.scores:
			score_sum += score
		assert(awarded == game.prize_total)
		assert(score_sum == game.prize_total)
		assert(game.result_panel.visible)

		# Una derrota final del jugador usa una X diferente y otro sonido.
		game.scores[0] = 0
		game.scores[1] = 99
		game._finish_game()
		await process_frame
		assert(game.fx_root.get_node_or_null("XDerrotaFinal") != null)
		assert(game.audio_player.stream == game.final_lose_sound)

		game.return_to_menu()
		game.queue_free()
		await process_frame

	print("OK: multijugador CPU validado para 2, 3 y 4 participantes.")
	quit(0)
