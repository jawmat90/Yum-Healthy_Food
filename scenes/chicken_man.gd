extends CharacterBody2D

# ── Node reference ───────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var stomp_ray: RayCast2D = %RayCast2D
@export var reverse_sprite_facing : bool = false
@export var debug_stomp : bool = false
var score = 0
@export var score_counter : Label
# ── Speed & gravity ──────────────────────────────────────────────
const SPEED          := 200.0
const JUMP_VELOCITY  := -400.0
const GRAVITY        := 980.0
@export var left_key : String = "p1_left"
@export var right_key : String = "p1_right"
@export var jump : String = "p1_jump"

# ── Health ───────────────────────────────────────────────────────
const MAX_HEALTH        := 3
var   health            := MAX_HEALTH
var   is_invincible     := false
var   is_dead           := false
const INVINCIBILITY_TIME := 1.2   # seconds of i-frames after hit
const KNOCKBACK_FORCE   := 300.0

# ── Coyote time ──────────────────────────────────────────────────
const COYOTE_TIME    := 0.12
var   coyote_timer   := 0.0

# ── Jump buffer ──────────────────────────────────────────────────
const JUMP_BUFFER_TIME := 0.10
var   jump_buffer_timer := 0.0

# ── Wall hang ────────────────────────────────────────────────────
const WALL_HANG_DURATION  := 0.6
const WALL_SLIDE_SPEED    := 40.0
var   wall_hang_timer     := 0.0
var   is_wall_hanging     := false
var   wall_hang_direction := 0

# ── Stomp (head-jump PvP kill) ────────────────────────────────────
const STOMP_BOUNCE_VELOCITY := -350.0   # how high you pop up after stomping someone

# ── Respawn ───────────────────────────────────────────────────────
const RESPAWN_MIN_X       := -600.0
const RESPAWN_MAX_X       := 70.0
const RESPAWN_DROP_HEIGHT := -360.0  # how far above start_pos.y to drop from on respawn

@onready var start_pos = global_position


func _mask_to_bits(mask: int) -> Array:
	var bits := []
	for i in range(32):
		if mask & (1 << i):
			bits.append(i + 1)  # Godot layer numbers are 1-indexed in the editor
	return bits


func _ready() -> void:
	stomp_ray.enabled = true
	stomp_ray.collide_with_areas = true
	stomp_ray.collide_with_bodies = false

	if debug_stomp:
		print("[%s] READY -----------------------------" % name)
		print("  stomp_ray position=%s target_position=%s enabled=%s" % [
			stomp_ray.position, stomp_ray.target_position, stomp_ray.enabled])
		print("  stomp_ray collision_mask=%s (bits: %s)" % [
			stomp_ray.collision_mask, _mask_to_bits(stomp_ray.collision_mask)])
		print("  hitbox collision_layer=%s (bits: %s) monitorable=%s" % [
			hitbox.collision_layer, _mask_to_bits(hitbox.collision_layer), hitbox.monitorable])
		print("  body collision_layer=%s collision_mask=%s" % [
			collision_layer, collision_mask])


func reset() -> void:
	var spawn_x := randf_range(RESPAWN_MIN_X, RESPAWN_MAX_X)
	global_position = Vector2(spawn_x, RESPAWN_DROP_HEIGHT)
	velocity = Vector2.ZERO
	health = MAX_HEALTH
	is_invincible = false
	is_dead = false
	sprite.modulate.a = 1.0
	sprite.visible = true
	%RayCast2D.enabled = true
	collision_shape.set_deferred("disabled", false)
	hitbox.monitoring = true
	hitbox.monitorable = true
	set_physics_process(true)
	show()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_handle_coyote_time(delta)
	_handle_jump_buffer(delta)
	_handle_wall_hang(delta)
	_apply_gravity(delta)
	_handle_horizontal_movement()
	_handle_jump()
	move_and_slide()
	_check_stomp()
	_update_animation()


# ── Coyote time ──────────────────────────────────────────────────
func _handle_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)


func _can_coyote_jump() -> bool:
	return coyote_timer > 0.0 and not is_on_floor()


# ── Jump buffer ──────────────────────────────────────────────────
func _handle_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed(jump):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)


# ── Wall hang ────────────────────────────────────────────────────
func _handle_wall_hang(delta: float) -> void:
	var touching_wall := is_on_wall()
	var moving_into_wall := (
		(Input.is_action_pressed(right_key) and velocity.x > 0) or
		(Input.is_action_pressed(left_key)  and velocity.x < 0)
	)

	if touching_wall and moving_into_wall and not is_on_floor() and velocity.y >= 0:
		if not is_wall_hanging:
			is_wall_hanging     = true
			wall_hang_timer     = WALL_HANG_DURATION
			wall_hang_direction = -1 if is_on_wall_only() and velocity.x < 0 else 1
		wall_hang_timer -= delta
		if wall_hang_timer <= 0.0:
			is_wall_hanging = false
	else:
		is_wall_hanging = false


