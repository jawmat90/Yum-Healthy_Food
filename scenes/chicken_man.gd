extends CharacterBody2D

# ── Node reference ───────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var reverse_sprite_facing : bool = false
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
const INVINCIBILITY_TIME := 1.2   # seconds of i-frames after hit
const KNOCKBACK_FORCE   := 300.0

# ── Coyote time ──────────────────────────────────────────────────
const COYOTE_TIME    := 0.12
var   coyote_timer   := 0.0
var   was_on_floor   := false

# ── Jump buffer ──────────────────────────────────────────────────
const JUMP_BUFFER_TIME := 0.10
var   jump_buffer_timer := 0.0

# ── Wall hang ────────────────────────────────────────────────────
const WALL_HANG_DURATION  := 0.6
const WALL_SLIDE_SPEED    := 40.0
var   wall_hang_timer     := 0.0
var   is_wall_hanging     := false
var   wall_hang_direction := 0
@onready var start_pos = global_position

func reset():
	global_position=start_pos
	set_physics_process(true)
func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	_handle_coyote_time(delta)
	_handle_jump_buffer(delta)
	_handle_wall_hang(delta)
	_apply_gravity(delta)
	_handle_horizontal_movement()
	_handle_jump()
	move_and_slide()
	was_on_floor = is_on_floor()
	_update_animation()


# ── Coyote time ──────────────────────────────────────────────────
func _handle_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	elif was_on_floor:
		coyote_timer -= delta
	else:
		coyote_timer -= delta
	coyote_timer = maxf(coyote_timer, 0.0)


func _can_coyote_jump() -> bool:
	return coyote_timer > 0.0 and not is_on_floor()


# ── Jump buffer ──────────────────────────────────────────────────
func _handle_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed(jump):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta
	jump_buffer_timer = maxf(jump_buffer_timer, 0.0)


# ── Wall hang ────────────────────────────────────────────────────
func _handle_wall_hang(delta: float) -> void:
	var touching_wall := is_on_wall()
	var moving_into_wall := (
		(Input.is_action_pressed(right_key) and velocity.x > 0) or
		(Input.is_action_pressed(left_key)  and velocity.x < 0)
	)

	if touching_wall and moving_into_wall and not is_on_floor() and velocity.y >= 0:
		if not is_wall_hanging:
			is_wall_hanging   = true
			wall_hang_timer   = WALL_HANG_DURATION
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
	var wants_jump := (
		Input.is_action_just_pressed(jump) or
		jump_buffer_timer > 0.0
	)

	if not wants_jump:
		return

	if is_on_floor() or _can_coyote_jump():
		velocity.y     = JUMP_VELOCITY
		coyote_timer   = 0.0
		jump_buffer_timer = 0.0
		return

	if is_wall_hanging:
		velocity.y          = JUMP_VELOCITY
		velocity.x          = -wall_hang_direction * SPEED
		is_wall_hanging     = false
		jump_buffer_timer   = 0.0


# ── Damage ───────────────────────────────────────────────────────
func take_damage(enemy_position: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
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
	is_invincible = false
	sprite.modulate.a = 1.0  # make sure it's fully visible


func die() -> void:
	# Add your game-over logic here
	print("Player died!")
	get_tree().reload_current_scene()


# ── Animation ────────────────────────────────────────────────────
func _update_animation() -> void:
	if reverse_sprite_facing:
		if velocity.x > 0:
			sprite.flip_h = true
		elif velocity.x < 0:
			sprite.flip_h = false
	else:
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true

	if is_wall_hanging:
		sprite.play("wall_hang")
	elif not is_on_floor():
		sprite.play("jump")
	elif abs(velocity.x) > 5.0:
		sprite.play("walk")
	else:
		sprite.play("idle")


	
