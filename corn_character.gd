extends CharacterBody2D

# ── Node reference ───────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── Speed & gravity ──────────────────────────────────────────────
const SPEED          := 200.0
const JUMP_VELOCITY  := -400.0
const GRAVITY        := 980.0

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


func _ready() -> void:
	pass
	# Force this viewport to use THIS node's camera
	#$"../../../../SubViewportContainer2/SubViewport/map/corn_man2/Camera2D2".make_current()


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
	if Input.is_action_just_pressed("p2_up"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta
	jump_buffer_timer = maxf(jump_buffer_timer, 0.0)


# ── Wall hang ────────────────────────────────────────────────────
func _handle_wall_hang(delta: float) -> void:
	var touching_wall := is_on_wall()
	var moving_into_wall := (
		(Input.is_action_pressed("p2_right") and velocity.x > 0) or
		(Input.is_action_pressed("p2_left")  and velocity.x < 0)
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
	var direction := Input.get_axis("p2_left", "p2_right")
	velocity.x = direction * SPEED


# ── Jump ─────────────────────────────────────────────────────────
func _handle_jump() -> void:
	var wants_jump := (
		Input.is_action_just_pressed("p2_up") or
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


# ── Animation ────────────────────────────────────────────────────
func _update_animation() -> void:
	if velocity.x < 0:
		sprite.flip_h = false
	elif velocity.x > 0:
		sprite.flip_h = true

	if is_wall_hanging:
		sprite.play("wall_hang")
	elif not is_on_floor():
		sprite.play("jump")
	elif abs(velocity.x) > 5.0:
		sprite.play("walk")
	else:
		sprite.play("idle")
