extends Node


var level = 1  # Default starting level
var score = 0
var total_pairs = 0
var check_mathced = false
var max_grid_col = 5
var max_grid_row = 4
func save_game():
	var save_data = { "level": level, "score" : score }
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	
func load_game():
	if FileAccess.file_exists("user://save_game.json"):
		var file = FileAccess.open("user://save_game.json", FileAccess.READ)
		var json = JSON.new()  # Create a JSON instance
		var save_data = json.parse(file.get_as_text())
		file.close()
		
		if save_data.error == OK:  # Check if parsing was successful
			level = save_data.result["level"]  # Use `result` to access the parsed data
			score = save_data.result["score"]  # Use `result` to access the parsed data
			
