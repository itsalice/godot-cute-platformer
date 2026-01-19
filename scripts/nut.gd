extends Area2D

@export var speed = 700
@export var damage = 50

var player: Node
var direction: Vector2

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	if enemies.has(body):
		body.hit(damage)
		queue_free()
