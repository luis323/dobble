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
	assert(game.prize_total == 29)
	assert(game.human_card != null)
	assert(game.center_card != null)
	var fixed_personal_card: Array[int] = game.player_symbols.duplicate()
	var first_center_card: Array[int] = game.center_symbols.duplicate()
	var matching: int = game._common_symbol(game.player_symbols, game.center_symbols)
	assert(matching >= 0)
	assert(game.touch_buttons.size() == 6)
	for button in game.touch_buttons:
		assert(button.flat)
		for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			var style: StyleBoxFlat = button.get_theme_stylebox(state)
			assert(style.bg_color.a == 0.0)
	var matching_index: int = game.player_symbols.find(matching)
	assert(matching_index >= 0)
	var wrong_index := 0 if matching_index != 0 else 1
	game.touch_buttons[wrong_index].pressed.emit()
	await process_frame
	assert(game.scores[0] == 0)
	assert(game.round_active)
	assert(game.human_locked)
	assert(game.WRONG_PENALTY_SECONDS == 5)
	for button in game.touch_buttons:
		assert(button.disabled)
	# Aunque un dispositivo envíe otro evento, el bloqueo también se valida en
	# la lógica y no depende únicamente del estado visual del botón.
	game._on_human_symbol(matching)
	assert(game.scores[0] == 0)
	# Cancela solamente el intento de la CPU para poder esperar y comprobar los
	# cinco segundos completos de la penalización del jugador.
	game.cpu_round_token += 1
	await create_timer(5.15).timeout
	assert(not game.human_locked)
	assert(game.round_active)
	for button in game.touch_buttons:
		assert(not button.disabled)
	assert("YA PUEDES JUGAR" in game.status_label.text)
	# La selección usa botones 2D y nunca entra en el raycast físico 3D.
	game.touch_buttons[matching_index].pressed.emit()
	game.touch_buttons[matching_index].pressed.emit()
	await process_frame
	assert(game.scores[0] == 1)
	await create_timer(0.8).timeout
	assert(game.player_symbols == fixed_personal_card)
	assert(game.center_symbols != first_center_card)
	assert(game.deck_cursor == 4)
	assert(game.deck.size() - game.deck_cursor == 27)
	game.scores[0] = 5
	game.scores[1] = 2
	game._finish_game()
	await process_frame
	assert(game.result_panel.visible)
	assert("GANASTE LA PARTIDA" in game.result_title.text)
	assert(game.fx_root.get_child_count() > 0)
	print("OK: penalización de 5 segundos, botones invisibles y toque seguro.")
	game.queue_free()
	await process_frame
	quit(0)
