extends Node2D

@export var projectile_scene: PackedScene;
@export var projectile_datas: Array[projectile_spawn];

@export var top: Marker2D;
@export var left: Marker2D;
@export var bottom: Marker2D;
@export var right: Marker2D;

var half_width: float = 0;
var half_height: float = 0;

var current_delay: float = 0;
var complete: bool = false;

func _ready() -> void:
	find_arena_dimensions();
	if remaining_projectiles():
		current_delay = projectile_datas[0].delay_seconds;

func find_arena_dimensions():
	half_width = top.position.x-left.position.x;
	half_height = left.position.y-top.position.y;

func _process(delta: float) -> void:
	if complete:
		return;
	
	if remaining_projectiles():
		current_delay-=delta;
		if current_delay <= 0:
			var current_data: projectile_spawn = projectile_datas[0];
			
			var new_proj: Area2D = projectile_scene.instantiate();
			add_child(new_proj);
			
			match current_data.dir:
				current_data.directions.UP:
					new_proj.global_position = top.global_position;
					new_proj.global_position.x += half_width * current_data.offset_ratio;
					new_proj.rotation_degrees = 90 + current_data.angle_offset_degress;
				current_data.directions.LEFT:
					new_proj.global_position = left.global_position;
					new_proj.global_position.y += half_height * current_data.offset_ratio;
					new_proj.rotation_degrees = 0 + current_data.angle_offset_degress;
				current_data.directions.DOWN:
					new_proj.global_position = bottom.global_position;
					new_proj.global_position.x += half_width * current_data.offset_ratio;
					new_proj.rotation_degrees = 270 + current_data.angle_offset_degress;
				current_data.directions.RIGHT:
					new_proj.global_position = right.global_position;
					new_proj.global_position.y += half_height * current_data.offset_ratio;
					new_proj.rotation_degrees = 180 + current_data.angle_offset_degress;
			
			projectile_datas.remove_at(0);
			if remaining_projectiles():
				current_delay = projectile_datas[0].delay_seconds;
			else:
				complete = true;

func remaining_projectiles() -> bool:
	return projectile_datas.size() > 0;
