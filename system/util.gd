class_name Util

## Turns a list layer indices into corresponding layermask
## Eg. layer_mask([1,3]) returns 5 (101 in binary)
static func layer_mask(layers: Array) -> int:
	var mask := 0
	for layer in layers:
		mask |= (1 << (layer - 1))
	return mask

# COLLISION LAYER REPRESENTATIONS:
# 1 default
# 2 player (player should only ever have this)
# 3 interactable
# 4 vehicle component

static func get_player_from_id(id: String, source : Node) -> Node3D:
	for player in source.get_tree().get_nodes_in_group("player"):
		if player.name == id:
			return player
	return null
