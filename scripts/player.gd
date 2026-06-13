extends Area3D

## 自機。キーボードで上下左右移動、弾は自動連射。weapon_mode で攻撃パターンが変わる。

const SHIP_SCENE := preload("res://models/ship_lowpoly.glb")

@export var move_speed: float = 14.0
@export var x_limit: float = 7.0
@export var y_min: float = -2.5
@export var y_max: float = 3.5
@export var max_hp: int = 5
@export var ship_rot_deg: Vector3 = Vector3(0, 0, 0)  # Blenderで機首=-Z/上面=+Yで作成済み。補正不要

var hp: int = 5
var weapon_mode: String = "single"
var manager = null

var _fire_t: float = 0.0
var _ship: Node3D = null
var _invuln: float = 2.5  # 開始直後の無敵時間


func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1

	_ship = SHIP_SCENE.instantiate()
	_ship.scale = Vector3(0.8, 0.8, 0.8)
	_ship.rotation_degrees = ship_rot_deg
	position = Vector3(0, 0.0, 0)
	add_child(_ship)
	# Blender製glbは正しい法線＆マテリアル（船体/エンジン発光/キャノピー）を持つので
	# 上書きせずそのまま使う。中心ズレだけ見た目のAABB中心を原点へ合わせ直す。
	_recenter_ship()

	# 当たり判定（大きめ＝狙いやすく）。
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.1
	col.shape = sph
	add_child(col)

	area_entered.connect(_on_area_entered)


func _ship_world_aabb(node: Node, acc: AABB, first: Array) -> AABB:
	if node is MeshInstance3D:
		var wa: AABB = node.global_transform * node.get_aabb()
		if first[0]:
			acc = wa
			first[0] = false
		else:
			acc = acc.merge(wa)
	for c in node.get_children():
		acc = _ship_world_aabb(c, acc, first)
	return acc


func _recenter_ship() -> void:
	var aabb := _ship_world_aabb(_ship, AABB(), [true])
	if aabb.size == Vector3.ZERO:
		return
	var center := aabb.position + aabb.size * 0.5
	_ship.global_position += global_position - center


func _process(delta: float) -> void:
	if manager and manager.state != manager.State.PLAYING:
		return
	if _invuln > 0.0:
		_invuln -= delta

	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		dir.y -= 1.0
	if dir != Vector3.ZERO:
		position += dir.normalized() * move_speed * delta
	var pp := position
	pp.x = clamp(pp.x, -x_limit, x_limit)
	pp.y = clamp(pp.y, y_min, y_max)
	position = pp

	# 自動連射。
	_fire_t -= delta
	if _fire_t <= 0.0:
		_fire()
		_fire_t = _cooldown()


func _cooldown() -> float:
	match weapon_mode:
		"rapid":
			return 0.10
		"spread":
			return 0.22
		"wide":
			return 0.26
		_:
			return 0.18


func _fire() -> void:
	if manager == null:
		return
	match weapon_mode:
		"rapid":
			manager.spawn_player_bullet(global_position + Vector3(-0.5, 0, 0), Vector3(0, 0, -1))
			manager.spawn_player_bullet(global_position + Vector3(0.5, 0, 0), Vector3(0, 0, -1))
		"spread":
			manager.spawn_player_bullet(global_position, Vector3(0, 0, -1))
			manager.spawn_player_bullet(global_position, Vector3(-0.28, 0, -1))
			manager.spawn_player_bullet(global_position, Vector3(0.28, 0, -1))
		"wide":
			for a in [-0.5, -0.25, 0.0, 0.25, 0.5]:
				manager.spawn_player_bullet(global_position, Vector3(a, 0, -1))
		_:
			manager.spawn_player_bullet(global_position, Vector3(0, 0, -1))


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("item"):
		area.apply_to(self)
	elif area.is_in_group("enemy") or area.is_in_group("boss"):
		take_damage(1)
		if area.has_method("take_damage"):
			area.take_damage(2)


func take_damage(d: int) -> void:
	if manager and manager.state != manager.State.PLAYING:
		return
	if _invuln > 0.0:
		return
	hp -= d
	if manager:
		manager.update_hud()
		manager.spawn_hit_spark(global_position, Color(1.0, 0.4, 0.3), 1.0)
		manager.flash_entity(_ship, Color(1.0, 0.5, 0.5), 0.08)
	if hp <= 0:
		if manager:
			manager.on_player_dead()
