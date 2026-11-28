# script for root of the scene
extends Node

# initialize stuff
func _ready() -> void:
	var path_material = ShaderMaterial.new()
	path_material.shader = load("res://assets/shaders/path.gdshader")
	PathManager.initialize(%capsule,%path,path_material)
	
	PathManager.set_path(Vector3(-18,0,-20))
