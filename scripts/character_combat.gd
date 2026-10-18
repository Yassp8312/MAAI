extends Resource
## First playable weapon envelopes, in logical pixels from the fighter pivot.
## Order: three ground attacks, then their three aerial variants.
@export var reaches: PackedFloat32Array = PackedFloat32Array([245, 160, 240, 190, 150, 160])
@export var dodge_height: float = 130.0
@export var startup_ticks: PackedInt32Array = PackedInt32Array([9, 12, 15, 8, 11, 14])
@export var active_ticks: PackedInt32Array = PackedInt32Array([4, 6, 5, 4, 6, 5])
@export var recovery_ticks: PackedInt32Array = PackedInt32Array([11, 14, 16, 12, 15, 16])
@export var advances: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0])
@export var move_names: PackedStringArray = PackedStringArray()
@export var move_roles: PackedStringArray = PackedStringArray()
@export var style_note: String = ""
@export var walk_scale: float = 1.0
@export var sprint_scale: float = 1.0
