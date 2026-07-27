extends CharacterBody2D
@export var left : String
@export var right : String
@export var jump : String
# Movement parameters
@export var speed: float = 100.0

@export var jump_force: float = 200.0
@export var gravity: float = 500.0
@export var max_jumps: int = 1
@export var acceleration : float = 10.0
var last_direction = 1
var score = 0
# Coyote time parameters
@export var coyote_time: float = 0.2
var coyote_timer: float = 0.0
@onready var label = $CanvasLayer/MarginContainer/PanelContainer/HBoxContainer/Label
const EXPLODE = preload("res://Scenes/explode.tscn")
# Jumping state
const JUMPCLOUD = preload("res://jumpcloud.tscn")
var jumps_left: int = 0
var is_jumping: bool = false
const DUST_CLOUD = preload("res://dust_cloud.tscn")
# Animation player reference
@onready var animation_player: AnimationPlayer = $AnimationPlayer
const INVINICIBLE = preload("res://Scenes/invinicible.tscn")
func _ready():
	jumps_left = max_jumps

func jump_up():
	jump_force = 300
	await get_tree().create_timer(5.0).timeout
	jump_force = 200
	
func speed_up():
	speed = 170
	await get_tree().create_timer(5.0).timeout
	speed = 100
	
func invincible():
	var invincible_object = INVINICIBLE.instantiate()
	invincible_object.position = Vector2.ZERO
	add_child(invincible_object)
	await get_tree().create_timer(3.0).timeout
	invincible_object.queue_free()
	

func _physics_process(delta):
	print(jumps_left)
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Check for horizontal movement
	var direction = Input.get_axis(left,right)
	if direction:
		velocity.x = move_toward(velocity.x, speed * direction, acceleration)
		animation_player.play("run")
		if velocity.x > 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
		last_direction = direction
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * 2)
		animation_player.play("idle")

	if not is_on_floor():
		if velocity.y < 0:
			animation_player.play("jump_up")
		else:
			animation_player.play("jump_down")
	# Jumping logic
	if Input.is_action_just_pressed(jump) and (is_on_floor() or coyote_timer > 0.0 or jumps_left > 0):
		if not is_on_floor() and coyote_timer <=0:
			jumps_left -= 1
	
		velocity.y = -jump_force
		is_jumping = true
		var jump_cloud = JUMPCLOUD.instantiate()
		jump_cloud.global_position = global_position
		jump_cloud.global_position.y +=5
		add_sibling(jump_cloud)
	
	if Input.is_action_just_released(jump) and velocity.y < 0:
		velocity.y /= 2	
	
	# Update coyote timer
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = max_jumps
	else:
		coyote_timer -= delta

	# Apply velocity to the character
	move_and_slide()
	update_indicator()
	
func update_indicator():
	out_of_screen_indicator.global_position.x = global_position.x
	out_of_screen_indicator.global_position.y = 8

func explode():
	var explosion = EXPLODE.instantiate()
	explosion.global_position = global_position
	add_sibling(explosion)
	global_position = Vector2(randi_range(40,420),-200)
	
	
func _on_kill_box_body_entered(body):
	var collider = $RayCast2D.get_collider()
	if collider and $RayCast2D.is_colliding():
		print("falling and colliding")
		if body.is_in_group("Player"):
			body.explode()
			velocity.y = -jump_force
			jumps_left = 1
			score +=1
			label.text = "Thumps : " +str(score)
		if body.is_in_group("Invincible"):
			velocity.y = -jump_force
			jumps_left = 0

@onready var out_of_screen_indicator = $OutOfScreenIndicator
func _on_visible_on_screen_notifier_2d_screen_entered():
	out_of_screen_indicator.hide()

func add_dust_cloud():
	if Input.get_axis(left,right) == 0:
		return
	var dust = DUST_CLOUD.instantiate()
	dust.global_position = global_position
	dust.scale.x = last_direction
	add_sibling(dust)

func _on_visible_on_screen_notifier_2d_screen_exited():
	out_of_screen_indicator.show()
