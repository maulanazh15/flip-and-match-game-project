extends Node2D

@export var card_face: Texture

var card_name
signal card_flipped(card)  # Signal for card flipping

var is_flipped = false
@export var base_size: Vector2 = Vector2(300, 450)  # Base card size
@export var min_size: Vector2 = Vector2(160, 180)  # Minimum card size
var level = Global.level  # Current game level
var max_cards_per_row = Global.total_pairs # Maximum cards per row in the grid

func _ready():
	# Adjust card size based on level
	adjust_card_size()
	
	# Set textures for CardBack and CardFace
	$CardBack.texture = preload("res://sprites/yugioh-card-back.png")
	$CardFace.texture = card_face if card_face else preload("res://sprites/skull-crossed-bones.png")
	
	# Hide the card face initially
	$CardFace.visible = true
	await get_tree().create_timer(1.0).timeout
	$CardFace.visible = false
	
	# Connect the `gui_input` signal of CardBack
	$CardBack.connect("gui_input", Callable(self, "_on_card_clicked"))

#func adjust_card_size():
	## Calculate total cards for the current level
	##var total_cards = max_cards_per_row * (level + 1)
	#var total_cards = max_cards_per_row
	  ## Example logic for card count increase
	#var grid_width = max_cards_per_row
	#var grid_height = ceil(total_cards / max_cards_per_row)
#
	## Calculate available size for each card
	#var available_width = get_viewport_rect().size.x / grid_width
	#var available_height = get_viewport_rect().size.y / grid_height
#
	## Determine new card size, limited by base_size and min_size
	#var new_width = min(base_size.x, max(min_size.x, available_width))
	#var new_height = min(base_size.y, max(min_size.y, available_height))
	#var new_size = Vector2(new_width, new_height)
	#
	## Scale CardBack and CardFace to match the new size
	#$CardBack.scale = Vector2(new_size.x / $CardBack.texture.get_size().x, new_size.y / $CardBack.texture.get_size().y)
	#$CardFace.scale = Vector2(new_size.x / $CardFace.texture.get_size().x, new_size.y / $CardFace.texture.get_size().y)
func adjust_card_size():
	# Define threshold area dimensions (e.g., max playable width and height)
	var max_playable_width = 1440  # Maximum width of the area
	var max_playable_height = 835  # Maximum height of the area
	# Calculate grid dimensions based on current level or setup
	var total_cards = max_cards_per_row * (level + 1)
	#var total_cards = max_cards_per_row * Global.grid_rows  # Adjust for total cards and grid rows/columns
	var grid_width = max_cards_per_row
	var grid_height = ceil(total_cards / float(max_cards_per_row))
	
	# Calculate available size for each card based on the thresholds	
	var available_width = min(get_viewport_rect().size.x, max_playable_width) / grid_width
	var available_height = min(get_viewport_rect().size.y, max_playable_height) / grid_height
	
	# Determine new card size, ensuring it remains within defined constraints
	var new_width = min(base_size.x, max(min_size.x, available_width))
	var new_height = min(base_size.y, max(min_size.y, available_height))
	var new_size = Vector2(new_width, new_height)
	# Update card scales for CardBack and CardFace
	$CardBack.scale = Vector2(
		new_size.x / $CardBack.texture.get_size().x,
		new_size.y / $CardBack.texture.get_size().y)
	$CardFace.scale = Vector2(
		new_size.x / $CardFace.texture.get_size().x,
		new_size.y / $CardFace.texture.get_size().y)
	print("Card size adjusted: ", new_size)
	
func flip_card():
	$CardFlipSound.play()
	if not is_flipped:
		$AnimationPlayer.play("flip_face")
		$CardBack.visible = false  # Hide the back texture
		$CardFace.visible = true  # Show the face texture
		is_flipped = true
	else:
		$AnimationPlayer.play("flip_back")
		$CardBack.visible = true  # Show the back texture
		$CardFace.visible = false  # Hide the face texture
		is_flipped = false

func _on_card_clicked(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and not Global.check_mathced:
		emit_signal("card_flipped", self)  # Emit the signal
		flip_card()  # Perform the flip
