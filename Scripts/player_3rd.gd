extends CharacterBody3D

@onready var camera_mount = $Camera_Mount
@onready var visuals = $Visuals

var camera_angle = 0
var SPEED = 3.0
const JUMP_VELOCITY = 4.5
var running : bool = false
var locked : bool = false

@export var sens_horizontal = 0.2
@export var sens_vertical = 0.2
@export var walking_speed = 3.0
@export var running_speed = 5.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#pass
	
func _input(event):
	if event is InputEventMouseMotion:	
		rotate_y(-deg_to_rad(event.relative.x * sens_horizontal))
		visuals.rotate_y(deg_to_rad(event.relative.x * sens_horizontal))
		#camera_mount.rotate_x(-deg_to_rad(event.relative.y * sens_vertical))
		
		var change = -event.relative.y * sens_vertical
		if change + camera_angle < 30 and change + camera_angle > -90:
			camera_mount.rotate_x(deg_to_rad(change))
			camera_angle += change

func _physics_process(delta):
	
	# if !animation_player.is_playing():
		# locked = false
	
	# Input.is_action_pressed("attack"):
		# if animation_player.current_animation != "attacking":
			# animation_player.play("attacking")
			# locked = true
	
	if Input.is_action_pressed("move_run"):
		SPEED = running_speed
		running = true
	else:
		SPEED = walking_speed
		running = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		# if animation_player.current_animation != "jump":
				# animation_player.play("jump")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if !locked:
			# if running:
				# if animation_player.current_animation != "running":
					# animation_player.play("running")
			
			# else:
				# if animation_player.current_animation != "walking":
					# animation_player.play("walking")
				
			visuals.look_at(position + direction)
		
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# if !locked:
			# if animation_player.current_animation != "idle":
				# animation_player.play("idle")
		
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if !locked:
		move_and_slide()
