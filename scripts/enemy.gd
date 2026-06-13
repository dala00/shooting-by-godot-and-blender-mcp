extends Area3D

## 雑魚敵。etype で見た目・挙動が変わる: "drone"(直進) / "shooter"(撃つ) / "weaver"(蛇行)。

const MODELS := {
	"drone": preload("res://models/enemy_drone.glb"),
	"shooter": preload("res://models/enemy_shooter.glb"),
	"weaver": preload("res://models/enemy_weaver.glb"),
}
const SCALES := {"drone": 1.2, "shooter": 1.0, "weaver": 1.1}

var etype: String = "drone"
var hp: int = 2
var speed: float = 10.0
var manager = null

var _t: float = 0.0
var _shoot_t: float = 1.5
var _base_x: float = 0.0
var _mesh_node: Node3D = null
var _spin: bool = false


func _ready() -> void:
	add_to_group("enemy")
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1
	_build_visual()

	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.6
	col.shape = sph
	add_child(col)

	_base_x = position.x
	_shoot_t = randf_range(0.8, 1.8)


func _build_visual() -> void:
	# Blender製ローポリglb。-Y前で作ってあるのでGodotでは+Z（接近=プレイヤー方向）を向く。
	var scene: PackedScene = MODELS.get(etype, MODELS["drone"])
	var m: Node3D = scene.instantiate()
	m.scale = Vector3.ONE * float(SCALES.get(etype, 1.0))
	add_child(m)
	_mesh_node = m
	_spin = etype == "drone"  # ドローンだけ機雷っぽく回転。撃つ/蛇行はプレイヤーを向き続ける。


func _process(delta: float) -> void:
	_t += delta
	global_position += Vector3(0, 0, speed * delta)

	if etype == "weaver":
		var pp := position
		pp.x = _base_x + sin(_t * 2.0) * 3.0
		position = pp
	elif etype == "shooter":
		_shoot_t -= delta
		if _shoot_t <= 0.0 and global_position.z < 4.0:
			_shoot_at_player()
			_shoot_t = randf_range(1.2, 2.2)

	if _mesh_node and _spin:
		_mesh_node.rotate_y(delta * 1.8)

	if global_position.z > 12.0:
		queue_free()


func _shoot_at_player() -> void:
	if manager == null:
		return
	var p = manager.get_player_pos()
	var dir: Vector3 = (p - global_position).normalized()
	manager.spawn_enemy_bullet(global_position, dir)


func take_damage(d: int) -> void:
	hp -= d
	if hp <= 0:
		if manager:
			manager.spawn_hit_spark(global_position, Color(1.0, 0.6, 0.2), 1.1)  # 撃破ポップ
			manager.on_enemy_killed(global_position)
		queue_free()
	else:
		if manager:
			manager.spawn_hit_spark(global_position, Color(1, 1, 1), 0.8)
			manager.flash_entity(_mesh_node, Color(1, 1, 1), 0.06)
