class_name Card3D
extends Node3D

signal symbol_pressed(symbol_id: int)

const SYMBOL_NAMES := [
	"SOL", "LUNA", "ESTRELLA", "CORAZÓN", "RAYO", "FLOR",
	"NUBE", "PARAGUAS", "AVIÓN", "TAZA", "TRÉBOL", "DIAMANTE",
	"CRUZ", "FLECHA", "ESPIRAL", "OJO", "TRIÁNGULO", "CUADRADO",
	"CÍRCULO", "CORONA", "NOTA", "PAZ", "YIN YANG", "NIEVE",
	"COMETA", "ANCLA", "DOBLE NOTA", "RELOJ", "CASA", "BANDERA",
	"SONRISA"
]

const SYMBOL_GLYPHS := [
	"☀", "☾", "★", "♥", "ϟ", "✿",
	"☁", "☂", "✈", "☕", "♣", "◆",
	"✚", "➜", "◎", "◉", "▲", "■",
	"●", "♛", "♪", "☮", "☯", "❄",
	"✦", "⚓", "♫", "◷", "⌂", "⚑",
	"☻"
]

const SYMBOL_COLORS := [
	Color("#ff3f76"), Color("#16c8ff"), Color("#ffd12f"), Color("#77ef67"),
	Color("#a96cff"), Color("#ff7a32"), Color("#00d8b4"), Color("#ff62d1"),
	Color("#4f8cff"), Color("#d99743"), Color("#71c837"), Color("#e24fff")
]

var interactive := false
var card_radius := 2.8
var symbols: Array[int] = []
var _base: MeshInstance3D
var _symbol_nodes: Array[Node3D] = []
var _touch_locked := false


static func get_symbol_name(symbol_id: int) -> String:
	return SYMBOL_NAMES[symbol_id % SYMBOL_NAMES.size()]


func setup(new_symbols: Array, can_touch: bool, radius: float = 2.8) -> void:
	interactive = can_touch
	card_radius = radius
	symbols.assign(new_symbols)
	_build_card()


func _build_card() -> void:
	for child in get_children():
		child.queue_free()
	_symbol_nodes.clear()

	_base = MeshInstance3D.new()
	_base.name = "Carta"
	var disc := CylinderMesh.new()
	disc.top_radius = card_radius
	disc.bottom_radius = card_radius
	disc.height = 0.20
	disc.radial_segments = 72
	_base.mesh = disc
	_base.material_override = _material(Color("#fbfcff"), 0.18, 0.58)
	add_child(_base)

	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = card_radius - 0.13
	rim_mesh.outer_radius = card_radius + 0.07
	rim_mesh.rings = 72
	rim_mesh.ring_segments = 14
	rim.mesh = rim_mesh
	rim.position.y = 0.13
	var rim_color := Color("#28e0ff") if interactive else Color("#b86bff")
	rim.material_override = _material(rim_color, 0.22, 0.42, rim_color * 0.42)
	add_child(rim)

	var count := symbols.size()
	var orbit := card_radius * 0.59
	for index in count:
		var angle := -PI * 0.5 + TAU * float(index) / float(count)
		var pos := Vector3(cos(angle) * orbit, 0.24, sin(angle) * orbit)
		_create_symbol(symbols[index], pos, index)


