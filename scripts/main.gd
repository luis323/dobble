extends Node3D

const Card := preload("res://scripts/card_3d.gd")
const TARGET_SCORE := 8
const CPU_NAMES := ["CPU Azul", "CPU Rosa", "CPU Lima"]

var total_players := 2
var difficulty := 1
var scores: Array[int] = []
var deck: Array = []
var deck_cursor := 0
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
	env.background_color = Color("#071229")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#98bfff")
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 11.8, 12.2)
	camera.fov = 48.0
	camera.look_at_from_position(camera.position, Vector3(0, 0, 0.5), Vector3.UP)
	camera.current = true
	add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-54, -24, 0)
	key_light.light_color = Color("#d8eeff")
	key_light.light_energy = 1.25
	key_light.shadow_enabled = false
	add_child(key_light)

	var glow_light := OmniLight3D.new()
	glow_light.position = Vector3(0, 5, 1)
	glow_light.light_color = Color("#9d64ff")
	glow_light.light_energy = 3.2
	glow_light.omni_range = 14.0
	add_child(glow_light)

	var table := MeshInstance3D.new()
	var table_mesh := BoxMesh.new()
	table_mesh.size = Vector3(18, 0.45, 14)
	table.mesh = table_mesh
	table.position = Vector3(0, -0.42, 0)
	var table_mat := StandardMaterial3D.new()
	table_mat.albedo_color = Color("#111c45")
	table_mat.metallic = 0.55
	table_mat.roughness = 0.28
	table.material_override = table_mat
	add_child(table)

	for i in 18:
		var orb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.055 + randf() * 0.07
		sphere.height = sphere.radius * 2.0
		orb.mesh = sphere
		orb.position = Vector3(randf_range(-8.0, 8.0), randf_range(0.4, 4.5), randf_range(-5.0, 5.0))
		var orb_mat := StandardMaterial3D.new()
		orb_mat.albedo_color = [Color("#19d5ff"), Color("#d354ff"), Color("#7dff91")][i % 3]
		orb_mat.emission_enabled = true
		orb_mat.emission = orb_mat.albedo_color
		orb_mat.emission_energy_multiplier = 2.0
		orb.material_override = orb_mat
		add_child(orb)
		var tween := create_tween().set_loops()
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(orb, "position:y", orb.position.y + randf_range(0.25, 0.7), randf_range(1.8, 3.8))
		tween.tween_property(orb, "position:y", orb.position.y, randf_range(1.8, 3.8))


func _create_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 20
	add_child(menu_layer)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.09, 0.86)
	menu_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 26
	center.offset_top = 26
	center.offset_right = -26
	center.offset_bottom = -26
	menu_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#121d4d"), Color("#49d9ff"), 26, 3))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title := Label.new()
	title.text = "SÍMBOLOS RELÁMPAGO 3D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 43)
	title.add_theme_color_override("font_color", Color("#7cecff"))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Encuentra el único símbolo repetido antes que las CPU"
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
	players_option.custom_minimum_size.y = 58
	box.add_child(players_option)

	box.add_child(_setting_label("VELOCIDAD DE LAS CPU"))
	difficulty_option = OptionButton.new()
	difficulty_option.add_item("Tranquila", 0)
	difficulty_option.add_item("Normal", 1)
	difficulty_option.add_item("Relámpago", 2)
	difficulty_option.select(1)
	_style_button(difficulty_option, Color("#452d78"))
	difficulty_option.custom_minimum_size.y = 58
	box.add_child(difficulty_option)

	var play := Button.new()
	play.text = "JUGAR"
	play.custom_minimum_size.y = 76
	_style_button(play, Color("#16bce4"), 27)
	play.pressed.connect(start_game)
	box.add_child(play)

	var guide := Label.new()
	guide.text = "Toca en TU carta el símbolo que también aparece en la carta del centro. Primero en llegar a %d puntos gana." % TARGET_SCORE
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size", 18)
	guide.add_theme_color_override("font_color", Color("#aebfe8"))
	box.add_child(guide)


