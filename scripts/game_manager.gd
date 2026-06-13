extends Node3D

## ステージ進行・敵/弾/アイテム/ボスの生成・HUD・クリア/ゲームオーバーを統括。

enum State { PLAYING, CLEAR, GAMEOVER }

const BULLET := preload("res://scripts/bullet.gd")
const ENEMY := preload("res://scripts/enemy.gd")
const ITEM := preload("res://scripts/item.gd")
const BOSS := preload("res://scripts/boss.gd")

const BOSS_TIME := 32.0
const PLANET_START_Z := -170.0
const PLANET_END_Z := -52.0

@onready var player: Area3D = $Player
@onready var bullets: Node3D = $Bullets
@onready var enemies: Node3D = $Enemies
@onready var items: Node3D = $Items
@onready var fx: Node3D = $FX
@onready var planet: Node3D = $Planet

var state: int = State.PLAYING
var _time: float = 0.0
var _spawn_t: float = 1.0
var _wave: int = 0
var _boss_spawned: bool = false
var score: int = 0

var hp_label: Label
var weapon_label: Label
var boss_label: Label
var center_label: Label


func _ready() -> void:
	player.manager = self
	_build_ui()
	var pz := planet.position
	pz.z = PLANET_START_Z
	planet.position = pz
	update_hud()


func _process(delta: float) -> void:
	if state == State.PLAYING:
		_time += delta
		var k: float = clamp(_time / BOSS_TIME, 0.0, 1.0)
		var pz := planet.position
		pz.z = lerp(PLANET_START_Z, PLANET_END_Z, k)
		planet.position = pz

		if not _boss_spawned:
			_spawn_t -= delta
			if _spawn_t <= 0.0:
				_spawn_wave()
				_spawn_t = 2.2
			if _time >= BOSS_TIME:
				_spawn_boss()
	else:
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()


# ---------- 生成 ----------

func _spawn_wave() -> void:
	_wave += 1
	var types := ["drone", "shooter", "weaver"]
	var n := 2 + (_wave % 2)
	for i in range(n):
		var e = ENEMY.new()
		e.etype = types[(i + _wave) % types.size()]
		e.manager = self
		match e.etype:
			"shooter":
				e.hp = 2
				e.speed = randf_range(4.0, 5.5)
			"weaver":
				e.hp = 2
				e.speed = randf_range(5.0, 6.5)
			_:
				e.hp = 2
				e.speed = randf_range(6.0, 8.0)
		enemies.add_child(e)
		e.position = Vector3(randf_range(-6.0, 6.0), randf_range(-2.5, 3.0), randf_range(-78.0, -62.0))
	if _wave % 2 == 0:
		_spawn_item()


func _spawn_item() -> void:
	var modes := [["spread", Color(1, 0.25, 0.25)], ["rapid", Color(0.3, 0.6, 1)], ["wide", Color(0.4, 1, 0.4)]]
	var m = modes[randi() % modes.size()]
	var it = ITEM.new()
	it.mode = m[0]
	it.color = m[1]
	it.manager = self
	items.add_child(it)
	it.position = Vector3(randf_range(-5.0, 5.0), randf_range(-2.0, 2.0), -62.0)


func _spawn_boss() -> void:
	_boss_spawned = true
	var boss = BOSS.new()
	boss.manager = self
	enemies.add_child(boss)
	boss.position = Vector3(0, 0, -44.0)
	center_label.text = "WARNING\nBOSS APPROACHING"
	await get_tree().create_timer(2.5).timeout
	if state == State.PLAYING:
		center_label.text = ""


func spawn_player_bullet(pos: Vector3, dir: Vector3) -> void:
	var b = BULLET.new()
	b.velocity = dir.normalized() * 58.0
	b.target_groups = ["enemy", "boss"]
	b.color = Color(0.4, 1, 1)
	bullets.add_child(b)
	b.global_position = pos


func spawn_enemy_bullet(pos: Vector3, dir: Vector3) -> void:
	var b = BULLET.new()
	b.velocity = dir.normalized() * 22.0
	b.target_groups = ["player"]
	b.color = Color(1, 0.45, 0.2)
	bullets.add_child(b)
	b.global_position = pos


func get_player_pos() -> Vector3:
	return player.global_position


# ---------- コールバック ----------

func on_enemy_killed(_pos: Vector3) -> void:
	score += 100
	update_hud()


func on_item_collected(_mode: String) -> void:
	update_hud()


