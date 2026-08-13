extends Node3D

const Card := preload("res://scripts/card_3d.gd")
const CPU_NAMES := ["CPU AZUL", "CPU ROSA", "CPU LIMA"]
const WRONG_PENALTY_SECONDS := 5

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
var penalty_token := 0
var human_locked := false

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
var round_win_sound: AudioStreamWAV
var cpu_win_sound: AudioStreamWAV
var final_win_sound: AudioStreamWAV
var final_lose_sound: AudioStreamWAV
var sound_enabled := true
var sound_toggle: Button
var touch_layer: Control
var touch_buttons: Array[Button] = []
var fx_layer: CanvasLayer
var fx_root: Control
var menu_glow_left: TextureRect
var menu_glow_right: TextureRect
var animation_time := 0.0


func _ready() -> void:
	seed(hash(Time.get_datetime_string_from_system()))
	_create_world()
	_create_menu()
	_create_hud()
	_create_audio()
	_show_menu()


func _process(delta: float) -> void:
	animation_time += delta
	if is_instance_valid(menu_glow_left):
		menu_glow_left.modulate.a = 0.72 + sin(animation_time * 1.35) * 0.16
	if is_instance_valid(menu_glow_right):
		menu_glow_right.modulate.a = 0.68 + cos(animation_time * 1.10) * 0.18
	if game_active:
		if is_instance_valid(center_card):
			center_card.rotation.y = sin(animation_time * 0.85) * 0.035
		if is_instance_valid(human_card):
			human_card.rotation.y = -sin(animation_time * 0.92) * 0.028


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
	shade.color = Color("#05091e")
	menu_layer.add_child(shade)

	menu_glow_left = _radial_glow(Color(0.12, 0.76, 1.0, 0.30))
	menu_glow_left.position = Vector2(-170, 110)
	menu_glow_left.size = Vector2(440, 440)
	menu_layer.add_child(menu_glow_left)

	menu_glow_right = _radial_glow(Color(0.68, 0.20, 1.0, 0.26))
	menu_glow_right.anchor_left = 1.0
	menu_glow_right.anchor_right = 1.0
	menu_glow_right.position = Vector2(-250, 770)
	menu_glow_right.size = Vector2(390, 390)
	menu_layer.add_child(menu_glow_right)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 26
	center.offset_top = 20
	center.offset_right = -26
	center.offset_bottom = -20
	menu_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.085, 0.22, 0.97), Color("#42d9ff"), 32, 2))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var badge := Label.new()
	badge.text = "  ⚡  DESAFÍO DE REFLEJOS  ⚡  "
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 17)
	badge.add_theme_color_override("font_color", Color("#061126"))
	badge.add_theme_stylebox_override("normal", _panel_style(Color("#62e7ff"), Color("#b8f6ff"), 18, 1, 8))
	box.add_child(badge)

	var title := Label.new()
	title.text = "SÍMBOLOS RELÁMPAGO 3D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#f1fbff"))
	title.add_theme_color_override("font_shadow_color", Color(0.18, 0.88, 1.0, 0.65))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Encuentra el símbolo repetido antes que las CPU"
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

	sound_toggle = Button.new()
	sound_toggle.text = "🔊  SONIDO: ACTIVADO"
	sound_toggle.custom_minimum_size.y = 50
	_style_button(sound_toggle, Color("#1b3861"), 18)
	sound_toggle.pressed.connect(_toggle_sound)
	box.add_child(sound_toggle)

	var play := Button.new()
	play.text = "⚡  COMENZAR PARTIDA"
	play.custom_minimum_size.y = 68
	_style_button(play, Color("#16bce4"), 27)
	play.pressed.connect(start_game)
	box.add_child(play)

	var guide := Label.new()
	guide.text = "MIRA ARRIBA  →  ENCUENTRA LA PAREJA  →  TOCA ABAJO\nCada carta ganada suma un punto."
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size", 18)
	guide.add_theme_color_override("font_color", Color("#aebfe8"))
	box.add_child(guide)

	var version_label := Label.new()
	version_label.text = "VERSIÓN 1.2.2  •  X ROJA Y SONIDO DE DERROTA"
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

	fx_layer = CanvasLayer.new()
	fx_layer.layer = 15
	add_child(fx_layer)
	fx_root = Control.new()
	fx_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(fx_root)


