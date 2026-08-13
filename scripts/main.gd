extends Node3D

const Card := preload("res://scripts/card_3d.gd")
const CPU_NAMES := ["CPU AZUL", "CPU ROSA", "CPU LIMA"]

var total_players := 2
var difficulty := 1
var scores: Array[int] = []
var deck: Array = []
var deck_cursor := 0
var prize_total := 0
var center_symbols: Array[int] = []
var player_symbols: Array[int] = []
var cpu_symbols: Array = []
var human_card: Card3D
var center_card: Card3D
var round_active := false
var game_active := false
var cpu_round_token := 0

var menu_layer: CanvasLayer
var hud_layer: CanvasLayer
var score_label: Label
var status_label: Label
var progress_label: Label
var players_option: OptionButton
var difficulty_option: OptionButton
var result_panel: PanelContainer
var result_title: Label
var audio_player: AudioStreamPlayer
var touch_layer: Control
var touch_buttons: Array[Button] = []


func _ready() -> void:
	seed(hash(Time.get_datetime_string_from_system()))
	_create_world()
	_create_menu()
	_create_hud()
	_create_audio()
	_show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if game_active:
			return_to_menu()
		else:
			get_tree().quit()


func _create_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#050b22")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b8d5ff")
	env.ambient_light_energy = 0.86
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	# Cámara vertical: cada carta ocupa casi exactamente media pantalla.
	var camera := Camera3D.new()
	camera.position = Vector3(0, 14.0, 0)
	camera.rotation_degrees = Vector3(-90, 0, 0)
	camera.fov = 49.0
	camera.current = true
	add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-52, -22, -18)
	key_light.light_color = Color("#e6f3ff")
	key_light.light_energy = 1.45
	key_light.shadow_enabled = false
	add_child(key_light)

	var top_light := OmniLight3D.new()
	top_light.position = Vector3(0, 5.5, -3.2)
	top_light.light_color = Color("#b46aff")
	top_light.light_energy = 2.8
	top_light.omni_range = 10.0
	add_child(top_light)

	var bottom_light := OmniLight3D.new()
	bottom_light.position = Vector3(0, 5.5, 3.2)
	bottom_light.light_color = Color("#25d8ff")
	bottom_light.light_energy = 2.8
	bottom_light.omni_range = 10.0
	add_child(bottom_light)

	var table := MeshInstance3D.new()
	var table_mesh := BoxMesh.new()
	table_mesh.size = Vector3(22, 0.48, 14)
	table.mesh = table_mesh
	table.position = Vector3(0, -0.44, 0)
	var table_mat := StandardMaterial3D.new()
	table_mat.albedo_color = Color("#101a42")
	table_mat.metallic = 0.48
	table_mat.roughness = 0.30
	table.material_override = table_mat
	add_child(table)


func _create_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 20
	add_child(menu_layer)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.021, 0.08, 0.92)
	menu_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 26
	center.offset_top = 20
	center.offset_right = -26
	center.offset_bottom = -20
	menu_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#121d4d"), Color("#49d9ff"), 26, 3))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 13)
	panel.add_child(box)

	var title := Label.new()
	title.text = "SÍMBOLOS RELÁMPAGO 3D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#7cecff"))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Arriba está la carta central. Abajo está tu carta."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 21)
	subtitle.add_theme_color_override("font_color", Color("#d7e0ff"))
	box.add_child(subtitle)

	box.add_child(_setting_label("PARTICIPANTES"))
	players_option = OptionButton.new()
	players_option.add_item("2: tú + 1 CPU", 2)
	players_option.add_item("3: tú + 2 CPU", 3)
	players_option.add_item("4: tú + 3 CPU", 4)
	_style_button(players_option, Color("#24417d"))
	players_option.custom_minimum_size.y = 54
	box.add_child(players_option)

	box.add_child(_setting_label("VELOCIDAD DE LAS CPU"))
	difficulty_option = OptionButton.new()
	difficulty_option.add_item("Tranquila", 0)
	difficulty_option.add_item("Normal", 1)
	difficulty_option.add_item("Relámpago", 2)
	difficulty_option.select(1)
	_style_button(difficulty_option, Color("#452d78"))
	difficulty_option.custom_minimum_size.y = 54
	box.add_child(difficulty_option)

	var play := Button.new()
	play.text = "JUGAR"
	play.custom_minimum_size.y = 68
	_style_button(play, Color("#16bce4"), 27)
	play.pressed.connect(start_game)
	box.add_child(play)

	var guide := Label.new()
	guide.text = "Toca en TU carta la figura que también aparece arriba. El más rápido gana esa carta central. Cuando se acaba el mazo, gana quien consiguió más cartas."
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size", 18)
	guide.add_theme_color_override("font_color", Color("#aebfe8"))
	box.add_child(guide)

	var version_label := Label.new()
	version_label.text = "VERSIÓN 1.1.3 — TOQUE SEGURO"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 17)
	version_label.add_theme_color_override("font_color", Color("#75ffad"))
	box.add_child(version_label)


