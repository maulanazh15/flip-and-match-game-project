extends Control

var gameManagerPacked 
var gameManagerUnpacked




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_game() -> void: 
	gameManagerPacked = preload("res://scenes/GameManagerAPI.tscn")	
	gameManagerUnpacked = gameManagerPacked.instantiate()
	$EasyBtn.visible = false
	$NormalBtn.visible = false
	$HardBtn.visible = false
	$BackBtn.visible = false
	add_child(gameManagerUnpacked)
	

func _on_easy_btn_pressed() -> void:
	Global.difficulty = "easy"
	start_game()


func _on_normal_btn_pressed() -> void:
	Global.difficulty = "normal"
	start_game()

func _on_hard_btn_pressed() -> void:
	Global.difficulty = "hard"
	start_game()

func _on_back_btn_pressed() -> void:
	get_tree().reload_current_scene()

	