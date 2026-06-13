extends Area3D

## ボス。遠方から登場 → 左右に動きつつ弾幕を撃つ。HPが減ると攻撃が激化。

const BOSS_SCENE := preload("res://models/boss.glb")

var max_hp: int = 70
var hp: int = 70
var manager = null

var _t: float = 0.0
var _shoot_t: float = 1.5
var _mi: Node3D = null


func _ready() -> void:
	add_to_group("boss")
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1
	hp = max_hp

	# Blender製ローポリ戦艦。-Y前で作ってあるのでGodotでは+Z（プレイヤー方向）を向く。
	var ship: Node3D = BOSS_SCENE.instantiate()
	add_child(ship)
	_mi = ship

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.9, 2.2, 3.6)
	col.shape = box
	add_child(col)


func _process(delta: float) -> void:
	_t += delta

	# 登場: 手前まで前進。
	if global_position.z < -18.0:
		global_position += Vector3(0, 0, 12.0 * delta)
		return

	# 左右・上下にゆらゆら（艦首は常にプレイヤー側=+Zを向いたまま）。
	var pp := position
	pp.x = sin(_t * 0.8) * 6.0
	pp.y = sin(_t * 0.5) * 2.0
	position = pp

	_shoot_t -= delta
	var rate := 1.4 if hp > int(max_hp * 0.4) else 0.8
	if _shoot_t <= 0.0:
		_shoot()
		_shoot_t = rate


func _shoot() -> void:
	if manager == null:
		return
	var n := 5 if hp > int(max_hp * 0.4) else 9
	for i in range(n):
		var ang: float = lerp(-0.6, 0.6, float(i) / float(max(n - 1, 1)))
		manager.spawn_enemy_bullet(global_position + Vector3(0, 0, 1.5), Vector3(ang, 0, 1).normalized())
	# 自機狙い1発。
	var p = manager.get_player_pos()
	manager.spawn_enemy_bullet(global_position, (p - global_position).normalized())


func take_damage(d: int) -> void:
	hp -= d
	if manager:
		manager.on_boss_hp_changed(hp, max_hp)
		manager.spawn_hit_spark(global_position + Vector3(0, 0, 2.0), Color(1, 0.8, 0.4), 0.8)
	if hp <= 0:
		if manager:
			manager.spawn_hit_spark(global_position, Color(1.0, 0.5, 0.2), 1.6)  # 撃破ポップ
			manager.on_boss_defeated()
		queue_free()
	elif manager:
		manager.flash_entity(_mi, Color(1, 1, 1), 0.05)
