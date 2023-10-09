class_name N # short for NodeUtils

## This static class is a utility class for common operations you might want to perform on a node that
## aren't supported out of the box with Godot. The focus is on creating and accessing nodes based on their
## typing rather than their exact path, which is more resilient to refactoring.

## Searches up a node's parents until it finds a node of of type "type" with name "name"
##
## Params:
## - node: the node to search from
## - type: the GDscript type to search for (ex. RigidBody2D, CharacterBody2D, Control, etc)
## - name: the name of the node to search for (default: "", i.e., matches any node of correct type)
##
## Example Usage:
##
## var damage: float = 5
## 
## func _on_body_enter(body):
## 		var player: Player = N.get_ancestor(body, Player)
##    if player:
##        player.take_damage(damage)
static func get_ancestor(node: Node, type, name: String = ""):
	if not node:
		return

	if __is_correct_node(node, type, name):
		return node

	var ancestor = node.get_parent()
	while ancestor and not __is_correct_node(ancestor, type, name):
		ancestor = ancestor.get_parent()

	return ancestor

## Searches a node's immediate children for the first node of type "type"
##
## Params:
## - node: the node to search from
## - type: the GDscript type to search for (ex. RigidBody2D, CharacterBody2D, Control, etc)
##
## Example Usage:
## 
## @onready var player: Player = get_tree().get_first_node_in_group('player')
## var regen_sec: float = 5
## 
## func _physics_process(delta):
##    # looks for a player's health bar right under the player's root node.
## 		var health_bar: HealthBar = N.get_child_immediate(player, HealthBar)
##    if health_bar:
##        health_bar.recover_health(regen_sec*delta)
static func get_immediate_child(node: Node, type):
	if not node: 
		return null

	if is_instance_of(node, type):
		return node
	
	for child in node.get_children():
		if is_instance_of(node, type):
			return node

	return null

## Searches a node's children and descendants for the first node of type "type" with name "name"
##
## Params:
## - node: the node to search from
## - type: the GDscript type to search for (ex. RigidBody2D, CharacterBody2D, Control, etc)
## - name: the name of the node to search for (default: "", i.e., matches any node of correct type)
##
## Example Usage:
##
## extends CharacterBody2D
## class_name Player
##
## @onready animator: AnimatedSprite2D = N.get_child(self, AnimatedSprite2D)
## func _ready():
##     animator.play('idle')
##
static func get_child(node: Node, type, name: String = ""):
	if not node:
		return null
	
	if __is_correct_node(node, type, name):
		return node
  
	for child in node.get_children():
		var result = get_child(child, type, name)
		if result:
			return result

	return null

## Searches a node's children and descendats for the all nodes of type "type"
##
## Params:
## - node: the node to search from
## - type: the GDscript type to search for (ex. RigidBody2D, CharacterBody2D, Control, etc)
## 
## Example Usage:
## extends Node
## class_name EnemyManager
##
## var enemies: Enemy[]
##
## func _ready():
##    enemies = N.get_all_children(self, Enemy)
##
static func get_all_children(node: Node, type):
	if not node:
		return []
	
	var result = []

	if __is_correct_node(node, type):
		result.append(node)

	for child in node.get_children():
		result += get_all_children(child, type)

	return result

## Creates a new node with name "name", attaches a script of type "script" to it, and adds it to the tree
## with "parent" as the parent and "owner" as the owner
##
## Params:
## - script: The script to attach
## - parent: the node to add the new node under (default: none)
## - owner: the new node's owner -- usually the root of the scene. (default: none)
## - name: the name of the new node (default: the script's class name)
##
## Example Usage:
## extends Node
## class_name EnemySpawner
## 
## var spawn_every: float 5
## var _spawn_timer: float
##
## func _ready():
##     _spawn_timer = spawn_every
##
## # Create a new enemy every "spawn_every" seconds and put it at the root of the tree.
## func _physics_process(delta):
##     _spawn_timer -= delta
##     if _spawn_timer < 0:
##          _spawn_timer = spawn_every
##					var root = get_tree().root
##          N.create(Enemy, root, root)
static func create(script: GDScript, parent: Node2D = null, owner: Node2D = null, name: String = ""):
	var node = Node2D.new()
	node.set_script(script)
	return __create(node, parent, owner, (name if name else StringUtils.file_name(script.get_path())))

## Creates a new node with name "name" of type "nativeClass", and adds it to the tree
## with "parent" as the parent and "owner" as the owner
##
## Params:
## - script: The script to attach
## - parent: the node to add the new node under (default: none)
## - owner: the new node's owner -- usually the root of the scene. (default: none)
## - name: the name of the new node (default: the name of the native class)
##
## Example Usage:
## 
## var animator: AnimatedSprite2D
##
## # Creates a new animated sprite sheet and loads the resources for it.
## func _ready():
##    animator = N.create_native(AnimatedSprite2D, self, self, "animator")
##    animator.sprite_frames = load("res://my/sprite/frames.tres") 
static func create_native(nativeClass, parent: Node2D = null, owner: Node2D = null, name: String = ""):
	return __create(
		nativeClass.new(),
		parent,
		owner,
		name if name else ('%s' % [nativeClass])
	)

## PRIVATE FUNCTIONS ##

static func __is_correct_node(node: Node, type, name: String = ""):
	return is_instance_of(node, type) and (not name or node.name == name)

static func __create(node: Node2D,  parent: Node2D = null, owner: Node2D = null, name: String = ""):
	node.set_name(name)

	if owner:
		node.connect('tree_entered', (func(): node.set_owner(owner)))
	
	if parent:
		parent.add_child(node)

	return node