func _create_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	round_win_sound = _make_chime([[659.25, 0.10], [783.99, 0.10], [987.77, 0.20]], 0.30)
	cpu_win_sound = _make_chime([[392.00, 0.11], [329.63, 0.18]], 0.18)
	final_win_sound = _make_chime([[523.25, 0.11], [659.25, 0.11], [783.99, 0.11], [1046.50, 0.32]], 0.32)
	final_lose_sound = _make_chime([[392.00, 0.16], [311.13, 0.16], [246.94, 0.34]], 0.24)


func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	sound_toggle.text = "🔊  SONIDO: ACTIVADO" if sound_enabled else "🔇  SONIDO: DESACTIVADO"


func _make_chime(notes: Array, volume: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := 0
	for note in notes:
		sample_count += int(float(note[1]) * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var sample_cursor := 0
	for note in notes:
		var frequency := float(note[0])
		var duration := float(note[1])
		var note_samples := int(duration * mix_rate)
		for i in note_samples:
			var local_time := float(i) / float(mix_rate)
			var progress := float(i) / float(maxi(1, note_samples - 1))
			var envelope := sin(PI * progress) * exp(-1.7 * progress)
			var wave := sin(TAU * frequency * local_time) + 0.22 * sin(TAU * frequency * 2.0 * local_time)
			var value := clampi(int(wave * envelope * volume * 32767.0), -32768, 32767)
			bytes.encode_s16(sample_cursor * 2, value)
			sample_cursor += 1
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = bytes
	return stream


func _play_stream(stream: AudioStreamWAV) -> void:
	if not sound_enabled or not is_instance_valid(audio_player) or stream == null:
		return
	audio_player.stream = stream
	audio_player.play()


func start_game() -> void:
	_clear_cards()
	penalty_token += 1
	human_locked = false
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
	penalty_token += 1
	human_locked = false
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
		button.flat = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		# Todos los estados son totalmente invisibles. Esto evita los rectángulos
		# oscuros predeterminados de Android al desactivar un botón tras pulsarlo.
		for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			button.add_theme_stylebox_override(state, _touch_style(Color.TRANSPARENT))
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
	penalty_token += 1
	human_locked = false
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
	if not game_active or not round_active or human_locked:
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
		human_locked = true
		penalty_token += 1
		var current_penalty := penalty_token
		_set_touch_enabled(false)
		status_label.text = "¡INCORRECTO! TU CARTA SE BLOQUEA %d SEGUNDOS" % WRONG_PENALTY_SECONDS
		status_label.add_theme_color_override("font_color", Color("#ff829f"))
		call_deferred("_wrong_penalty_countdown", current_penalty)


func _wrong_penalty_countdown(token: int) -> void:
	for seconds_left in range(WRONG_PENALTY_SECONDS, 0, -1):
		if not game_active or not round_active or token != penalty_token:
			return
		status_label.text = "⛔ INCORRECTO — BLOQUEADO %d..." % seconds_left
		await get_tree().create_timer(1.0).timeout
	if not game_active or not round_active or token != penalty_token:
		return
	human_locked = false
	_set_touch_enabled(true)
	status_label.text = "¡YA PUEDES JUGAR! BUSCA LA FIGURA REPETIDA"
	status_label.add_theme_color_override("font_color", Color("#7cecff"))


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
	human_locked = false
	_set_touch_enabled(false)
	cpu_round_token += 1
	penalty_token += 1
	scores[winner] += 1
	_update_score()

	var figure_name: String = Card.get_symbol_name(symbol_id)
	if winner == 0:
		status_label.text = "¡GANASTE ESTA CARTA! ERA %s" % figure_name
		status_label.add_theme_color_override("font_color", Color("#75ffad"))
		call_deferred("_play_stream", round_win_sound)
		call_deferred("_round_celebration", figure_name)
	else:
		status_label.text = "%s GANÓ LA CARTA CON %s" % [CPU_NAMES[winner - 1], figure_name]
		status_label.add_theme_color_override("font_color", Color("#ffd36a"))
		call_deferred("_play_stream", cpu_win_sound)
		call_deferred("_loss_feedback", false)

	# El sonido y la celebración son diferidos y 2D: el toque nunca anima física 3D.
	await get_tree().create_timer(0.72).timeout
	if not game_active:
		return
	if deck_cursor >= deck.size():
		_finish_game()
	else:
		_start_round()


func _finish_game() -> void:
	game_active = false
	round_active = false
	human_locked = false
	cpu_round_token += 1
	penalty_token += 1

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
		call_deferred("_play_stream", final_win_sound)
		call_deferred("_super_celebration")
	else:
		result_title.text = "GANÓ %s\nCon %d cartas\n\n%s" % [winner_names[0], highest, "  •  ".join(summary_parts)]
		call_deferred("_play_stream", final_lose_sound)
		call_deferred("_loss_feedback", true)
	result_panel.show()


func _loss_feedback(final_loss: bool = false) -> void:
	if not is_instance_valid(fx_root):
		return
	var red_x := Label.new()
	red_x.name = "XDerrotaFinal" if final_loss else "XDerrotaRonda"
	red_x.text = "✕"
	red_x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	red_x.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	red_x.anchor_left = 0.18
	red_x.anchor_right = 0.82
	if final_loss:
		red_x.anchor_top = 0.20
		red_x.anchor_bottom = 0.80
		red_x.add_theme_font_size_override("font_size", 270)
	else:
		# La X de la ronda queda sobre la carta inferior del jugador.
		red_x.anchor_top = 0.55
		red_x.anchor_bottom = 0.95
		red_x.add_theme_font_size_override("font_size", 210)
	red_x.add_theme_color_override("font_color", Color("#ff234f"))
	red_x.add_theme_color_override("font_shadow_color", Color(0.12, 0.0, 0.02, 0.88))
	red_x.add_theme_constant_override("shadow_offset_x", 8)
	red_x.add_theme_constant_override("shadow_offset_y", 10)
	red_x.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_x.modulate.a = 0.0
	red_x.scale = Vector2(2.2, 2.2)
	red_x.pivot_offset = Vector2(230, 240 if final_loss else 170)
	fx_root.add_child(red_x)

	var x_tween := create_tween()
	x_tween.set_parallel(true)
	x_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	x_tween.tween_property(red_x, "scale", Vector2.ONE, 0.23)
	x_tween.tween_property(red_x, "modulate:a", 1.0, 0.12)
	x_tween.set_parallel(false)
	x_tween.tween_interval(0.85 if final_loss else 0.28)
	x_tween.set_parallel(true)
	x_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	x_tween.tween_property(red_x, "scale", Vector2(0.72, 0.72), 0.24)
	x_tween.tween_property(red_x, "modulate:a", 0.0, 0.24)
	x_tween.set_parallel(false)
	x_tween.tween_callback(red_x.queue_free)


func _round_celebration(figure_name: String) -> void:
	if not is_instance_valid(fx_root) or not game_active:
		return
	var banner := Label.new()
	banner.text = "⚡  +1 CARTA  •  %s  ⚡" % figure_name
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.anchor_left = 0.08
	banner.anchor_right = 0.92
	banner.anchor_top = 0.43
	banner.anchor_bottom = 0.57
	banner.add_theme_font_size_override("font_size", 31)
	banner.add_theme_color_override("font_color", Color("#071229"))
	banner.add_theme_stylebox_override("normal", _panel_style(Color("#75ffad"), Color.WHITE, 24, 3, 12))
	banner.scale = Vector2(0.2, 0.2)
	banner.pivot_offset = Vector2(302, 85)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_root.add_child(banner)
	var banner_tween := create_tween()
	banner_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.24)
	banner_tween.tween_interval(0.25)
	banner_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 0.20)
	banner_tween.tween_callback(banner.queue_free)
	_spawn_confetti(18, 0.50, 0.92)


