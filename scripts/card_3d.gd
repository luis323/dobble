class_name Card3D
extends Node3D

signal symbol_pressed(symbol_id: int)

const SYMBOL_COLORS := [
	Color("#ff4d8d"), Color("#18d7ff"), Color("#ffd43b"),
	Color("#7cff6b"), Color("#a875ff"), Color("#ff873b")
]

var interactive := false
var card_radius := 2.7
var symbols: Array[int] = []
var _base: MeshInstance3D
var _symbol_nodes: Array[Node3D] = []


func setup(new_symbols: Array, can_touch: bool, radius: float = 2.7) -> void:
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
	disc.height = 0.18
	disc.radial_segments = 64
	_base.mesh = disc
	_base.material_override = _material(Color("#f9fbff"), 0.22, 0.65)
	add_child(_base)

	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = card_radius - 0.12
	rim_mesh.outer_radius = card_radius + 0.04
	rim_mesh.rings = 64
	rim_mesh.ring_segments = 12
	rim.mesh = rim_mesh
	rim.position.y = 0.12
	rim.material_override = _material(Color("#37d9ff"), 0.15, 0.55, Color("#0ebaff"))
	add_child(rim)

	var count := symbols.size()
	var orbit := card_radius * 0.58
	for index in count:
		var angle := -PI * 0.5 + TAU * float(index) / float(count)
		var pos := Vector3(cos(angle) * orbit, 0.22, sin(angle) * orbit)
		_create_symbol(symbols[index], pos, index)


func _create_symbol(symbol_id: int, pos: Vector3, index: int) -> void:
	var area := Area3D.new()
	area.name = "Simbolo_%02d" % symbol_id
	area.position = pos
	area.input_ray_pickable = interactive
	area.set_meta("symbol_id", symbol_id)
	add_child(area)
	_symbol_nodes.append(area)

	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.25, 0.55, 1.25)
	collision.shape = box
	area.add_child(collision)

	var pedestal := MeshInstance3D.new()
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 0.49
	pedestal_mesh.bottom_radius = 0.55
	pedestal_mesh.height = 0.18
	pedestal_mesh.radial_segments = 24
	pedestal.mesh = pedestal_mesh
	var color: Color = SYMBOL_COLORS[symbol_id % SYMBOL_COLORS.size()]
	pedestal.material_override = _material(color, 0.18, 0.38, color * 0.26)
	area.add_child(pedestal)

	var topper := MeshInstance3D.new()
	topper.position = Vector3(0, 0.18, 0)
	topper.scale = Vector3.ONE * (0.22 + float(symbol_id % 3) * 0.025)
	match symbol_id % 4:
		0:
			topper.mesh = BoxMesh.new()
		1:
			topper.mesh = SphereMesh.new()
		2:
			var shape := CylinderMesh.new()
			shape.top_radius = 0.8
			shape.bottom_radius = 0.35
			shape.height = 1.0
			topper.mesh = shape
		_:
			var torus := TorusMesh.new()
			torus.inner_radius = 0.55
			torus.outer_radius = 1.0
			topper.mesh = torus
	topper.material_override = _material(Color.WHITE, 0.08, 0.55)
	area.add_child(topper)

	var label := Label3D.new()
	label.text = str(symbol_id + 1)
	label.position = Vector3(0, 0.54, 0)
	label.font_size = 72
	label.outline_size = 14
	label.modulate = Color.WHITE
	label.outline_modulate = Color("#11152c")
	label.pixel_size = 0.0075
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	area.add_child(label)

	if interactive:
		area.input_event.connect(_on_symbol_input.bind(symbol_id))


func _on_symbol_input(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int, symbol_id: int) -> void:
	var pressed: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	pressed = pressed or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		symbol_pressed.emit(symbol_id)


func celebrate(symbol_id: int) -> void:
	for node in _symbol_nodes:
		if int(node.get_meta("symbol_id", -1)) == symbol_id:
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(node, "scale", Vector3.ONE * 1.42, 0.16)
			tween.tween_property(node, "scale", Vector3.ONE, 0.22)


func wrong(symbol_id: int) -> void:
	for node in _symbol_nodes:
		if int(node.get_meta("symbol_id", -1)) == symbol_id:
			var origin := node.position
			var tween := create_tween()
			tween.tween_property(node, "position:x", origin.x - 0.18, 0.06)
			tween.tween_property(node, "position:x", origin.x + 0.18, 0.08)
			tween.tween_property(node, "position:x", origin.x, 0.06)


func enter_animation(delay: float = 0.0) -> void:
	var target_scale := scale
	# Una escala exactamente cero hace que la física 3D no pueda invertir la base.
	scale = Vector3.ONE * 0.01
	rotation.y = -0.7
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.42).set_delay(delay)
	tween.tween_property(self, "rotation:y", 0.0, 0.42).set_delay(delay)


func _material(color: Color, metallic: float, roughness: float, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 0.7
	return material
