extends Node2D

var http_request: HTTPRequest
var high_score = Global.high_score
var pokemon_sprites = []
var api_url = "https://db.ygoprodeck.com/api/v7/cardinfo.php?&startdate=2000-01-01&enddate=2002-08-23&dateregion=tcg"
var default_image
var level = Global.level
var available_cards
var base_cards = 6  # Jumlah kartu dasar untuk level pertama
var card_scene = preload("res://scenes/card.tscn")  # Path ke Card.tscn
var request_queue = []  # Antrian URL untuk permintaan
var fetching = false  # Status apakah permintaan sedang berlangsung
var sprites_loaded = 0  # Counter for loaded sprites
var total_pairs = Global.total_pairs
var selected_cards = []  # To track currently selected cards
var score = 0  # Player's score
var time_left = Global.difficulty_levels[Global.difficulty]["time_left"]  # Time limit for the level in seconds
var bonus_time = Global.difficulty_levels[Global.difficulty]["bonus_time"]
var penalty_time = Global.difficulty_levels[Global.difficulty]["penalty_time"]
var flips_remaining = Global.difficulty_levels[Global.difficulty]["flip_limit"]
var bonus_flip = Global.difficulty_levels[Global.difficulty]["bonus_flip"]
var time_bonus = 0
var timer
var unmatched_cards = 0
var max_grid_col = Global.max_grid_col
var max_grid_row = Global.max_grid_row
var max_allowed_cards = max_grid_col * max_grid_row
var card_spawned = false


func _ready():
	$LoadingScreen.visible = true
	$HigScoreLabel.text = "High Score : " + str(high_score)
	timer = $LevelTimer
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	default_image = preload("res://sprites/dandelion-flower.png")
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))
	#prepare_next_level()
	$Difficulty.text = Global.difficulty
	fetch_card_data()
	
func _on_timer_timeout():
	end_level()  # Define logic for ending the level
	
func prepare_next_level():
	$LoadingScreen.text = "LOADING CARDS ..."
	var max_allowed_pairs = max_allowed_cards / 2
	total_pairs = min(max_allowed_pairs, base_cards / 2 + (level - 1))
	Global.total_pairs = total_pairs
	request_queue.clear()
	pokemon_sprites.clear()
	#print('total_pairs : ', total_pairs)
	randomize()
	var selected_indices = []
	for i in range(total_pairs):
		var random_index = randi() % available_cards.size()
		while random_index in selected_indices : 
			random_index = randi() % available_cards.size()
		selected_indices.append(random_index)
	
	for index in selected_indices : 
		var card_data = available_cards[index]
		var sprite_url = card_data["card_images"][0]["image_url_small"]
		load_sprite(sprite_url)
	
	sprites_loaded = 0  # Reset sprite counter before starting requests


func fetch_card_data():
	$LoadingScreen.text = "Fetching card data..."
	http_request.request(api_url)
	
func _on_request_completed(result, response_code, headers, body):
	#fetching = false  # Reset fetching status
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		if parse_result == OK:
			available_cards = json.data["data"]
			if available_cards.size() > 0 : 
				prepare_next_level()
		else:
			print("Failed to parse JSON: ", json.error_message)
	else:
		print("Failed to fetch Pokémon data: ", response_code)


func load_sprite(url):
	var image_request = HTTPRequest.new()
	add_child(image_request)
	image_request.request(url)
	image_request.connect("request_completed", Callable(self, "_on_image_loaded"))

func _on_image_loaded(result, response_code, headers, body):
	if response_code == 200:
		var image = Image.new()
		var err = image.load_jpg_from_buffer(body)
		if err == OK:
			var texture = ImageTexture.create_from_image(image)
			if texture.get_width() > 0 and texture.get_height() > 0:
				#print("Image printed successfully")
				pokemon_sprites.append(texture)
			else:
				print("Image not loaded yet")
		else:
			print("Failed to load image")
	sprites_loaded += 1  # Increment sprite load counter

	# Check if all sprites are loaded before proceeding
	if sprites_loaded == total_pairs:
		spawn_cards()  # Proceed to spawn cards after all images are loaded

