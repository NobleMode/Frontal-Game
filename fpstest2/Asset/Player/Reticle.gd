extends CenterContainer

@export var retLines : Array[Line2D]
@export var playerController : CharacterBody3D
@export var retSpeed : float = 0.25
@export var retDist : float = 2.0
@export var dotRad : float = 1.0
@export var dotColor : Color = Color.WHITE

func _ready():
	#_draw()
	pass

func _process(_delta):
	adjustRet()

#func _draw():
	#draw_circle(Vector2.ZERO, dotRad, dotColor)

func adjustRet():
	var vel = playerController.get_real_velocity()
	var origin = Vector3.ZERO
	var pos = Vector2.ZERO
	var speed = origin.distance_to(vel)

	retLines[0].position = lerp(retLines[0].position, pos + Vector2(0, -speed * retDist), retSpeed) # top
	retLines[1].position = lerp(retLines[1].position, pos + Vector2(speed * retDist, 0), retSpeed) # right
	retLines[2].position = lerp(retLines[2].position, pos + Vector2(0, speed * retDist), retSpeed) # bottom
	retLines[3].position = lerp(retLines[3].position, pos + Vector2(-speed * retDist, 0), retSpeed) #left
