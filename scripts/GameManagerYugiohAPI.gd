extends Node2D

var http_request: HTTPRequest
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
var time_left = 60  # Time limit for the level in seconds
var timer
var unmatched_cards = 0
var time_bonus = 0
var max_grid_col = Global.max_grid_col
var card_spawned = false


func _ready():
	$LoadingScreen.visible = true
	timer = $LevelTimer
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	
	default_image = preload("res://sprites/dandelion-flower.png")
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))
	#prepare_next_level()
	fetch_card_data()
	
func _on_timer_timeout():
	print("Time's up!")
	end_level()  # Define logic for ending the level
	
func prepare_next_level():
	$LoadingScreen.text = "LOADING CARDS ..."
	total_pairs = base_cards / 2 + (level - 1)
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
	var card_count = base_cards + (level - 1) * 2  # Total cards for this level
	#$LoadingScreen.visible = true
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
	var max_x_threshold = 1440  # Adjust based on your scene's dimensions
	var max_y_threshold = 835
	# Adjust multipliers based on the total card count
	var x_multiplier = lerp(300, 150, clamp(float(card_count) / (grid_columns * grid_rows), 0.0, 1.0))
	var y_multiplier = lerp(400, 200, clamp(float(card_count) / (grid_columns * grid_rows), 0.0, 1.0))
	# Spawn the cards
	for i in range(card_count):
		var card_instance = card_scene.instantiate()
		var column = i % grid_columns
		var row = int(i / grid_columns)
		
		var x_pos = min(column * x_multiplier, max_x_threshold)
		var y_pos = min(row * y_multiplier, max_y_threshold)
		
		card_instance.position = Vector2(x_pos, y_pos)  # Adjust card position
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
	time_left = 60 + time_bonus  # Add time bonus to the base time (60 seconds)
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
		else:
			$CheckBox.text = "!="
			# Flip back if not a match after a small delay
			$WrongPairSound.play()
			time_left -= 5
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
		time_bonus = time_left
		next_level()
	
	

func check_match(card1, card2):
	return card1.card_face == card2.card_face
	
func _process(delta):
	if card_spawned and not timer.is_paused():
		time_left -= delta
		$TimerLabel.text = "Time: " + str(round(time_left)) + " s"
		if time_left <= 0:
			_on_timer_timeout()
	update_score_display()
	update_level_display()
		
func end_level():
	print("Level Over! Final Score: ", score)# Implement logic for restarting, progressing to the next level, or showing a game-over screen
	timer.stop()
	level = 1
	score = 0
	Global.level = level
	Global.score = score 
	get_tree().reload_current_scene()

func update_score_display():
	$ScoreLabel.text = "Score: " + str(score)

func update_level_display() :
	$NumberOfMatches.text = "Level : " + str(level)
func _on_BackToMenuButton_button_down():
	end_level()
