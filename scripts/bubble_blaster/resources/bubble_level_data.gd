class_name BubbleLevelData
extends Resource

@export var num_colors: int = 3
@export var visible_cols: int = 10         # size of the on-screen play window
@export var total_cols: int = 10           # >= visible_cols; surplus = hidden reserve
@export var bubbles_per_col: int = 10
@export var blob_size_min: int = 4         # blob generator: bigger = Easy
@export var blob_size_max: int = 6         # smaller = Hard; both >= 3 to keep clusters poppable