func _super_celebration() -> void:
	if not is_instance_valid(fx_root):
		return
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.25, 0.95, 1.0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_root.add_child(flash)
	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "color:a", 0.34, 0.16)
	flash_tween.tween_property(flash, "color:a", 0.0, 0.55)
	flash_tween.tween_callback(flash.queue_free)

	var crown := Label.new()
	crown.text = "★  CAMPEÓN RELÁMPAGO  ★"
	crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crown.anchor_left = 0.05
	crown.anchor_right = 0.95
	crown.anchor_top = 0.15
	crown.anchor_bottom = 0.28
	crown.add_theme_font_size_override("font_size", 35)
	crown.add_theme_color_override("font_color", Color("#fff07a"))
	crown.add_theme_color_override("font_shadow_color", Color("#8b4dff"))
	crown.add_theme_constant_override("shadow_offset_x", 4)
	crown.add_theme_constant_override("shadow_offset_y", 4)
	crown.scale = Vector2(0.1, 0.1)
	crown.pivot_offset = Vector2(324, 80)
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_root.add_child(crown)
	var crown_tween := create_tween()
	crown_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	crown_tween.tween_property(crown, "scale", Vector2.ONE, 0.70)
	crown_tween.tween_interval(1.1)
	crown_tween.tween_property(crown, "modulate:a", 0.0, 0.35)
	crown_tween.tween_callback(crown.queue_free)
	_spawn_confetti(46, 0.05, 0.95)


