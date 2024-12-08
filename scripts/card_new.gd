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
	var card_count = Global.total_cards # Total cards for this level
	var grid_columns = min(Global.total_pairs, Global.max_grid_col)
	var grid_rows = ceil(card_count / float(grid_columns))
	
	adjust_card_size(card_count, grid_columns, grid_rows)
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

func adjust_card_size(card_count: int, grid_columns: int, grid_rows: int):
	# Define threshold area dimensions
	var max_playable_width = 1440  # Maximum width of the area
	var max_playable_height = 835  # Maximum height of the area

	# Calculate dynamic gaps based on spawn_card logic
	var min_gap_x = 50  # Minimum horizontal gap
	var min_gap_y = 50  # Minimum vertical gap
	var card_width = base_size.x
	var card_height = base_size.y

	# Adjust gaps to fit the available space
	var gap_x = max((max_playable_width - (grid_columns * card_width)) / (grid_columns + 1), min_gap_x)
	var gap_y = max((max_playable_height - (grid_rows * card_height)) / (grid_rows + 1), min_gap_y)

	# Calculate available space for each card
	var available_width = (max_playable_width - (gap_x * (grid_columns + 1))) / grid_columns
	var available_height = (max_playable_height - (gap_y * (grid_rows + 1))) / grid_rows

	# Determine new card size, ensuring height > width
	var new_width = min(base_size.x, max(min_size.x, available_width))
	var new_height = max(new_width * 1.2, min(base_size.y, max(min_size.y, available_height)))  # Ensure height is 20% greater

	# Apply scaling to card elements
	var new_size = Vector2(new_width, new_height)
	$CardBack.scale = Vector2(
		new_size.x / $CardBack.texture.get_size().x,
		new_size.y / $CardBack.texture.get_size().y
	)
	$CardFace.scale = Vector2(
		new_size.x / $CardFace.texture.get_size().x,
		new_size.y / $CardFace.texture.get_size().y
	)

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
