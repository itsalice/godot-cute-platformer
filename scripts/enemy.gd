extends CharacterBody2D

@export var health = 100
@export var damage = 100
var incoming_damage = 0

@onready var sprite = $AnimatedSprite2D

func hit(dmg: int):
	incoming_damage += dmg

func damaged():
	print(health)
	health -= incoming_damage
	incoming_damage = 0
	sprite.play("damage_1")
	await sprite.animation_finished
	sprite.play("move_1")

func _physics_process(_delta):
	sprite.play()
	
	if incoming_damage:
		if incoming_damage >= health:
			sprite.play("death", 1.5)
			await sprite.animation_finished
			queue_free()
		else:
			damaged()
