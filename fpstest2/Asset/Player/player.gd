extends CharacterBody3D

#References
@onready var neck = $Neck
@onready var head = $Neck/Head
@onready var eye = $Neck/Head/Eye
@onready var cam = $"Neck/Head/Eye/First Person Camera"
@onready var headDetect = $HeadDetect
@onready var pcap = $CollisionShape3D
@onready var chestRay = $Rays/chestRay
@onready var headRay = $Rays/headRay
@onready var gunCam = $"Control/SubViewportContainer/SubViewport/Gun Camera"
@onready var weaponManager = $"Control/SubViewportContainer/SubViewport/Gun Camera/weaponManager"
@onready var flashlight = $Neck/Head/SpotLight3D
@onready var crosshair = $Control/Crosshair

#Movement variables
var currentSpeed
const walkingSpeed = 4.5
const sprintSpeed = 7.0
const crouchSpeed = 2.5
const jumpForce = 4.5

#Mouse sensitivity
const mouse_sens = 0.2

# Movement lerp var
var lerp_speed = 5
var air_lerp_speed = 2.5
var changeSpeed = 5
var direction = Vector3.ZERO
var fl_tilt_amount = 5

# Head bumping dection states
var headDetected

#Slide variables
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10

#Headbobbing vars
const headbob_sprint_speed = 22.0
const headbob_walk_speed = 14.0
const headbob_crouch_speed = 10.0
const headbob_ads_speed = 12.0

const headbob_sprint_intens = 0.1
const headbob_walk_intens = 0.05
const headbob_crouch_intens = 0.0
const headbob_ads_intens = 0.02

var headbob_vector = Vector2.ZERO
var headbob_index = 0.0
var headbob_current_index = 0.0

# States
var walking = false
var crouching = false
var sprinting = false
var freelooking = false
var sliding = false
var can_jump := true
var camera_can_move := true
var is_ads := false

@onready var standHeight = pcap.shape.height
@onready var crouchHeight = standHeight - 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	flashlight.visible = false
	currentSpeed = walkingSpeed
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			if freelooking:
				neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
				neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-75), deg_to_rad(75))
			else:
				rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
			
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = !flashlight.visible		
		
	if Input.is_action_pressed("ads"):
		is_ads = true
	else:
		is_ads = false

func _physics_process(delta):
	_movement(delta)
	headDetection()
	process_camera(delta)

func headDetection():
	# Head Detection
		headDetected = false
			
		if headDetect.is_colliding():
			headDetected = true

