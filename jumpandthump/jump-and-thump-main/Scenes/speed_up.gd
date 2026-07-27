extends Area2D
@onready var animated_sprite_2d = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	animated_sprite_2d.frame = randi_range(0,3)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	queue_free()
	if body.is_in_group("Player"):
		if animated_sprite_2d.frame == 0:
			body.speed_up()
		elif animated_sprite_2d.frame == 1:
			body.jump_up()
		elif animated_sprite_2d.frame == 2:
			body.invincible()
	
