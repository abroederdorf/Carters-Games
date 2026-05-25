class_name HideSeekAnchor
extends Resource

@export var id: int = -1 # Unique ID for referencing in JSON/Editor
@export var position: Vector2 = Vector2.ZERO
@export var radius: float = 50.0
@export var visual_scale: float = 1.0
@export var difficulty: int = 1 # 0: Easy, 1: Medium, 2: Hard
@export var tags: Array[String] = []
