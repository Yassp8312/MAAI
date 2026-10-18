extends Resource
## All movement values use logical pixels per 60 Hz tick.
@export var walk_speed: float = 5.0
@export var jump_speed: float = -18.0
@export var gravity: float = 0.65
@export var sprint_distance: float = 260.0
@export var sprint_ticks: int = 18
@export var dodge_ticks: int = 25
@export var dodge_start: int = 3
@export var dodge_end: int = 10
@export var perfect_end: int = 5
@export var parry_window: int = 9
@export var parry_ticks: int = 20
@export var parry_success_ticks: int = 6
@export var parried_ticks: int = 18
@export var buffer_ticks: int = 5
@export var body_size: Vector2 = Vector2(64, 250)
@export var arena_left: float = 120.0
@export var arena_right: float = 1480.0
@export var floor_y: float = 710.0
@export var round_close_ticks: int = 72
@export var countdown_ticks: int = 54
@export var attacks: Array[Resource] = []

