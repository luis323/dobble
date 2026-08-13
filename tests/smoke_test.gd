extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	await process_frame

	assert(game.deck.size() == 31)
	assert(game.cards_per_player == 20)
	assert(game.player_piles.size() == 2)
	assert(game.player_piles[0].size() == 20)
	assert(game.player_piles[1].size() == 20)
	assert(game.human_card != null)
	assert(game.center_card != null)
	assert(game.touch_buttons.size() == 6)
	for button in game.touch_buttons:
		assert(button.flat)
		for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			var style: StyleBoxFlat = button.get_theme_stylebox(state)
			assert(style.bg_color.a == 0.0)

	var first_personal_card: Array[int] = game.player_symbols.duplicate()
	var first_center_card: Array[int] = game.center_symbols.duplicate()
	var matching: int = game._common_symbol(game.player_symbols, game.center_symbols)
	assert(matching >= 0)
	var matching_index: int = game.player_symbols.find(matching)
	var wrong_index := 0 if matching_index != 0 else 1

	# Un error bloquea exactamente cinco segundos y luego habilita la carta.
	game.touch_buttons[wrong_index].pressed.emit()
	await process_frame
	assert(game.human_locked)
	assert(game.WRONG_PENALTY_SECONDS == 5)
	for button in game.touch_buttons:
		assert(button.disabled)
	game.cpu_round_token += 1
	await create_timer(5.15).timeout
	assert(not game.human_locked)
	assert(game.round_active)

	# Al acertar se descarta la carta propia y esa carta pasa al centro.
	game.touch_buttons[matching_index].pressed.emit()
	game.touch_buttons[matching_index].pressed.emit()
	await process_frame
	assert(game.scores[0] == 1)
	assert(game.player_piles[0].size() == 19)
	assert(game.player_piles[1].size() == 20)
	assert(game.center_symbols == first_personal_card)
	assert(game.center_symbols != first_center_card)
	assert(game.human_card.position.y > 0.12)
	await create_timer(1.1).timeout
	assert(game.round_active)
	assert(game._common_symbol(game.player_symbols, game.center_symbols) >= 0)

	# Con una última carta, acertar termina la partida de inmediato.
	game.player_piles[0] = [game.active_card_indices[0]]
	var last_match: int = game._common_symbol(game.player_symbols, game.center_symbols)
	game._score_round(0, last_match)
	assert(game.player_piles[0].is_empty())
	await create_timer(1.1).timeout
	assert(not game.game_active)
	assert(game.result_panel.visible)
	assert("GANASTE LA PARTIDA" in game.result_title.text)
	print("OK: descarte al centro, victoria en cero y penalización de 5 segundos.")
	game.queue_free()
	await process_frame
	quit(0)
