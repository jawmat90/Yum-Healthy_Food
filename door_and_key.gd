extends Node2D
var has_key = false
@onready var on_screen: VisibleOnScreenNotifier2D = $Door/VisibleOnScreenNotifier2D
@onready var animation_player: AnimationPlayer = $Door/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if on_screen.is_on_screen() and has_key:
	
		animation_player.play("Open")
		set_process(false)
		await animation_player.animation_finished
		queue_free()


func _on_key_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		$Key.queue_free()
		has_key = true
