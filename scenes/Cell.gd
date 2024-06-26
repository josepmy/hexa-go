extends Node2D
class_name Cell

const COLOR_ACTIVATED = Color.BLUE
const COLOR_HIGHLIGHTED = Color.YELLOW
const COLOR_NORMAL = Color.WHITE

@export_enum ("None", "A", "B") var belongs_to: int = 0
@export_enum ("Board", "Stack", "Discard", "Hand") var type: int = 0

const TYPE_BOARD = 0
const TYPE_STACK = 1
const TYPE_DISCARD = 2
const TYPE_HAND = 3

@onready var sprite = $Sprite
@onready var area = $HexArea
@onready var deck_ui = $CenterContainer/Deck
@onready var tokens_left = $CenterContainer/Deck/TokensLeft
@onready var discard_ui = $CenterContainer/Discard


var blocked = false


func _enter_tree():
	var sprite = get_node("Sprite")
	sprite.add_to_group("belongs_to:" + str(belongs_to))


func _ready():
	global.connect("cell_selected", Callable(self, "_on_cell_selected"))
	global.connect("lock", Callable(self, "_on_lock"))
	global.connect("unlock", Callable(self, "_on_unlock"))
	if type == TYPE_STACK:
		deck_ui.show()
	elif type == TYPE_DISCARD:
		discard_ui.show()


func _on_HexArea_clicked():
	var token = get_token()
	
	if type == TYPE_STACK:
		for cell in get_tree().get_nodes_in_group("cells"):
			if (
				cell.type == TYPE_HAND and
				cell.belongs_to == self.belongs_to and
				cell.get_token() == null
			):
				var token_number = global.get_token(belongs_to)
				if token_number == null:
					# TODO: probably send a signal: no tokens available
					break
				tokens_left.text = str(len(global.TOKENS[belongs_to]))
				var new_token = load("res://scenes/Token.tscn").instantiate()
				
				new_token.initialize(belongs_to, token_number)
				add_child(new_token)
				new_token.reparent_custom(self, cell)
				new_token.deactivate()
				break
		return
	elif type == TYPE_BOARD and token and not token.is_activated():
		deactivate()
		token.activate()
		global.emit_signal("cell_selected", self)
	elif type == TYPE_HAND and token:
		global.emit_signal("cell_selected", self)
	elif type == TYPE_BOARD and is_cell_activity():
		global.emit_signal("cell_selected", self)
	elif type == TYPE_DISCARD:
		if is_cell_activity():
			global.emit_signal("cell_selected", self)
		else:
			# TODO: show discard screen
			pass


func get_token():
	for child in get_children():
		if child.name.find("Token") >= 0:
			return child
	return null


func is_activated():
	return area.input_pickable


func activate():
	area.input_pickable = true
	modulate = Color.WHITE


func deactivate(update_color=true):
	area.input_pickable = false
	if update_color:
		modulate = Color.DARK_GRAY


func _on_lock():
	var token = get_token()
	var keep_color = token and token.is_activated()
	deactivate(not keep_color)


func _on_unlock():
	activate()


func _on_cell_selected(cell):
	var token = get_token()
	
	if cell.type == TYPE_HAND:
		if type == TYPE_BOARD and get_token() != null:
			deactivate()
		if type == TYPE_HAND and self != cell:
			deactivate()
		if type == TYPE_STACK:
			deactivate()
		if type == TYPE_DISCARD and belongs_to != cell.belongs_to:
			deactivate()
	if cell.type == TYPE_DISCARD:
		if type == TYPE_HAND and token and is_activated():
			# TODO: send signal and add discarded token to the list
			token.reparent_custom(self, cell)
		if type == TYPE_BOARD and token and token.is_activated():
			token.reparent_custom(self, cell)
		activate()
	if cell.type == TYPE_BOARD:
		if type == TYPE_HAND and is_activated():
			if token and not cell.get_token():
				token.reparent_custom(self, cell)
				token.activate()
				cell.deactivate(false)
				deactivate()
			else:
				deactivate()
		elif type == TYPE_BOARD and token and token.is_activated():
			if cell.is_activated():
				token.reparent_custom(self, cell)
			cell.deactivate(false)
			activate()
		if type == TYPE_STACK:
			deactivate()
		if (
			type == TYPE_DISCARD and
			cell.get_token()
			and belongs_to != cell.get_token().belongs_to
		):
			deactivate()


func is_cell_activity():
	for cell in get_tree().get_nodes_in_group("cells"):
		if not cell.is_activated():
			return true
	return false
