extends CanvasLayer

enum State { COMBAT_PLAYER, COMBAT_ENEMY, SHOP }
var current_state: State = State.COMBAT_PLAYER
var current_round: int = 1

# --- UI NODES ---
@onready var status_label: Label = $StatusLabel
@onready var attack_btn: Button = $HBoxContainer/AttackButton
@onready var heal_btn: Button = $HBoxContainer/HealButton
@onready var sell_btn: Button = $HBoxContainer/SellButton
@onready var sell_tome_btn: Button = $HBoxContainer/SellTomeButton
@onready var sell_junk_btn: Button = $HBoxContainer/SellJunkButton
@onready var continue_btn: Button = $HBoxContainer/ContinueButton
@onready var player_hp_bar: ProgressBar = $PlayerHealthBar
@onready var enemy_hp_bar: ProgressBar = $EnemyHealthBar
@onready var upg_attack_btn: Button = $HBoxContainer/UpgradeAttackButton
@onready var upg_health_btn: Button = $HBoxContainer/UpgradeHealthButton
@onready var upg_heal_btn: Button = $HBoxContainer/UpgradeHealButton

# --- FIGHTERS ---
@onready var player = $Player
@onready var enemy = $Enemy

func _ready() -> void:
	# Connect combat buttons
	attack_btn.pressed.connect(_on_attack_pressed)
	heal_btn.pressed.connect(_on_heal_pressed)
	
	# Connect shop buttons
	sell_btn.pressed.connect(func(): _sell_item("health_potion"))
	sell_tome_btn.pressed.connect(func(): _sell_item("fireball_tome"))
	sell_junk_btn.pressed.connect(func(): _sell_item("junk"))
	
	# Shop Purchases
	upg_attack_btn.pressed.connect(_on_buy_attack)
	upg_health_btn.pressed.connect(_on_buy_health)
	upg_heal_btn.pressed.connect(_on_buy_heal)
	
	continue_btn.pressed.connect(_on_continue_pressed)
	
	start_combat_round()

# ==========================================
# UI VISIBILITY CONTROLLERS
# ==========================================

func show_combat_ui() -> void:
	# Show combat buttons
	attack_btn.visible = true
	heal_btn.visible = true
	
	# Hide shop buttons
	sell_btn.visible = false
	sell_tome_btn.visible = false
	sell_junk_btn.visible = false
	upg_attack_btn.visible = false
	upg_health_btn.visible = false
	continue_btn.visible = false
	
	# Show the health bars and characters
	player_hp_bar.visible = true
	enemy_hp_bar.visible = true
	player.visible = true
	enemy.visible = true

func show_shop_ui() -> void:
	# Hide combat buttons
	attack_btn.visible = false
	heal_btn.visible = false
	
	# Show shop buttons
	sell_btn.visible = true
	sell_tome_btn.visible = true
	sell_junk_btn.visible = true
	upg_attack_btn.visible = true
	upg_health_btn.visible = true
	continue_btn.visible = true
	
	# Hide the health bars and characters so the shop is clean
	player_hp_bar.visible = false
	enemy_hp_bar.visible = false
	player.visible = false
	enemy.visible = false

# ==========================================
# COMBAT FLOW
# ==========================================

func start_combat_round() -> void:
	current_state = State.COMBAT_PLAYER
	show_combat_ui()
	attack_btn.disabled = false
	heal_btn.disabled = false
	
	if current_round == 6:
		start_boss_fight()
	else:
		# Configure standard enemy
		enemy.max_hp = 30 + (current_round * 10)
		enemy.hp = enemy.max_hp
		enemy.attack_power = 6 + (current_round * 2)
		update_combat_ui("Your turn!")

func _on_attack_pressed() -> void:
	enemy.take_damage(player.attack_power)
	
	if not enemy.is_alive():
		if current_round == 6:
			status_label.text = "VICTORY! You defeated the Merchant Boss!"
			attack_btn.disabled = true
			heal_btn.disabled = true
		else:
			# Enemy defeated! Trigger Merchant encounter
			open_merchant_shop()
	else:
		start_enemy_turn()

func _on_heal_pressed() -> void:
	player.heal(25)
	start_enemy_turn()

func start_enemy_turn() -> void:
	current_state = State.COMBAT_ENEMY
	attack_btn.disabled = true
	heal_btn.disabled = true
	
	if current_round == 6:
		run_merchant_boss_turn()
	else:
		player.take_damage(enemy.attack_power)
		update_combat_ui("Enemy attacked you!")
		
		if not player.is_alive():
			status_label.text = "GAME OVER: You were defeated in battle."
		else:
			current_state = State.COMBAT_PLAYER
			attack_btn.disabled = false
			heal_btn.disabled = false