func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 28)
	safe.add_theme_constant_override("margin_right", 28)
	safe.add_theme_constant_override("margin_top", 22)
	safe.add_theme_constant_override("margin_bottom", 20)
	hud_layer.add_child(safe)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	safe.add_child(layout)

	var top := HBoxContainer.new()
	layout.add_child(top)

	score_label = Label.new()
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	top.add_child(score_label)

	var exit := Button.new()
	exit.text = "MENÚ"
	exit.custom_minimum_size = Vector2(128, 50)
	_style_button(exit, Color("#27335d"), 18)
	exit.pressed.connect(return_to_menu)
	top.add_child(exit)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.add_theme_color_override("font_color", Color("#7cecff"))
	layout.add_child(status_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)

	progress_label = Label.new()
	progress_label.text = "TU CARTA — TOCA EL SÍMBOLO REPETIDO"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 20)
	progress_label.add_theme_color_override("font_color", Color("#eff5ff"))
	layout.add_child(progress_label)

	result_panel = PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.offset_left = -320
	result_panel.offset_top = -185
	result_panel.offset_right = 320
	result_panel.offset_bottom = 185
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color("#111a43"), Color("#7eeaff"), 28, 4))
	hud_layer.add_child(result_panel)

	var result_box := VBoxContainer.new()
	result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	result_box.add_theme_constant_override("separation", 18)
	result_panel.add_child(result_box)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_title.add_theme_font_size_override("font_size", 37)
	result_title.add_theme_color_override("font_color", Color("#7cecff"))
	result_box.add_child(result_title)
	var again := Button.new()
	again.text = "REVANCHA"
	again.custom_minimum_size.y = 68
	_style_button(again, Color("#17badf"), 23)
	again.pressed.connect(start_game)
	result_box.add_child(again)
	var back := Button.new()
	back.text = "VOLVER AL MENÚ"
	back.custom_minimum_size.y = 58
	_style_button(back, Color("#34416d"), 19)
	back.pressed.connect(return_to_menu)
	result_box.add_child(back)
	result_panel.hide()


func _create_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func start_game() -> void:
	total_players = players_option.get_selected_id()
	difficulty = difficulty_option.get_selected_id()
	scores.clear()
	for _i in total_players:
		scores.append(0)
	deck = _generate_projective_deck()
	deck.shuffle()
	deck_cursor = 0
	game_active = true
	result_panel.hide()
	menu_layer.hide()
	hud_layer.show()
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


func _start_round() -> void:
	if not game_active:
		return
	round_active = false
	cpu_round_token += 1
	_clear_cards()

	if deck_cursor + total_players + 1 >= deck.size():
		deck.shuffle()
		deck_cursor = 0

	center_symbols = _next_card()
	player_symbols = _next_card()
	cpu_symbols.clear()
	for _i in range(total_players - 1):
		cpu_symbols.append(_next_card())

	center_card = Card.new()
	center_card.setup(center_symbols, false, 2.35)
	center_card.position = Vector3(0, 0.05, -2.05)
	center_card.scale = Vector3.ONE * 0.93
	add_child(center_card)
	center_card.enter_animation()

	human_card = Card.new()
	human_card.setup(player_symbols, true, 2.55)
	human_card.position = Vector3(0, 0.12, 3.35)
	human_card.symbol_pressed.connect(_on_human_symbol)
	add_child(human_card)
	human_card.enter_animation(0.08)

	_create_cpu_markers()
	_update_score()
	status_label.text = "Busca... ¡hay exactamente uno!"
	round_active = true
	_schedule_cpus(cpu_round_token)


func _next_card() -> Array[int]:
	var value: Array[int] = []
	value.assign(deck[deck_cursor])
	deck_cursor += 1
	return value


