extends Node2D

class_name PhosphorEmulation

@export var viewport_container:SubViewportContainer
@export var viewport:SubViewport

@onready var hum = $SubViewportContainer/SubViewport/CanvasLayer/ColorRect/Hum

func _ready():
	hum.play()
