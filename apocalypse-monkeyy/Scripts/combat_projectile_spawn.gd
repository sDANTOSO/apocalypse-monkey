extends Resource
class_name projectile_spawn

@export var delay_seconds: float = 1;
@export var offset_ratio: float = 0.5;# decimal represting distance from top to bottown of arena side

enum directions {LEFT, RIGHT, UP, DOWN}
@export var dir: directions = directions.LEFT;

@export var angle_offset_degress: float = 0;