func _on_human_symbol(symbol_id: int) -> void:
	if not round_active:
		return
	var matching := _common_symbol(player_symbols, center_symbols)
	if symbol_id == matching:
		human_card.celebrate(symbol_id)
		center_card.celebrate(symbol_id)
		_score_round(0, matching)
	else:
		human_card.wrong(symbol_id)
		status_label.text = "Ese no está en el centro — sigue buscando"
		status_label.add_theme_color_override("font_color", Color("#ff829f"))
		_play_tone(170.0, 0.12, 0.18)
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(55)


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
	round_active = false
	cpu_round_token += 1
	scores[winner] += 1
	_update_score()
	if winner == 0:
		status_label.text = "¡CORRECTO! Símbolo %d" % (symbol_id + 1)
		status_label.add_theme_color_override("font_color", Color("#75ffad"))
		_play_tone(760.0, 0.16, 0.22)
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(28)
	else:
		status_label.text = "%s encontró el símbolo %d" % [CPU_NAMES[winner - 1], symbol_id + 1]
		status_label.add_theme_color_override("font_color", Color("#ffd36a"))
		_play_tone(310.0, 0.14, 0.16)

	if scores[winner] >= TARGET_SCORE:
		await get_tree().create_timer(0.7).timeout
		_finish_game(winner)
	else:
		await get_tree().create_timer(0.72).timeout
		_start_round()


func _finish_game(winner: int) -> void:
	game_active = false
	round_active = false
	if winner == 0:
		result_title.text = "¡GANASTE!\nFuiste el más rápido"
		_play_tone(980.0, 0.30, 0.24)
	else:
		result_title.text = "Ganó %s\n¡Revancha!" % CPU_NAMES[winner - 1]
	result_panel.show()


func _clear_cards() -> void:
	if is_instance_valid(human_card):
		human_card.queue_free()
	if is_instance_valid(center_card):
		center_card.queue_free()
	for child in get_tree().get_nodes_in_group("cpu_marker"):
		child.queue_free()


func _create_cpu_markers() -> void:
	var positions := [Vector3(-5.2, 0.15, -0.8), Vector3(5.2, 0.15, -0.8), Vector3(0, 0.15, -5.0)]
	for index in range(total_players - 1):
		var marker := MeshInstance3D.new()
		marker.add_to_group("cpu_marker")
		var mesh := CylinderMesh.new()
		mesh.top_radius = 1.05
		mesh.bottom_radius = 1.05
		mesh.height = 0.16
		mesh.radial_segments = 36
		marker.mesh = mesh
		marker.position = positions[index]
		var material := StandardMaterial3D.new()
		material.albedo_color = [Color("#1e91ff"), Color("#ff4b98"), Color("#83e64f")][index]
		material.metallic = 0.25
		material.roughness = 0.42
		marker.material_override = material
		add_child(marker)
		var label := Label3D.new()
		label.text = CPU_NAMES[index]
		label.position.y = 0.55
		label.font_size = 42
		label.outline_size = 9
		label.pixel_size = 0.009
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.add_child(label)


func _update_score() -> void:
	var parts := ["TÚ %d/%d" % [scores[0], TARGET_SCORE]]
	for i in range(1, scores.size()):
		parts.append("%s %d/%d" % [CPU_NAMES[i - 1], scores[i], TARGET_SCORE])
	score_label.text = "   •   ".join(parts)


func _cpu_delay_range() -> Vector2:
	match difficulty:
		0:
			return Vector2(3.0, 5.0)
		2:
			return Vector2(0.85, 1.65)
		_:
			return Vector2(1.65, 3.0)


func _common_symbol(first: Array, second: Array) -> int:
	for symbol in first:
		if second.has(symbol):
			return int(symbol)
	return -1


func _generate_projective_deck() -> Array:
	# Plano proyectivo de orden 5: 31 cartas, 6 símbolos por carta.
	# Esta construcción garantiza exactamente un símbolo común en cualquier par.
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


func _play_tone(frequency: float, duration: float, volume: float) -> void:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var fade := 1.0 - float(i) / float(sample_count)
		var value := int(sin(TAU * frequency * float(i) / float(sample_rate)) * 32767.0 * volume * fade)
		data.encode_s16(i * 2, value)
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = sample_rate
	wave.stereo = false
	wave.data = data
	audio_player.stream = wave
	audio_player.play()


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
