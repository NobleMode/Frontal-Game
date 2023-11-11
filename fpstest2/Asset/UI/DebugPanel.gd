extends PanelContainer

var property
@onready var property_container = %VBoxContainer

var FPS: String

func _ready():
	visible = false
	add_debug_prop("FPS", FPS)

func _process(delta):
	if visible:
		FPS = "%.2f" % (1.0/delta)
		property.text = property.name + ": " + FPS

func _input(event):
	if event.is_action_pressed("debug"):
		visible = !visible

func add_debug_prop(title: String, value):
	property = Label.new()
	property_container.add_child(property)
	property.name = title
	property.text = property.name + value