func _spawn_confetti(amount: int, top_ratio: float, bottom_ratio: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var colors := [Color("#62e7ff"), Color("#ff5ebc"), Color("#fff168"), Color("#75ffad"), Color("#9c72ff")]
	for i in amount:
		var piece := ColorRect.new()
		piece.color = colors[i % colors.size()]
		piece.size = Vector2(randf_range(8.0, 18.0), randf_range(14.0, 30.0))
		piece.position = Vector2(randf_range(8.0, viewport_size.x - 24.0), randf_range(viewport_size.y * top_ratio, viewport_size.y * bottom_ratio))
		piece.rotation = randf_range(-PI, PI)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_root.add_child(piece)
		var destination := piece.position + Vector2(randf_range(-95.0, 95.0), randf_range(130.0, 330.0))
		var piece_tween := create_tween().set_parallel(true)
		piece_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		piece_tween.tween_property(piece, "position", destination, randf_range(0.65, 1.25))
		piece_tween.tween_property(piece, "rotation", piece.rotation + randf_range(3.0, 8.0), randf_range(0.65, 1.25))
		piece_tween.tween_property(piece, "modulate:a", 0.0, randf_range(0.65, 1.25))
		piece_tween.chain().tween_callback(piece.queue_free)


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


func _radial_glow(color: Color) -> TextureRect:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([color, Color(color.r, color.g, color.b, color.a * 0.28), Color(color.r, color.g, color.b, 0.0)])
	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	var glow := TextureRect.new()
	glow.texture = texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return glow


func _style_button(button: BaseButton, color: Color, font_size: int = 20) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel_style(color, color.lightened(0.18), 15, 2))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), Color("#8cecff"), 15, 3))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.18), Color.WHITE, 15, 3))


func _panel_style(color: Color, border: Color, radius: int, width: int, margin: int = 22) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style
