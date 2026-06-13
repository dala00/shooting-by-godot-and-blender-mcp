extends Area3D

## 取ると自機の攻撃パターン(weapon_mode)を切り替えるアイテム。mode 別に色が違う。

var mode: String = "spread"
var color: Color = Color(1, 0.2, 0.2)
var manager = null

var _t: float = 0.0
var _mi: MeshInstance3D = null


func _ready() -> void:
	add_to_group("item")
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.8, 0.8, 0.8)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	bm.material = mat
	mi.mesh = bm
	add_child(mi)
	_mi = mi

	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.7
	col.shape = sph
	add_child(col)


func _process(delta: float) -> void:
	_t += delta
	global_position += Vector3(0, 0, 8.0 * delta)
	if _mi:
		_mi.rotate_y(delta * 2.0)
		_mi.rotate_x(delta * 1.0)
	if global_position.z > 12.0:
		queue_free()


func apply_to(player) -> void:
	player.weapon_mode = mode
	if manager:
		manager.on_item_collected(mode)
	queue_free()
