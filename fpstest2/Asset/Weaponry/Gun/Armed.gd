extends Weapon
class_name Armed

@export_group("Weapon Pickup Refereneces")
# Rigidbody Version
@export var weapon_pickup : PackedScene

# References
var animation_player

# Weapon States
var is_firing = false
var is_reloading = false

@export_group("Weapon Stats")
# Weapon Parameters
@export var ammo_in_mag = 15
@export var extra_ammo = 30
@onready var mag_size = ammo_in_mag

@export var damage = 10
@export var fire_rate = 1.0

@export_group("Weapon Positions and Speed")
# The offset of the weapon from the camera
@export var equip_pos = Vector3.ZERO

# Effects
@export var impact_effect : PackedScene
@export var muzzle_flash_path : NodePath
@onready var muzzle_flash = get_node(muzzle_flash_path)

# Optional
@export var equip_speed = 1.0
@export var unequip_speed = 1.0
@export var reload_speed = 1.0

# Sway
var sway_pivot = null

# ADS
@export var ads_pos = Vector3.ZERO
@export var canted_pos = Vector3.ZERO
@export var canted_rot = rotation
@onready var og_rot = rotation
var ads_speed = 10
var is_ads = false
var is_canted = false

# bolt
@export var need_bolt_lock : bool


func _ready():
	pass

func _process(delta):
	pass

# Fire Cycle
func fire():
	if !is_reloading and is_equipped:
		if ammo_in_mag > 0:
			if not is_firing:
				is_firing = true
				animation_player.get_animation("Fire").loop_mode = Animation.LOOP_LINEAR
				animation_player.play("Fire", -1.0, fire_rate)
			
			return
		
		elif is_firing:
			fire_stop()
			

func fire_stop():
	is_firing = false
	animation_player.get_animation("Fire").loop_mode = Animation.LOOP_NONE


func fire_bullet():  # Will be called from the animation track
	update_ammo("consume")  

	if ammo_in_mag == 0 and need_bolt_lock:
		animation_player.get_animation("Fire").track_set_enabled(0, false)
		
	for flash in muzzle_flash.get_children():
		flash.emitting = true

	ray.force_raycast_update()

	if ray.is_colliding():
		var impact = Global.instantiate_node(impact_effect, ray.get_collision_point())
		for im in impact.get_children():
			print(ray.get_collision_normal())
			im.look_at(ray.get_collision_point() + ray.get_collision_normal(), Vector3.UP)
			im.look_at(ray.get_collision_point() + ray.get_collision_normal(), Vector3.RIGHT)
			
			im.emitting = true

# Reload
func reload():
	if ammo_in_mag < mag_size and extra_ammo > 0:
		is_firing = false
		
		if ammo_in_mag > 0:
			animation_player.play("Reload", -1.0, reload_speed)
			is_reloading = true
		elif ammo_in_mag == 0:
			animation_player.play("Empty Reload", -1.0, reload_speed)
			is_reloading = true
			
		var currentAnim = animation_player.current_animation
			
		if need_bolt_lock:
			animation_player.get_animation("Fire").track_set_enabled(0, true)


# Equip/Unequip Cycle
func equip():
	animation_player.play("Equip", -1.0, equip_speed)
	is_reloading = false

func unequip():
	animation_player.play("Unequip", -1.0, unequip_speed)

func is_equip_finished():
	if is_equipped:
		return true
	else:
		return false

func is_unequip_finished():
	if is_equipped:
		return false
	else:
		return true



# Show/Hide Weapon
func show_weapon():
	visible = true
	

func hide_weapon():
	visible = false



# Animation Finished
func on_animation_finish(anim_name):
	match anim_name:
		"Unequip":
			is_equipped = false
		"Equip":
			is_equipped = true
		"Reload":
			is_reloading = false
			update_ammo("reload")
		"Empty Reload":
			is_reloading = false
			update_ammo("reload")



# Update Ammo
func update_ammo(action = "Refresh", additional_ammo = 0):
	
	match action:
		"consume":
			ammo_in_mag -= 1
			
			if ammo_in_mag < 0:
				ammo_in_mag = 0
		
		"reload":
			var ammo_needed = mag_size - ammo_in_mag
			
			if extra_ammo > ammo_needed:
				ammo_in_mag = mag_size
				extra_ammo -= ammo_needed
			else:
				ammo_in_mag += extra_ammo
				extra_ammo = 0
		
		"add":
			extra_ammo += additional_ammo
	
	
	var weapon_data = {
		"Name" : weapon_name,
		"Image" : weapon_image,
		"Ammo" : str(ammo_in_mag),
		"ExtraAmmo" : str(extra_ammo)
	}
	
	weapon_manager.update_hud(weapon_data)



# Drops weapon on the ground, by instancing weapon_pickup, and removing itself from the tree
func drop_weapon():
	var pickup = Global.instantiate_node(weapon_pickup, global_transform.origin - player.global_transform.basis.z.normalized())
	pickup.ammo_in_mag = ammo_in_mag
	pickup.extra_ammo = extra_ammo
	pickup.mag_size = mag_size
	
	queue_free()


# ADS by interpolating/lerping Sway Pivot and Camera's FOV towards a certain value
func aim_down_sights(value, delta):
	is_ads = value
	
	if is_ads and !is_reloading:
		if !is_canted:
			transform.origin = transform.origin.lerp(ads_pos, ads_speed * delta)
			rotation = rotation.lerp(og_rot, ads_speed * delta)
			#player.camera.fov = lerp(player.camera.fov, 50, ads_speed * delta)
		else:
			transform.origin = transform.origin.lerp(canted_pos, ads_speed * delta)
			rotation = rotation.lerp(canted_rot, ads_speed * delta)
			#player.camera.fov = lerp(player.camera.fov, 50, ads_speed * delta)
	else:
		transform.origin = transform.origin.lerp(equip_pos, ads_speed * delta)
		rotation = rotation.lerp(og_rot, ads_speed * delta)
		#player.camera.fov = lerp(player.camera.fov, 70, ads_speed * delta)
		
	return true

func checkCanted():
	is_canted = !is_canted