func spawn_cards():
	card_spawned = false
	
	# Calculate maximum cards allowed by grid
	var max_total_cards = max_allowed_cards
	var card_count = min(base_cards + (level - 1) * 2, max_total_cards)  # Ensure cards don't exceed grid capacity
	Global.total_cards = card_count
	
	randomize()
	var grid_columns = min(total_pairs, max_grid_col)
	var grid_rows = ceil(card_count / float(grid_columns))
	
	# Ensure there are enough sprites
	if pokemon_sprites.size() * 2 < card_count:
		print("Not enough sprites loaded yet!")
		return

	# Duplicate each sprite to create pairs
	var sprite_pool = []
	for sprite in pokemon_sprites:
		sprite_pool.append(sprite)
		sprite_pool.append(sprite)

	# Shuffle the sprite pool for randomness
	sprite_pool.shuffle()

	# Scene dimensions and gaps
	var scene_width = 1440  # Adjust based on your viewport width
	var scene_height = 835  # Adjust based on your viewport height

	# Calculate dynamic gaps
	var min_gap_x = 50  # Minimum horizontal gap
	var min_gap_y = 50  # Minimum vertical gap
	var card_width = 160  # Estimated width of a card
	var card_height = 180  # Estimated height of a card

	# Dynamic horizontal and vertical gaps
	var gap_x = max((scene_width - (grid_columns * card_width)) / (grid_columns + 1), min_gap_x)
	var gap_y = max((scene_height - (grid_rows * card_height)) / (grid_rows + 1), min_gap_y)

	# Spawn the cards with dynamic gaps
	for i in range(card_count):
		var card_instance = card_scene.instantiate()
		var column = i % grid_columns
		var row = int(i / grid_columns)
		
		# Position with dynamic gaps
		var x_pos = gap_x + column * (card_width + gap_x)
		var y_pos = gap_y + row * (card_height + gap_y)
		
		card_instance.position = Vector2(x_pos, y_pos)
		card_instance.card_face = sprite_pool.pop_back()  # Assign a sprite to the card
		card_instance.connect("card_flipped", Callable(self, "_on_card_flipped"))
		get_node("CardArea").add_child(card_instance)
		unmatched_cards += 1

	card_spawned = true
	timer.set_paused(false)
	timer.start(time_left)
	$LoadingScreen.text = ""
	print("Cards spawned for level ", level)


func next_level():
	level += 1
	Global.level = level
	# Add time bonus for the new level (reset time)
	time_bonus = time_left + bonus_time  # Add time bonus to the base time (60 seconds)
	time_left = time_bonus
	clear_cards()
	prepare_next_level()

func clear_cards():
	for child in get_children():
		if child is Node2D and child.has_method("reset_card"):
			child.queue_free()

func _on_card_flipped(card):
	$CardAttribute/CardView.texture = card.card_face
	if card in selected_cards :
	#if card in selected_cards or not allow_input or not card_spawned:
		return  # Prevent duplicate flips
		
	if flips_remaining <= 0:
		print("No more flips allowed!")
		end_level()
		return
	flips_remaining -= 1  # Decrement flip count
	selected_cards.append(card)
	if selected_cards.size() == 2:
		Global.check_mathced = true
		if check_match(selected_cards[0], selected_cards[1]):
			score += 10  # Increase score for a match
			$CheckBox.text = "="
			$MatchSound.play()
			await get_tree().create_timer(1.5).timeout
			for matched_card in selected_cards:
				matched_card.queue_free()  # Remove matched cards
			unmatched_cards -= 2
			flips_remaining += bonus_flip
			time_left += bonus_time
		else:
			$CheckBox.text = "!="
			# Flip back if not a match after a small delay
			$WrongPairSound.play()
			time_left -= penalty_time
			await get_tree().create_timer(1.0).timeout
			for unmatched_card in selected_cards:
				unmatched_card.flip_card()
		
		$CardAttribute/CardView.texture = load("res://sprites/yugioh-card-back.png")
		selected_cards.clear()
		Global.check_mathced = false
		
	
	$CheckBox.text = "?"
	if unmatched_cards == 0 : 
		timer.set_paused(true)
		await get_tree().create_timer(2.0).timeout
		next_level()
	
	

func check_match(card1, card2):
	return card1.card_face == card2.card_face
	
func _process(delta):
	if card_spawned and not timer.is_paused():
		time_left -= delta
		$TimerLabel.text = "Time Left: " + str(round(time_left)) + " s"
		$FlipRemaining.text = "Flip Remainings : " +str(flips_remaining)
		if time_left <= 0:
			_on_timer_timeout()
			
	update_score_display()
	update_level_display()
		
func end_level():
	timer.stop()
	check_high_score()
	Global.save_game()
	var gameOverScene = preload("res://game_over.tscn")
	gameOverScene = gameOverScene.instantiate()
	print("Level Over! Final Score: ", score)# Implement logic for restarting, progressing to the next level, or showing a game-over screen
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func update_score_display():
	$ScoreLabel.text = "Score: " + str(score)

func check_high_score() :
	Global.score = score
	if score >= high_score : 
		high_score = score
		Global.high_score = high_score

func update_level_display() :
	$NumberOfMatches.text = "Level : " + str(level)
	
func _on_BackToMenuButton_button_down():
	end_level()
