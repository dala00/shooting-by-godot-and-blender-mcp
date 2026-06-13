extends Area3D

## 自機弾・敵弾の共通スクリプト。target_groups に当たると take_damage して消える。

var velocity: Vector3 = Vector3.ZERO
var target_groups: Array = []
var damage: int = 1
var life: float = 4.0
var color: Color = Color(1, 1, 0)


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1

	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	mesh.radial_segments = 8
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mesh.material = mat
	mi.mesh = mesh
	add_child(mi)

	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.55
	col.shape = sph
	add_child(col)

	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	global_position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_area_entered(area: Area3D) -> void:
	for g in target_groups:
		if area.is_in_group(g):
			if area.has_method("take_damage"):
				area.take_damage(damage)
			queue_free()
			return