# ==========================================
# SHOP PHASE (Between Waves)
# ==========================================

func open_merchant_shop() -> void:
	current_state = State.SHOP
	show_shop_ui()
	status_label.text = "Wave " + str(current_round) + " Cleared! Merchant: 'Interested in selling any goods before your next fight?'"

func _sell_item(item_id: String) -> void:
	GameState.merchant_inventory[item_id] = GameState.merchant_inventory.get(item_id, 0) + 1
	status_label.text = "Sold 1x " + item_id + "! Merchant Inventory: " + str(GameState.merchant_inventory)

func _on_continue_pressed() -> void:
	current_round += 1
	start_combat_round()

func _on_buy_attack() -> void:
	if GameState.player_gold >= 10:
		GameState.player_gold -= 10
		player.attack_power += 5
		update_shop_ui("Upgraded Attack! Current: " + str(player.attack_power))
	else:
		update_shop_ui("Not enough gold for Attack Upgrade!")

func _on_buy_health() -> void:
	if GameState.player_gold >= 10:
		GameState.player_gold -= 10
		player.max_hp += 20
		player.heal(20) # Give them the new HP immediately
		update_shop_ui("Upgraded Max HP! Current: " + str(player.max_hp))
	else:
		update_shop_ui("Not enough gold for Health Upgrade!")

func _on_buy_heal() -> void:
	if GameState.player_gold >= 5:
		if player.hp < player.max_hp:
			GameState.player_gold -= 5
			player.heal(30)
			update_shop_ui("Healed 30 HP! Current: " + str(player.hp) + "/" + str(player.max_hp))
		else:
			update_shop_ui("Health is already full!")
	else:
		update_shop_ui("Not enough gold to Heal!")
# ==========================================
# BOSS LOGIC (Round 6)
# ==========================================

func start_boss_fight() -> void:
	enemy.max_hp = 180
	enemy.hp = enemy.max_hp
	enemy.attack_power = 12
	status_label.text = "BOSS FIGHT! The Merchant turns on you with all the items you sold!"

func run_merchant_boss_turn() -> void:
	var potions = GameState.merchant_inventory.get("health_potion", 0)
	var tomes = GameState.merchant_inventory.get("fireball_tome", 0)
	var junk = GameState.merchant_inventory.get("junk", 0)
	
	# Priority 1: Emergency heal
	if enemy.hp < (enemy.max_hp * 0.4) and potions > 0:
		GameState.merchant_inventory["health_potion"] -= 1
		enemy.heal(30)
		update_combat_ui("Merchant Boss drank a sold Potion to heal!")
	# Priority 2: Fireball
	elif tomes > 0:
		GameState.merchant_inventory["fireball_tome"] -= 1
		player.take_damage(35)
		update_combat_ui("Merchant Boss cast FIREBALL from your sold tome! (35 dmg)")
	# Priority 3: Gilgamesh Junk Barrage
	elif junk > 0:
		var barrage_dmg = junk * 6
		player.take_damage(barrage_dmg)
		GameState.merchant_inventory["junk"] = 0
		update_combat_ui("Merchant Boss launched a Gate of Babylon Junk Barrage! (" + str(barrage_dmg) + " dmg)")
	# Priority 4: Normal strike
	else:
		player.take_damage(enemy.attack_power)
		update_combat_ui("Merchant Boss attacked with his cane!")
	
	if not player.is_alive():
		status_label.text = "Defeated by your own greed against the Merchant!"
	else:
		current_state = State.COMBAT_PLAYER
		attack_btn.disabled = false
		heal_btn.disabled = false

# ==========================================
# UI HELPER
# ==========================================

func update_combat_ui(message: String) -> void:
	var prefix = "Round " + str(current_round) + "/5" if current_round <= 5 else "FINAL BOSS"
	status_label.text = prefix + " | " + message + " | Gold: " + str(GameState.player_gold)
	
	# Update Player Health Bar
	player_hp_bar.max_value = player.max_hp
	player_hp_bar.value = player.hp
	
	# Update Enemy Health Bar
	enemy_hp_bar.max_value = enemy.max_hp
	enemy_hp_bar.value = enemy.hp

func update_shop_ui(message: String) -> void:
		status_label.text = "SHOP | " + message + " | Gold: " + str(GameState.player_gold)
