class_name Fighter
extends Node2D

# Stats
@export var max_hp: int = 250
@export var attack_power: int = 15
var hp: int

func _ready() -> void:
	hp = max_hp

# Core combat action
func take_damage(amount: int) -> void:
	hp -= amount
	if hp < 0:
		hp = 0
	print(name, " took ", amount, " damage! Current HP: ", hp)

func heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	print(name, " healed ", amount, " HP! Current HP: ", hp)
	
func is_alive() -> bool:
	return hp > 0
