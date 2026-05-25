extends CharacterBody2D

const SPEED = 60.0
const GRAVITY = 900.0

@export var move_right = true
var flip_cooldown = 0.0

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Horizontal movement
	velocity.x = SPEED if move_right else -SPEED
	move_and_slide()

	# Flip sprite to match direction
	$AnimatedSprite2D.flip_h = move_right

	# Cooldown timer to prevent rapid oscillation on walls
	if flip_cooldown > 0:
		flip_cooldown -= delta
		return

	# Turn around on walls
	if is_on_wall():
		move_right = !move_right
		velocity.x = 0
		flip_cooldown = 0.2

	# Edge Detection
	if move_right and not $RayCastRight.is_colliding():
		move_right = false
		flip_cooldown = 0.2
	elif not move_right and not $RayCastLeft.is_colliding():
		move_right = true
		flip_cooldown = 0.2


# --- Stomp Detection ---
func _on_stomp_area_body_entered(body):
	if body.is_in_group("player") and body.velocity.y >= 0:
		die()
		body.velocity.y = -300

func _on_body_area_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(global_position)


# --- Death ---
func die():
	$AnimatedSprite2D.play("dead")
	set_physics_process(false)
	# Disable both hit areas so nothing triggers during death animation
	$StompArea/CollisionShape2D.set_deferred("disabled", true)
	$BodyArea/CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(0.3).timeout
	queue_free()
