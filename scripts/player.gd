extends CharacterBody2D

enum States 
{
	IDLE,
	DIE,
	RUN,
	JUMP,
	LIFT,
	FALL,
	LAND
}

var state: States = States.IDLE: set = set_state

@export var nut_scene : PackedScene
@export var speed = 300
@export var gravity = 30
@export var jump_force = 300
@export var health = 100

@onready var ap = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var sprite_collision = $CollisionShape2D
@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer_timer = $JumpBufferTimer
@onready var jump_height_timer = $JumpHeightTimer
@onready var attack_buffer_timer = $AttackBufferTimer

var can_coyote_jump = false
var jump_buffered = false
var attack_buffered = false

# Is player dead
var is_dead = false

# Directon player is currently facing
var player_direction = 1

func _input(event):
	if event.is_action_pressed("jump"):
		jump_height_timer.start()
		jump()

func _physics_process(_delta):
	var is_initiating_jump = is_on_floor() && Input.is_action_pressed("jump")
	#var is_attacking = is_on_floor() && Input.is_action_pressed("attack")
	
	if !is_on_floor():
		velocity.y += gravity
		if velocity.y > 1000:
			velocity.y = 1000
	
	var h_direction = Input.get_axis("move_left", "move_right")
	velocity.x = h_direction * speed
	
	if h_direction != 0:
		switch_direction(h_direction)
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	if is_on_floor() && h_direction != 0:
		state = States.RUN
	elif state == States.RUN && is_on_floor() && h_direction == 0:
		state = States.IDLE
	elif is_initiating_jump:
		state = States.JUMP
	elif state == States.JUMP && velocity.y < 0:
		state = States.LIFT
	elif velocity.y > 0:
		state = States.FALL
	elif state == States.FALL && is_on_floor():
		state = States.LAND
	
	if health == 0:
		state = States.DIE

	# Started to fall
	if was_on_floor && !is_on_floor() && velocity.y >= 0:
		can_coyote_jump = true
		coyote_timer.start()

	# Touched ground
	if !was_on_floor && is_on_floor():
		if jump_buffered:
			jump_buffered = false
			jump()
	
	# Attack
	if Input.is_action_just_pressed("attack"):
		attack()
		var nut = nut_scene.instantiate()
		nut.player = self
		nut.position = self.position + Vector2(64, 0)
		nut.direction = Vector2(player_direction, 0)
		get_parent().add_child(nut)
	
	# Gets hit
	var enemy = get_parent().get_tree().get_nodes_in_group("enemies")
	# Restart when dead or fall into restart zone
	var restart = get_parent().get_tree().get_nodes_in_group("restartZones")
	
	for j in get_slide_collision_count():
		var collision = get_slide_collision(j)
		
		for i in enemy.size():
			if !is_dead:

				if collision.get_collider().name == enemy[i].name:
					if health > 0:
						ap.play("receiveDamage", -1, 2)
						health -= enemy[i].damage
						print(health)
			
func set_state(new_state):
	#var previous_state := state
	state = new_state
	
	if state == States.IDLE:
		ap.play("idle", -1, 0.75)
	elif state == States.RUN:
		ap.play("run", -1, 2)
	elif state == States.JUMP:
		ap.play("jumpStart", -1, 2)
	elif state == States.LIFT:
		ap.play("jump")
	elif state == States.FALL:
		ap.play("fall")
	elif state == States.LAND:
		ap.play("fallEnd", -1, 2)
		ap.queue("idle")
	
	if state == States.DIE:
		set_physics_process(false)
		ap.play("die")
		await ap.animation_finished
		get_tree().reload_current_scene()

func attack():
	attack_buffer_timer.start()
	ap.play("attack", -1, 3)
	ap.queue("idle")

func jump():
	if is_on_floor() || can_coyote_jump:
		velocity.y = -jump_force
		if can_coyote_jump:
			can_coyote_jump = false
	else:
		if !jump_buffered:
			jump_buffered = true
			jump_buffer_timer.start()

func _on_coyote_timer_timeout():
	can_coyote_jump = false

func _on_jump_buffer_timer_timeout():
	jump_buffered = false

func _on_jump_height_timer_timeout():
	if !Input.is_action_pressed("jump"):
		if velocity.y < -100:
			velocity.y = -100
	else:
		pass

func _on_attack_buffer_timer_timeout():
	attack_buffered = false

func switch_direction(h_direction):
	sprite.flip_h = (h_direction == -1)
	sprite_collision.position.x = h_direction * 14
	player_direction = h_direction

func _on_animation_player_animation_finished(_anim_name):
	pass

func _on_restart_zone_body_entered(body):
	if body == self:
		get_tree().reload_current_scene()
