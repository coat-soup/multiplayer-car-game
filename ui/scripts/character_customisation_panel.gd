extends Control
class_name CharacterCustomisationPanelManager

@export var skeleton : PlayerSkeletonController

@onready var color_picker_button: ColorPickerButton = $ColorPickerButton
@onready var hat_a: TextureButton = $HatA
@onready var hat_b: TextureButton = $HatB
@onready var hair_a: TextureButton = $HairA
@onready var hair_b: TextureButton = $HairB
@onready var face_a: TextureButton = $FaceA
@onready var face_b: TextureButton = $FaceB


func _ready() -> void:
	hat_a.pressed.connect(switch_hat.bind(-1))
	hat_b.pressed.connect(switch_hat.bind(1))
	
	hair_a.pressed.connect(switch_hair.bind(-1))
	hair_b.pressed.connect(switch_hair.bind(1))
	
	face_a.pressed.connect(switch_face.bind(-1))
	face_b.pressed.connect(switch_face.bind(1))
	
	color_picker_button.color_changed.connect(switch_colour)
	
	switch_colour(color_picker_button.color)


func switch_hat(dir : int):
	skeleton.hat_id = wrapi(skeleton.hat_id + dir, -1, skeleton.hat_holder.get_child_count())
	skeleton.update()


func switch_hair(dir : int):
	skeleton.hair_id = wrapi(skeleton.hair_id + dir, -1, skeleton.hair_holder.get_child_count())
	skeleton.update()


func switch_face(dir : int):
	skeleton.face_id = wrapi(skeleton.face_id + dir, -1, skeleton.face_holder.get_child_count())
	skeleton.update()


func switch_colour(color):
	skeleton.shirt_colour = color_picker_button.color
	skeleton.update()