func _create_symbol(symbol_id: int, pos: Vector3, index: int) -> void:
	var area := Area3D.new()
	area.name = "Figura_%s" % get_symbol_name(symbol_id)
	area.position = pos
	area.input_ray_pickable = interactive
	area.set_meta("symbol_id", symbol_id)
	add_child(area)
	_symbol_nodes.append(area)

	var collision := CollisionShape3D.new()
	var hitbox := BoxShape3D.new()
	hitbox.size = Vector3(1.58, 0.72, 1.48)
	collision.shape = hitbox
	area.add_child(collision)

	var color: Color = SYMBOL_COLORS[symbol_id % SYMBOL_COLORS.size()]
	var pedestal := MeshInstance3D.new()
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 0.61
	pedestal_mesh.bottom_radius = 0.67
	pedestal_mesh.height = 0.20
	pedestal_mesh.radial_segments = 28
	pedestal.mesh = pedestal_mesh
	pedestal.material_override = _material(color.darkened(0.08), 0.20, 0.32, color * 0.34)
	area.add_child(pedestal)

	var topper := MeshInstance3D.new()
	topper.position = Vector3(0, 0.20, 0)
	topper.scale = Vector3.ONE * (0.23 + float(symbol_id % 3) * 0.027)
	match symbol_id % 4:
		0:
			topper.mesh = BoxMesh.new()
			topper.rotation_degrees.y = 45.0
		1:
			topper.mesh = SphereMesh.new()
		2:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.28
			cone.bottom_radius = 0.92
			cone.height = 1.0
			topper.mesh = cone
		_:
			var torus := TorusMesh.new()
			torus.inner_radius = 0.48
			torus.outer_radius = 1.0
			topper.mesh = torus
	topper.material_override = _material(Color.WHITE, 0.12, 0.46)
	area.add_child(topper)

	# Cada figura combina glifo, nombre, color y volumen 3D: no depende de números.
	var glyph := Label3D.new()
	glyph.text = SYMBOL_GLYPHS[symbol_id % SYMBOL_GLYPHS.size()]
	glyph.position = Vector3(0, 0.58, -0.05)
	glyph.font_size = 112
	glyph.outline_size = 18
	glyph.modulate = color.lightened(0.16)
	glyph.outline_modulate = Color("#121731")
	glyph.pixel_size = 0.0072
	glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glyph.no_depth_test = true
	area.add_child(glyph)

	var name_label := Label3D.new()
	name_label.text = get_symbol_name(symbol_id)
	name_label.position = Vector3(0, 0.60, 0.48)
	name_label.font_size = 34
	name_label.outline_size = 10
	name_label.modulate = Color.WHITE
	name_label.outline_modulate = Color("#121731")
	name_label.pixel_size = 0.0056
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	area.add_child(name_label)

	if interactive:
		area.input_event.connect(_on_symbol_input.bind(symbol_id))


func _on_symbol_input(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int, symbol_id: int) -> void:
	var pressed: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	pressed = pressed or (event is InputEventScreenTouch and event.pressed)
	if not pressed or _touch_locked or not interactive:
		return

	# Android puede enviar toque y clic emulado en el mismo fotograma. Emitir la
	# señal de forma diferida evita cambiar nodos dentro del evento de física.
	_touch_locked = true
	call_deferred("_emit_safe_symbol", symbol_id)


func _emit_safe_symbol(symbol_id: int) -> void:
	if not is_inside_tree() or not interactive or not symbols.has(symbol_id):
		_touch_locked = false
		return
	symbol_pressed.emit(symbol_id)
	await get_tree().create_timer(0.16).timeout
	if is_instance_valid(self):
		_touch_locked = false


func celebrate(symbol_id: int) -> void:
	for node in _symbol_nodes:
		if int(node.get_meta("symbol_id", -1)) == symbol_id:
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(node, "scale", Vector3.ONE * 1.48, 0.16)
			tween.tween_property(node, "scale", Vector3.ONE, 0.24)


func wrong(symbol_id: int) -> void:
	for node in _symbol_nodes:
		if int(node.get_meta("symbol_id", -1)) == symbol_id:
			var origin := node.position
			var tween := create_tween()
			tween.tween_property(node, "position:x", origin.x - 0.22, 0.06)
			tween.tween_property(node, "position:x", origin.x + 0.22, 0.08)
			tween.tween_property(node, "position:x", origin.x, 0.06)


func enter_animation(delay: float = 0.0) -> void:
	var target_scale := scale
	scale = Vector3.ONE * 0.01
	rotation.y = -0.70
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.42).set_delay(delay)
	tween.tween_property(self, "rotation:y", 0.0, 0.42).set_delay(delay)


func fly_away(target: Vector3) -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", target, 0.45)
	tween.tween_property(self, "scale", Vector3.ONE * 0.12, 0.45)
	tween.tween_property(self, "rotation:y", rotation.y + TAU, 0.45)


func _material(color: Color, metallic: float, roughness: float, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 0.8
	return material
