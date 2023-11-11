extends Control

var weapon_ui
var health_ui
var display_ui
var slot_ui


func _enter_tree():
	weapon_ui = $AmmoCount
	health_ui = $HealthText
	display_ui = $WeaponImage
	slot_ui = $WeaponSlot


func _ready():
	pass


func update_weapon_ui(weapon_data, weapon_slot):
	slot_ui.text = weapon_slot
	display_ui.texture = weapon_data["Image"]
	
	if weapon_data["Name"] == "Knife":
		weapon_ui.text = weapon_data["Name"]
		return
	
	weapon_ui.text = weapon_data["Ammo"] + "/" + weapon_data["ExtraAmmo"]

