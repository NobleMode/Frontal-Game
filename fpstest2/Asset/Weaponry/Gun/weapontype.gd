extends Armed

func _ready():
	animation_player = $AnimationPlayer
	animation_player.connect("animation_finished", on_animation_finish)


func on_animation_finish(anim_name):
	super.on_animation_finish(anim_name)