func _movement(delta):
	#Getting movement inputs
	var input_dir = Input.get_vector("left", "right", "forward", "back")

	# Handle collision shape
	if Input.is_action_pressed("crouch") or sliding:
		pcap.shape.height -= changeSpeed * delta
	elif not headDetected:
		pcap.shape.height += changeSpeed * delta

	pcap.shape.height = clamp(pcap.shape.height, crouchHeight, standHeight)

	#Handle movement speed and states
	if Input.is_action_pressed("crouch") or (pcap.shape.height < standHeight):
		currentSpeed = lerp(currentSpeed, crouchSpeed, lerp_speed * delta) 
		
		#Slide logic
		if sprinting and input_dir != Vector2.ZERO and is_on_floor():
			sliding = true
			freelooking = true
			slide_timer = slide_timer_max
			slide_vector = input_dir

		crouching = true
		walking = false
		sprinting = false

	elif not headDetected:
		if Input.is_action_pressed("sprint"):
			currentSpeed = lerp(currentSpeed, sprintSpeed, lerp_speed * delta) 

			crouching = false
			walking = false
			sprinting = true
		else:
			currentSpeed = lerp(currentSpeed, walkingSpeed, lerp_speed * delta) 

			crouching = false
			walking = true
			sprinting = false

	else:
		crouching = false
		walking = false
		sprinting = false
	
	#Handle free looking
	if Input.is_action_pressed("freelook") or sliding:
		freelooking = true
		if sliding:
			cam.rotation.z = lerp(cam.rotation.z, -deg_to_rad(2.0), lerp_speed * delta)
		else:
			cam.rotation.z = -deg_to_rad(neck.rotation.y * fl_tilt_amount)
			
		
	else: 
		freelooking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		cam.rotation.z = lerp(cam.rotation.z, 0.0, delta * lerp_speed)

	#Handle weapon weapon cam
	if !is_ads:
		gunCam.global_transform = cam.global_transform
		weaponManager.global_position = head.global_position + Vector3(0.0, -0.15, 0.0)
	else: 
		gunCam.global_transform = cam.global_transform
		weaponManager.global_position = head.global_position
		
	
	#Handle sliding
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0.05:
			sliding = false
			freelooking = false

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and can_jump:
		velocity.y = jumpForce
		sliding = false
	elif Input.is_action_just_pressed("ui_accept") and can_climb() and can_jump:
		climb()
		sliding = false

	#Headbob
	if sprinting:
		headbob_current_index = headbob_sprint_intens
		headbob_index += headbob_sprint_speed * delta
	elif crouching:
		headbob_current_index = headbob_crouch_intens
		headbob_index += headbob_crouch_speed * delta
	elif is_ads:
		headbob_current_index = headbob_ads_intens
		headbob_index += headbob_ads_speed * delta
	elif walking and !is_ads:
		headbob_current_index = headbob_walk_intens
		headbob_index += headbob_walk_speed * delta
	
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		headbob_vector.y = sin(headbob_index)
		headbob_vector.x = sin(headbob_index/2)

		eye.position.y = lerp(eye.position.y, headbob_vector.y * (headbob_current_index / 2.0), lerp_speed * delta)
		eye.position.x = lerp(eye.position.x, headbob_vector.x * (headbob_current_index), lerp_speed * delta)
	else:
		eye.position.y = lerp(eye.position.y, 0.0, lerp_speed * delta)
		eye.position.x = lerp(eye.position.x, 0.0, lerp_speed * delta)
		
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_lerp_speed)

	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		currentSpeed = (slide_timer + 0.1) * slide_speed
		

	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
			
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()

#Handle climbing
func climb():
	velocity = Vector3.ZERO
	can_jump = false
	camera_can_move = false
	freelooking = false
	
	var v_move_time = 0.4
	var h_move_time = 0.2
	if !crouching:
		#Vert Trans
		var vert_movement = global_transform.origin + Vector3(0, 1.05, 0)
		var vm_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		var camera_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		
		vm_tween.tween_property(self, "global_transform:origin", vert_movement, v_move_time)
		camera_tween.tween_property(cam, "rotation_degrees:x", clamp(cam.rotation_degrees.x - 20.0, -85, 90), v_move_time)
		camera_tween.tween_property(cam, "rotation_degrees:z", -5.0 * sign(randf_range(-10000, 10000)), v_move_time)
		
		await vm_tween.finished
		
		#Hozi Trans
		var forw_movement = global_transform.origin + (-global_transform.basis.z * 0.7)
		var fn_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
		var camera_reset = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		fn_tween.tween_property(self, "global_transform:origin", forw_movement, h_move_time)
		camera_reset.tween_property(cam, "rotation_degrees:x", 0.0, h_move_time)
		camera_reset.tween_property(cam, "rotation_degrees:z", 0.0, h_move_time)
	can_jump = true
	camera_can_move = true

func can_climb():
	if !chestRay.is_colliding():
		return false
	for ray in headRay.get_children():
		if ray.is_colliding():
			return false
		return true

func process_camera(delta):
	if is_ads:
		weaponManager.current_weapon.aim_down_sights(true, delta)
		if weaponManager.current_weapon_slot != "Empty":
			crosshair.visible = false
	elif !is_ads:
		weaponManager.current_weapon.aim_down_sights(false, delta)
		crosshair.visible = true
		
	if Input.is_action_pressed("fire"):
		weaponManager.current_weapon.fire()
	if Input.is_action_just_released("fire"):
		weaponManager.current_weapon.fire_stop()