func on_boss_hp_changed(hp: int, max_hp: int) -> void:
	var ratio: float = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	var filled := int(round(ratio * 20.0))
	boss_label.text = "BOSS [" + "#".repeat(filled) + "-".repeat(20 - filled) + "]"


func on_player_dead() -> void:
	if state != State.PLAYING:
		return
	state = State.GAMEOVER
	center_label.text = "GAME OVER\n\nPress Enter to retry"


func on_boss_defeated() -> void:
	if state != State.PLAYING:
		return
	state = State.CLEAR
	boss_label.text = ""
	center_label.text = "STAGE CLEAR!\n\nPress Enter to play again"
	_fireworks()


# ---------- 演出 ----------

func _fireworks() -> void:
	for i in range(20):
		await get_tree().create_timer(0.22).timeout
		if not is_inside_tree():
			return
		_spawn_firework(Vector3(randf_range(-9.0, 9.0), randf_range(-1.0, 6.0), randf_range(-22.0, -8.0)))


func _spawn_firework(pos: Vector3) -> void:
	var col := Color.from_hsv(randf(), 0.65, 1.0)
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.spread = 180.0
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 13.0
	pm.gravity = Vector3(0, -4.0, 0)
	pm.scale_min = 0.4
	pm.scale_max = 0.9
	pm.color = col
	p.process_material = pm

	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = col
	dm.emission_enabled = true
	dm.emission = col
	dm.emission_energy_multiplier = 4.0
	var qm := QuadMesh.new()
	qm.size = Vector2(0.25, 0.25)
	qm.material = dm
	p.draw_pass_1 = qm

	p.amount = 90
	p.lifetime = 1.6
	p.one_shot = true
	p.explosiveness = 0.9
	p.position = pos
	fx.add_child(p)
	p.emitting = true
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(p):
		p.queue_free()


# ---------- ヒット演出（軽量・短時間） ----------

## 着弾位置に小さな火花を一瞬出す。size で死亡ポップ等に流用。
func spawn_hit_spark(pos: Vector3, color: Color, size: float = 1.0) -> void:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.spread = 180.0
	pm.initial_velocity_min = 2.0 * size
	pm.initial_velocity_max = 5.0 * size
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.08 * size
	pm.scale_max = 0.18 * size
	pm.color = color
	p.process_material = pm

	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = color
	dm.emission_enabled = true
	dm.emission = color
	dm.emission_energy_multiplier = 2.5
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var qm := QuadMesh.new()
	qm.size = Vector2(0.16, 0.16) * size
	qm.material = dm
	p.draw_pass_1 = qm

	p.amount = 9
	p.lifetime = 0.26
	p.one_shot = true
	p.explosiveness = 1.0
	p.position = pos
	fx.add_child(p)
	p.emitting = true
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(p):
		p.queue_free()


## 被弾エンティティのメッシュ群を一瞬だけ単色に光らせる（ヒット確認用）。
func flash_entity(root: Node, color: Color = Color(1, 1, 1), dur: float = 0.07) -> void:
	if root == null:
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	var meshes: Array = []
	_collect_meshes(root, meshes)
	for mi in meshes:
		mi.material_override = mat
	await get_tree().create_timer(dur).timeout
	for mi in meshes:
		if is_instance_valid(mi):
			mi.material_override = null


func _collect_meshes(node: Node, acc: Array) -> void:
	if node is MeshInstance3D:
		acc.append(node)
	for c in node.get_children():
		_collect_meshes(c, acc)


# ---------- HUD ----------

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	hp_label = Label.new()
	hp_label.position = Vector2(20, 14)
	hp_label.add_theme_font_size_override("font_size", 22)
	cl.add_child(hp_label)

	weapon_label = Label.new()
	weapon_label.position = Vector2(20, 44)
	weapon_label.add_theme_font_size_override("font_size", 18)
	cl.add_child(weapon_label)

	boss_label = Label.new()
	boss_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.add_theme_font_size_override("font_size", 20)
	cl.add_child(boss_label)

	center_label = Label.new()
	center_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.add_theme_font_size_override("font_size", 44)
	cl.add_child(center_label)


func update_hud() -> void:
	var hearts := "v".repeat(max(player.hp, 0))
	hp_label.text = "HP " + hearts + "    SCORE " + str(score)
	weapon_label.text = "WEAPON: " + player.weapon_mode.to_upper()
