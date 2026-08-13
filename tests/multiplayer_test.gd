extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	for participant_count in [2, 3, 4]:
		for selected_amount in [20, 30, 40, 50, 70]:
			var game: Node = load("res://main.tscn").instantiate()
			root.add_child(game)
			await process_frame
			game.players_option.select(participant_count - 2)
			game.cards_option.select([20, 30, 40, 50, 70].find(selected_amount))
			game.start_game()
			await process_frame

			assert(game.total_players == participant_count)
			assert(game.cards_per_player == selected_amount)
			assert(game.player_piles.size() == participant_count)
			assert(game.active_card_indices.size() == participant_count)
			assert(game.cpu_symbols.size() == participant_count - 1)
			for pile in game.player_piles:
				assert(pile.size() == selected_amount)

			for player_index in participant_count:
				assert(game.active_card_indices[player_index] != game.center_card_index)
				var personal_card: Array = game.player_symbols if player_index == 0 else game.cpu_symbols[player_index - 1]
				assert(_match_count(personal_card, game.center_symbols) == 1)

			# La CPU azul descarta todo. Los demás conservan sus montones completos.
			for discarded in selected_amount:
				var old_cpu_card: Array = game.cpu_symbols[0].duplicate()
				assert(game._common_symbol(old_cpu_card, game.center_symbols) >= 0)
				var finished: bool = game._discard_winner_card(1)
				assert(game.center_symbols == old_cpu_card)
				assert(game.player_piles[1].size() == selected_amount - discarded - 1)
				assert(finished == (discarded == selected_amount - 1))
				if not finished:
					for player_index in participant_count:
						var next_card: Array = game.player_symbols if player_index == 0 else game.cpu_symbols[player_index - 1]
						assert(_match_count(next_card, game.center_symbols) == 1)

			assert(game.player_piles[1].is_empty())
			assert(game.player_piles[0].size() == selected_amount)
			for player_index in range(2, participant_count):
				assert(game.player_piles[player_index].size() == selected_amount)
			game._finish_game(1)
			await process_frame
			assert(game.result_panel.visible)
			assert("CPU AZUL" in game.result_title.text)
			assert(game.fx_root.get_node_or_null("XDerrotaFinal") != null)
			assert(game.audio_player.stream == game.final_lose_sound)

			game.return_to_menu()
			game.queue_free()
			await process_frame

	print("OK: 20/30/40/50/70 cartas iguales para 2, 3 y 4 participantes.")
	quit(0)


func _match_count(first: Array, second: Array) -> int:
	var amount := 0
	for symbol in first:
		if second.has(symbol):
			amount += 1
	return amount
