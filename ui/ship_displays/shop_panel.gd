extends Control

@onready var grid_container: GridContainer = $GridContainer
@onready var money_label: Label = $MoneyLabel

@export var item_spawn_point : Node3D

var items : Array[ItemData]


func _ready() -> void:
	rebuild()
	Global.game_manager.money_changed.connect(on_money_changed)


func rebuild():
	on_money_changed()
	items.clear()
	
	for child in grid_container.get_children():
		child.queue_free()
	
	var data_paths = Util.get_files_in_folder("res://items/item_data/", "tres")
	
	for i in range(len(data_paths)):
		var item_data = load(data_paths[i]) as ItemData
		items.append(item_data)
		var entry = preload("res://ui/widgets/shop_entry.tscn").instantiate()
		grid_container.add_child(entry)
		entry.get_child(1).text = item_data.item_name
		entry.get_child(2).text = "$%d" % item_data.price
		entry.get_child(3).text = "STOCK: %d" % 100
		(entry.get_child(4) as Button).pressed.connect(buy_item.bind(i))



func buy_item(index: int):
	if Global.game_manager.money < items[index].price:
		Global.game_manager.ui.display_prompt("Not enough money")
		return
	
	Global.level_manager.spawn_item_synced.rpc_id(1, items[index].prefab_path, item_spawn_point.global_position)
	Global.game_manager.request_change_money.rpc(-items[index].price)


func on_money_changed():
	money_label.text = "Funds: $%d" % Global.game_manager.money
