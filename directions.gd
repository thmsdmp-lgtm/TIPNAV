# script for handling direction
# and tracking panel
extends Control

func _ready() -> void:
	pass

func open(place_name:String,from_place_name:String):
	if not place_name: return