# ── Gravity ───────────────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	if is_wall_hanging and wall_hang_timer > 0.0:
		velocity.y = WALL_SLIDE_SPEED
	else:
		velocity.y += GRAVITY * delta


# ── Horizontal movement ──────────────────────────────────────────
func _handle_horizontal_movement() -> void:
	var direction := Input.get_axis(left_key, right_key)
	velocity.x = direction * SPEED


# ── Jump ─────────────────────────────────────────────────────────
func _handle_jump() -> void:
	# Use only the buffer timer — it's set to JUMP_BUFFER_TIME on the
	# exact frame just_pressed fires, so it covers that frame too.
	var wants_jump := jump_buffer_timer > 0.0
	if not wants_jump:
		return

	if is_on_floor() or _can_coyote_jump():
		velocity.y        = JUMP_VELOCITY
		coyote_timer      = 0.0
		jump_buffer_timer = 0.0
		return

	if is_wall_hanging:
		velocity.y        = JUMP_VELOCITY
		velocity.x        = -wall_hang_direction * SPEED
		is_wall_hanging   = false
		jump_buffer_timer = 0.0


# ── Stomp (head-jump PvP kill) ────────────────────────────────────
func _check_stomp() -> void:
	if velocity.y < 0:
		return  # only counts while falling

	if debug_stomp and Engine.get_physics_frames() % 15 == 0:
		# Sampled so it doesn't spam every single physics frame
		print("[%s] falling, ray.enabled=%s ray.is_colliding=%s" % [
			name, stomp_ray.enabled, stomp_ray.is_colliding()])

	if not stomp_ray.is_colliding():
		return

	var hit_area := stomp_ray.get_collider()
	if debug_stomp:
		print("[%s] ray hit: %s (class %s)" % [
			name, hit_area, hit_area.get_class() if hit_area else "null"])

	if hit_area == null:
		return

	var other = hit_area.get_parent()
	if debug_stomp:
		print("[%s] parent of hit: %s | is self=%s | has stomp_die=%s" % [
			name, other, other == self,
			(is_instance_valid(other) and other.has_method("stomp_die"))])

	if other == self or not is_instance_valid(other) or not other.has_method("stomp_die"):
		return
	if other.is_dead:
		if debug_stomp:
			print("[%s] target already dead, skipping" % name)
		return

	if debug_stomp:
		print("[%s] STOMP confirmed on %s" % [name, other])

	other.stomp_die()
	velocity.y = STOMP_BOUNCE_VELOCITY
	score = score + 1
	score_counter.text = str(score)



func stomp_die() -> void:
	health = 0
	die()


# ── Damage ───────────────────────────────────────────────────────
func take_damage(enemy_position: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or is_dead:
		return

	health -= 1
	is_invincible = true

	# Knockback away from the enemy
	if enemy_position != Vector2.ZERO:
		var direction = sign(global_position.x - enemy_position.x)
		velocity.x = direction * KNOCKBACK_FORCE
		velocity.y = -200.0  # small upward bump

	if health <= 0:
		die()
	else:
		_start_invincibility()


func _start_invincibility() -> void:
	# Flash the sprite during i-frames
	var tween := create_tween().set_loops(6)
	tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(INVINCIBILITY_TIME).timeout
	if not is_dead:
		is_invincible = false
		sprite.modulate.a = 1.0


func die() -> void:
	if is_dead:
		return
	is_dead = true

	print("Player died!")
	set_physics_process(false)
	velocity = Vector2.ZERO

	collision_shape.set_deferred("disabled", true)
	hitbox.monitoring = false
	hitbox.monitorable = false
	stomp_ray.enabled = false
	sprite.modulate.a = 0.4

	# Auto-respawn after a short delay
	await get_tree().create_timer(2.0).timeout
	reset()

	# Uncomment when you're ready to wire up round-restart logic:
	# get_tree().reload_current_scene()


# ── Animation ────────────────────────────────────────────────────
func _update_animation() -> void:
	if reverse_sprite_facing:
		sprite.flip_h = velocity.x > 0
	else:
		sprite.flip_h = velocity.x < 0

	if is_wall_hanging:
		sprite.play("wall_hang")
	elif not is_on_floor():
		sprite.play("jump")
	elif abs(velocity.x) > 5.0:
		sprite.play("walk")
	else:
		sprite.play("idle")
