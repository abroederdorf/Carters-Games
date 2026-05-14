class_name HideSeekItemData
extends Resource

@export var item_name: String = ""
@export var thumbnail: Texture2D
@export var position: Vector2 = Vector2.ZERO
@export var radius: float = 50.0
@export var base_scale: float = 1.0       # Intrinsic item size (e.g. 0.5 for small, 2.0 for large)
@export var preferred_anchors: Array[int] = [] # List of anchor IDs this item likes
@export var tags: Array[String] = []
