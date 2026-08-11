extends Area2D
@export var target : Area2D
@onready var exit : Marker2D = target.get_node("Exit")
@export var color : Color = Color(1.0, 1.0, 1.0, 1.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate = color
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.global_position = exit.global_position
