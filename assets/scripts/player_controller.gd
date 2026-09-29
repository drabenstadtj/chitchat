extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 7.0
@export var walk_fov := 75.0
@export var sprint_fov := 90.0
@export var fov_change_speed := 8.0
@export var acceleration := 40.0
@export var friction := 50.0
@export var air_control := 0.3
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.003
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var chat_bubble: Label3D = $ChatBubble
@onready var hud = $HUD

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var bubble_id := 0
var chatting := false

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	chat_bubble.hide()
	Network.message_received.connect(_on_message_received)

	if not is_multiplayer_authority():
		camera.current = false
		hud.queue_free()
		return

	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.chat_toggled.connect(func(open): chatting = open)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	
	# Gravity and coyote time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		velocity += get_gravity() * delta
		coyote_timer -= delta

	# Jump buffering
	if not chatting and Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0

	# Variable jump height: release early for a shorter jump
	if not chatting and Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= 0.5

	# Movement with acceleration and friction
	var input_dir := Vector2.ZERO if chatting else Input.get_vector("left", "right", "forward", "back")
	var is_sprinting := not chatting and Input.is_action_pressed("sprint") and input_dir.y < 0
	var speed := sprint_speed if is_sprinting else walk_speed
	var target_fov := sprint_fov if is_sprinting else walk_fov
	camera.fov = lerp(camera.fov, target_fov, fov_change_speed * delta)

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var control := 1.0 if is_on_floor() else air_control
	var horizontal := Vector3(velocity.x, 0, velocity.z)

	if direction:
		horizontal = horizontal.move_toward(direction * speed, acceleration * control * delta)
	else:
		horizontal = horizontal.move_toward(Vector3.ZERO, friction * control * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event.is_action_pressed("chat") and not chatting:
		hud.open_chat()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and not chatting and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _on_message_received(sender_id: int, text: String):
	if sender_id != name.to_int() or is_multiplayer_authority():
		return
	chat_bubble.text = text
	chat_bubble.show()
	bubble_id += 1
	var my_id = bubble_id
	await get_tree().create_timer(5.0).timeout
	if my_id == bubble_id:
		chat_bubble.hide()
