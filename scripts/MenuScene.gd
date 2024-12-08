extends Node2D

var gameManagerPacked 
var gameManagerUnpacked
var	difficultyManager = preload("res://scenes/difficulty_level.tscn") 


func _ready():
	#gameManagerPacked = preload("res://scenes/GameManager.tscn")
	gameManagerPacked = preload("res://scenes/GameManagerAPI.tscn")	
	gameManagerUnpacked = gameManagerPacked.instantiate()
	difficultyManager = difficultyManager.instantiate()
	if $MenuBackSound.playing == false :
		$MenuBackSound.play()
	


func _on_StartButton_pressed():
	if $ClickStartSound.playing == false :
		$ClickStartSound.play()
	await get_tree().create_timer(1).timeout

	get_node("StartButton").visible = false
	get_node("QuitButton").visible = false
	get_node("GameName").visible = false
	get_node("Credits").visible = false
	get_node("ClickColors").visible = false
	get_node("GrayElement").visible = false
	get_node("RedElement").visible = false
	get_node("PinkElement").visible = false
	get_node("BlueElement").visible = false
	get_node("OrangeElement").visible = false
	get_node("DarkGreenElement").visible = false
	get_node("BlacKElement").visible = false
	get_node("PurpleElement").visible = false
	add_child(difficultyManager)
	#add_child(gameManagerUnpacked)
	
	if $GameBGM.playing == false:
		$GameBGM.play()
		$MenuBackSound.stop()

func _on_QuitButton_button_down():
	get_tree().quit()
