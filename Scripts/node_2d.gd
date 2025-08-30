extends Node

# Path to your BalletMoveDatabase resource
@export var database_path: String = "res://Definition Resources/ballet_moves_database.tres"

func _ready():
	# Load the database
	var database = load(database_path)
	
	# Check if it loaded
	if database == null:
		print("Failed to load database!")
		return
	
	# Check the moves array
	if database.moves.size() == 0:
		print("Database loaded but moves array is empty!")
		return
	
	# Iterate and print moves
	for move in database.moves:
		print("Move:", move.name, "| Definition:", move.definition)