func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	var top_tint := ColorRect.new()
	top_tint.anchor_right = 1.0
	top_tint.anchor_bottom = 0.5
	top_tint.color = Color(0.40, 0.16, 0.70, 0.09)
	top_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(top_tint)

	var bottom_tint := ColorRect.new()
	bottom_tint.anchor_top = 0.5
	bottom_tint.anchor_right = 1.0
	bottom_tint.anchor_bottom = 1.0
	bottom_tint.color = Color(0.04, 0.62, 0.85, 0.08)
	bottom_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(bottom_tint)

	var divider_glow := ColorRect.new()
	divider_glow.anchor_top = 0.5
	divider_glow.anchor_right = 1.0
	divider_glow.anchor_bottom = 0.5
	divider_glow.offset_top = -4
	divider_glow.offset_bottom = 4
	divider_glow.color = Color("#69e8ff")
	divider_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(divider_glow)

	var header := MarginContainer.new()
	header.anchor_right = 1.0
	header.offset_left = 20
	header.offset_top = 14
	header.offset_right = -20
	header.offset_bottom = 66
	hud_layer.add_child(header)

	var header_row := HBoxContainer.new()
	header.add_child(header_row)

	score_label = Label.new()
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	header_row.add_child(score_label)

	var exit := Button.new()
	exit.text = "MENÚ"
	exit.custom_minimum_size = Vector2(120, 48)
	_style_button(exit, Color("#27335d"), 17)
	exit.pressed.connect(return_to_menu)
	header_row.add_child(exit)

	var central_title := Label.new()
	central_title.anchor_right = 1.0
	central_title.offset_top = 70
	central_title.offset_bottom = 106
	central_title.text = "CARTA CENTRAL — TODOS MIRAN ARRIBA"
	central_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	central_title.add_theme_font_size_override("font_size", 21)
	central_title.add_theme_color_override("font_color", Color("#e7ceff"))
	central_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(central_title)

	status_label = Label.new()
	status_label.anchor_top = 0.5
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 0.5
	status_label.offset_top = -47
	status_label.offset_bottom = -10
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 23)
	status_label.add_theme_color_override("font_color", Color("#7cecff"))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(status_label)

	var player_title := Label.new()
	player_title.anchor_top = 0.5
	player_title.anchor_right = 1.0
	player_title.anchor_bottom = 0.5
	player_title.offset_top = 12
	player_title.offset_bottom = 48
	player_title.text = "TU CARTA — TOCA AQUÍ LA FIGURA REPETIDA"
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_title.add_theme_font_size_override("font_size", 21)
	player_title.add_theme_color_override("font_color", Color("#b8f6ff"))
	player_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(player_title)

	progress_label = Label.new()
	progress_label.anchor_top = 1.0
	progress_label.anchor_right = 1.0
	progress_label.anchor_bottom = 1.0
	progress_label.offset_top = -48
	progress_label.offset_bottom = -12
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 19)
	progress_label.add_theme_color_override("font_color", Color("#eff5ff"))
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(progress_label)

	# Capa táctil 2D: no usa raycast ni eventos físicos 3D en Android.
	touch_layer = Control.new()
	touch_layer.name = "BotonesFiguras"
	touch_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_layer.add_child(touch_layer)

	result_panel = PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.offset_left = -330
	result_panel.offset_top = -200
	result_panel.offset_right = 330
	result_panel.offset_bottom = 200
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color("#111a43"), Color("#7eeaff"), 28, 4))
	hud_layer.add_child(result_panel)

	var result_box := VBoxContainer.new()
	result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	result_box.add_theme_constant_override("separation", 18)
	result_panel.add_child(result_box)

	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_title.add_theme_font_size_override("font_size", 34)
	result_title.add_theme_color_override("font_color", Color("#7cecff"))
	result_box.add_child(result_title)

	var again := Button.new()
	again.text = "REVANCHA"
	again.custom_minimum_size.y = 66
	_style_button(again, Color("#17badf"), 23)
	again.pressed.connect(start_game)
	result_box.add_child(again)

	var back := Button.new()
	back.text = "VOLVER AL MENÚ"
	back.custom_minimum_size.y = 56
	_style_button(back, Color("#34416d"), 19)
	back.pressed.connect(return_to_menu)
	result_box.add_child(back)
	result_panel.hide()


