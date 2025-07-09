extends Resource
class_name PowerSystem

signal capacitors_changed
signal powered_on
signal powered_off


@export var system_name : String
@export var icon : Texture2D
@export var max_capacitors : int = 1
@export var min_capacitors_for_power : int = 1

var assigned_capacitors : int = 0
