extends CanvasLayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	$ColorRect/CenterContainer/VBoxContainer/Reviver.pressed.connect(_on_reviver_pressed)
	$ColorRect/CenterContainer/VBoxContainer/Sair.pressed.connect(_on_sair_pressed)


func _on_reviver_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()


func _on_sair_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	queue_free()