func _create_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func start_game() -> void:
	_clear_cards()
	total_players = players_option.get_selected_id()
	difficulty = difficulty_option.get_selected_id()
	scores.clear()
	for _i in total_players:
		scores.append(0)

	deck = _generate_projective_deck()
	deck.shuffle()
	deck_cursor = 0

	# Cada participante conserva una carta privada durante toda la partida.
	player_symbols = _next_card()
	cpu_symbols.clear()
	for _i in range(total_players - 1):
		cpu_symbols.append(_next_card())
	prize_total = deck.size() - deck_cursor

	game_active = true
	round_active = false
	result_panel.hide()
	menu_layer.hide()
	hud_layer.show()
	_create_human_card()
	_update_score()
	_start_round()


func return_to_menu() -> void:
	game_active = false
	round_active = false
	cpu_round_token += 1
	_clear_cards()
	_show_menu()


func _show_menu() -> void:
	menu_layer.show()
	hud_layer.hide()


func _create_human_card() -> void:
	human_card = Card.new()
	human_card.setup(player_symbols, false, 2.82)
	human_card.position = Vector3(0, 0.12, 3.15)
	add_child(human_card)
	human_card.enter_animation(0.08)
	_rebuild_touch_buttons()


func _rebuild_touch_buttons() -> void:
	_clear_touch_buttons()
	if not is_instance_valid(touch_layer):
		return

	# La carta inferior está centrada al 75% de la pantalla. Estas posiciones
	# coinciden con las seis figuras distribuidas alrededor de la carta 3D.
	var touch_orbit := 166.0
	var touch_radius := 73.0
	for index in player_symbols.size():
		var angle := -PI * 0.5 + TAU * float(index) / float(player_symbols.size())
		var button := Button.new()
		button.name = "Tocar_%s" % Card.get_symbol_name(player_symbols[index])
		button.text = ""
		button.tooltip_text = Card.get_symbol_name(player_symbols[index])
		button.anchor_left = 0.5
		button.anchor_right = 0.5
		button.anchor_top = 0.75
		button.anchor_bottom = 0.75
		var offset := Vector2(cos(angle), sin(angle)) * touch_orbit
		button.offset_left = offset.x - touch_radius
		button.offset_right = offset.x + touch_radius
		button.offset_top = offset.y - touch_radius
		button.offset_bottom = offset.y + touch_radius
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", _touch_style(Color(0, 0, 0, 0)))
		button.add_theme_stylebox_override("hover", _touch_style(Color(0.18, 0.88, 1.0, 0.12)))
		button.add_theme_stylebox_override("pressed", _touch_style(Color(0.18, 0.88, 1.0, 0.30)))
		button.pressed.connect(_on_human_symbol.bind(player_symbols[index]))
		touch_layer.add_child(button)
		touch_buttons.append(button)


func _touch_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.35, 0.94, 1.0, color.a * 1.8)
	style.set_border_width_all(3 if color.a > 0.0 else 0)
	style.set_corner_radius_all(73)
	return style


func _set_touch_enabled(enabled: bool) -> void:
	for button in touch_buttons:
		if is_instance_valid(button):
			button.disabled = not enabled
			button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _clear_touch_buttons() -> void:
	for button in touch_buttons:
		if is_instance_valid(button):
			button.queue_free()
	touch_buttons.clear()


func _start_round() -> void:
	if not game_active:
		return
	if deck_cursor >= deck.size():
		_finish_game()
		return

	round_active = false
	cpu_round_token += 1
	_clear_center_card()

	center_symbols = _next_card()
	center_card = Card.new()
	center_card.setup(center_symbols, false, 2.82)
	center_card.position = Vector3(0, 0.10, -3.15)
	add_child(center_card)
	center_card.enter_animation()

	_update_score()
	status_label.text = "¡BUSCA LA FIGURA QUE ESTÁ EN LAS DOS CARTAS!"
	status_label.add_theme_color_override("font_color", Color("#7cecff"))
	round_active = true
	_set_touch_enabled(true)
	_schedule_cpus(cpu_round_token)


func _next_card() -> Array[int]:
	var value: Array[int] = []
	value.assign(deck[deck_cursor])
	deck_cursor += 1
	return value


func _on_human_symbol(symbol_id: int) -> void:
	if not game_active or not round_active:
		return
	if not is_instance_valid(human_card) or not is_instance_valid(center_card):
		return
	var matching := _common_symbol(player_symbols, center_symbols)
	if matching < 0:
		status_label.text = "ERROR DE CARTAS — PREPARANDO OTRA RONDA"
		round_active = false
		call_deferred("_start_round")
		return
	if symbol_id == matching:
		_score_round(0, matching)
	else:
		status_label.text = "ESA FIGURA NO ESTÁ ARRIBA — SIGUE BUSCANDO"
		status_label.add_theme_color_override("font_color", Color("#ff829f"))


func _schedule_cpus(token: int) -> void:
	for cpu_index in range(total_players - 1):
		var delay_range := _cpu_delay_range()
		var think_time := randf_range(delay_range.x, delay_range.y) + cpu_index * 0.08
		_cpu_attempt(cpu_index, think_time, token)


