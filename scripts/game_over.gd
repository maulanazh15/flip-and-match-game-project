extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if $MenuBackSound.playing == false :
		$MenuBackSound.play()
	$HighScore.text = "High Score : " + str(Global.high_score)
	$Score.text = "Score : " + str(Global.score)
	$Difficulty.text = "Difficulty : " + Global.difficulty


func _on_back_to_menu_button_pressed() -> void:
	Global.level = 1
	Global.score = 0
	Global.check_mathced = false
	Global.total_cards = 0
	Global.total_pairs = 0 
	get_tree().change_scene_to_file("res://scenes/MenuScene.tscn")
