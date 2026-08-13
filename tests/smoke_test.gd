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
	assert(game.human_card != null)
	assert(game.center_card != null)
	var matching: int = game._common_symbol(game.player_symbols, game.center_symbols)
	assert(matching >= 0)
	game._on_human_symbol(matching)
	assert(game.scores[0] == 1)
	print("OK: escena, menú, partida, cartas 3D y toque correcto.")
	game.queue_free()
	await process_frame
	quit(0)