func _cpu_attempt(cpu_index: int, think_time: float, token: int) -> void:
	await get_tree().create_timer(think_time).timeout
	if not game_active or not round_active or token != cpu_round_token:
		return
	var matching := _common_symbol(cpu_symbols[cpu_index], center_symbols)
	_score_round(cpu_index + 1, matching)


func _score_round(winner: int, symbol_id: int) -> void:
	if not round_active:
		return
	if winner < 0 or winner >= scores.size() or symbol_id < 0:
		return
	round_active = false
	_set_touch_enabled(false)
	cpu_round_token += 1
	scores[winner] += 1
	_update_score()

	var figure_name: String = Card.get_symbol_name(symbol_id)
	if winner == 0:
		status_label.text = "¡GANASTE ESTA CARTA! ERA %s" % figure_name
		status_label.add_theme_color_override("font_color", Color("#75ffad"))
	else:
		status_label.text = "%s GANÓ LA CARTA CON %s" % [CPU_NAMES[winner - 1], figure_name]
		status_label.add_theme_color_override("font_color", Color("#ffd36a"))

	# Cambio sencillo: no ejecutar vibración, audio ni tweens 3D desde un toque.
	await get_tree().create_timer(0.42).timeout
	if not game_active:
		return
	if deck_cursor >= deck.size():
		_finish_game()
	else:
		_start_round()


func _finish_game() -> void:
	game_active = false
	round_active = false
	cpu_round_token += 1

	var highest := -1
	for score in scores:
		highest = maxi(highest, score)

	var winner_names: Array[String] = []
	for index in scores.size():
		if scores[index] == highest:
			winner_names.append("TÚ" if index == 0 else CPU_NAMES[index - 1])

	var summary_parts: Array[String] = []
	for index in scores.size():
		var player_name: String = "TÚ" if index == 0 else CPU_NAMES[index - 1]
		summary_parts.append("%s: %d" % [player_name, scores[index]])

	if winner_names.size() > 1:
		result_title.text = "¡EMPATE!\n%s\n\n%s" % [" Y ".join(winner_names), "  •  ".join(summary_parts)]
	elif winner_names[0] == "TÚ":
		result_title.text = "¡GANASTE LA PARTIDA!\nConseguiste %d cartas\n\n%s" % [highest, "  •  ".join(summary_parts)]
	else:
		result_title.text = "GANÓ %s\nCon %d cartas\n\n%s" % [winner_names[0], highest, "  •  ".join(summary_parts)]
	result_panel.show()


func _clear_center_card() -> void:
	if is_instance_valid(center_card):
		center_card.queue_free()
	center_card = null


func _clear_cards() -> void:
	_clear_touch_buttons()
	if is_instance_valid(human_card):
		human_card.queue_free()
	human_card = null
	_clear_center_card()


func _update_score() -> void:
	if scores.is_empty():
		return
	var parts := ["TÚ: %d CARTAS" % scores[0]]
	for i in range(1, scores.size()):
		parts.append("%s: %d" % [CPU_NAMES[i - 1], scores[i]])
	score_label.text = "   •   ".join(parts)

	var played := clampi(deck_cursor - total_players, 0, prize_total)
	var remaining := maxi(0, deck.size() - deck_cursor)
	progress_label.text = "CARTA CENTRAL %d DE %d   •   QUEDAN %d" % [played, prize_total, remaining]


func _cpu_delay_range() -> Vector2:
	match difficulty:
		0:
			return Vector2(3.2, 5.2)
		2:
			return Vector2(0.90, 1.65)
		_:
			return Vector2(1.75, 3.15)


func _common_symbol(first: Array, second: Array) -> int:
	for symbol in first:
		if second.has(symbol):
			return int(symbol)
	return -1


func _generate_projective_deck() -> Array:
	# 31 cartas de 6 figuras. Cualquier par comparte exactamente una figura.
	var cards: Array = []
	var q := 5
	for slope in q:
		for intercept in q:
			var card: Array[int] = []
			for x in q:
				var y := (slope * x + intercept) % q
				card.append(x * q + y)
			card.append(q * q + slope)
			cards.append(card)
	for x in q:
		var vertical: Array[int] = []
		for y in q:
			vertical.append(x * q + y)
		vertical.append(q * q + q)
		cards.append(vertical)
	var infinity: Array[int] = []
	for point in range(q * q, q * q + q + 1):
		infinity.append(point)
	cards.append(infinity)
	return cards


func _setting_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("#91a8df"))
	return label


func _style_button(button: BaseButton, color: Color, font_size: int = 20) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel_style(color, color.lightened(0.18), 15, 2))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), Color("#8cecff"), 15, 3))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.18), Color.WHITE, 15, 3))


func _panel_style(color: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	return style
