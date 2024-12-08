extends Node

var difficulty_levels = {
	"easy": {
		"time_left": 120,      # Ample time
		"bonus_time": 20,      # Generous bonus for matches
		"penalty_time": 3,     # Small penalty for mismatches
		"flip_limit": 40,      # High limit for experimentation
		"bonus_flip": 5,       # Generous flip bonus
	},
	"normal": {
		"time_left": 90,       # Moderate time pressure
		"bonus_time": 10,      # Reasonable bonus for matches
		"penalty_time": 7,     # Noticeable penalty
		"flip_limit": 25,      # Balanced flip limit
		"bonus_flip": 3,       # Moderate flip bonus
	},
	"hard": {
		"time_left": 60,       # Minimal time
		"bonus_time": 5,       # Small reward for matches
		"penalty_time": 10,    # Severe penalty
		"flip_limit": 15,      # Very restrictive flip limit
		"bonus_flip": 2,       # Minimal flip bonus
	}
}


var difficulty = "easy"
var level = 1  # Default starting level
var score = 0
var total_pairs = 0
var total_cards = 0
var check_mathced = false
var max_grid_col = 6
var max_grid_row = 3

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
			
