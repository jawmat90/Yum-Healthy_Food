extends Node2D
func _process(delta):
	translate(Vector2.RIGHT * 25 * delta)

func _on_animated_sprite_2d_animation_finished():
	queue_free()
