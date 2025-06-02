extends Interactable

@export var target_node : Node
@export var function_name : String
@export var arguments : String

var callable : Callable


func _ready() -> void:
	interacted.connect(activate_button)
	callable = Callable(target_node, function_name)


func activate_button(source):
	callable.call(arguments)
