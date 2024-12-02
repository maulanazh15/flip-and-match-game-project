extends Node2D

var http_request: HTTPRequest
var pokemon_sprites = []
var api_url = "https://pokeapi.co/api/v2/pokemon/"
var number_of_pokemon = 12  # Fetch this many Pokémon
var default_image
var pokemon_data = []
var init = false  # Moved init here for proper scope

func _ready():
	default_image = preload("res://sprites/dandelion-flower.png")
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))
	fetch_pokemon_sprites()

func fetch_pokemon_sprites():
	randomize()
	for i in range(number_of_pokemon):
		var random_pokemon_id = randi() % 898 + 1  # Random Pokémon ID (1-898)
		var url = api_url + str(random_pokemon_id)
		http_request.request(url)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		if parse_result == OK:
			var data = json.data
			var sprite_url = data["sprites"]["other"]["official-artwork"]["front_default"]
			if sprite_url:
				load_sprite(sprite_url)
		else:
			print("Failed to parse JSON: ", json.error_message)
	else:
		print("Failed to fetch Pokémon data: ", response_code)

func load_sprite(url):
	# Using an HTTPRequest to load the image
	var image_request = HTTPRequest.new()
	add_child(image_request)
	image_request.request(url)
	image_request.connect("request_completed", Callable(self, "_on_image_loaded"))

func _on_image_loaded(result, response_code, headers, body):
	if response_code == 200:
		var image = Image.new()
		var err = image.load_png_from_buffer(body)
		if err == OK:
			var texture = ImageTexture.new()
			texture.create_from_image(image)
			pokemon_sprites.append(texture)
	else:
		print("Failed to load sprite image: ", response_code)

func _shuffle_cards():
	if pokemon_sprites.size() < number_of_pokemon:
		print("Sprites are still loading!")
		return

	var all_remaining_cards = []  # Declared here for correct scope
	for i in range(1, number_of_pokemon * 2 + 1):
		all_remaining_cards.append(i)

	randomize()
	for i in range(number_of_pokemon):
		var random_card_1 = randi() % all_remaining_cards.size()
		var card_1_id = all_remaining_cards[random_card_1]
		all_remaining_cards.remove_at(random_card_1)

		var random_card_2 = randi() % all_remaining_cards.size()
		var card_2_id = all_remaining_cards[random_card_2]
		all_remaining_cards.remove_at(random_card_2)

		# Assign images to cards
		var texture = pokemon_sprites[i]
		get_node("Card" + str(card_1_id)).set("card_face", texture)
		get_node("Card" + str(card_2_id)).set("card_face", texture)

	init = true
