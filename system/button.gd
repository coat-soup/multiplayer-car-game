extends Interactable

@export var target_node : Node
@export var function_name : String
@export var arguments : String

var callable : Callable

@onready var anim : AnimationPlayer = get_node_or_null("button/AnimationPlayer") as AnimationPlayer


func _ready() -> void:
	interacted.connect(activate_button)
	callable = Callable(target_node, function_name)


func activate_button(_source):
	activate_button_rpc.rpc()


@rpc("any_peer", "call_local")
func activate_button_rpc():
	callable.call(arguments)
	if anim: anim.play("trigger")
