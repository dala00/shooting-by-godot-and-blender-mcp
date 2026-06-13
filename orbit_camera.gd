extends Camera3D

## 注視点まわりを回るオービットカメラ。
## 左ドラッグ（またはマウス中ボタンドラッグ）で視点回転、
## マウスホイールでズームイン／アウト。

## 注視する対象の位置（地球＝Planet の中心）。
@export var target: Vector3 = Vector3(0, 2, 0)

## 回転速度（ラジアン / ピクセル）。
@export var orbit_speed: float = 0.01

## ズーム 1 段あたりの距離変化量。
@export var zoom_step: float = 0.4

## カメラと注視点の最小・最大距離。
@export var min_distance: float = 2.5
@export var max_distance: float = 30.0

var _yaw: float = 0.0
var _pitch: float = 0.0
var _distance: float = 7.0
var _dragging: bool = false


func _ready() -> void:
	# 現在のカメラ位置から初期の角度・距離を求める。
	var offset := global_position - target
	_distance = clamp(offset.length(), min_distance, max_distance)
	_yaw = atan2(offset.x, offset.z)
	_pitch = asin(clamp(offset.y / max(offset.length(), 0.001), -1.0, 1.0))
	_update_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE:
				_dragging = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				_distance = clamp(_distance - zoom_step, min_distance, max_distance)
				_update_transform()
			MOUSE_BUTTON_WHEEL_DOWN:
				_distance = clamp(_distance + zoom_step, min_distance, max_distance)
				_update_transform()
	elif event is InputEventMouseMotion and _dragging:
		_yaw -= event.relative.x * orbit_speed
		_pitch = clamp(_pitch + event.relative.y * orbit_speed, deg_to_rad(-85.0), deg_to_rad(85.0))
		_update_transform()


func _update_transform() -> void:
	var offset := Vector3(
		_distance * cos(_pitch) * sin(_yaw),
		_distance * sin(_pitch),
		_distance * cos(_pitch) * cos(_yaw)
	)
	global_position = target + offset
	look_at(target, Vector3.UP)
