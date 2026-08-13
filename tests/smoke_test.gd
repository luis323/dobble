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
	var android_touch := InputEventScreenTouch.new()
	android_touch.pressed = true
	android_touch.position = Vector2(360, 960)
	game.human_card._on_symbol_input(null, android_touch, Vector3.ZERO, Vector3.UP, 0, matching)
	# Un segundo evento para el mismo toque no debe puntuar ni procesarse otra vez.
	game.human_card._on_symbol_input(null, android_touch, Vector3.ZERO, Vector3.UP, 0, matching)
	await process_frame
	assert(game.scores[0] == 1)
	await create_timer(0.8).timeout
	assert(game.player_symbols == fixed_personal_card)
	assert(game.center_symbols != first_center_card)
	assert(game.deck_cursor == 4)
	assert(game.deck.size() - game.deck_cursor == 27)
	print("OK: toque Android doble seguro, carta personal fija y puntuación.")
	game.queue_free()
	await process_frame
	quit(0)
