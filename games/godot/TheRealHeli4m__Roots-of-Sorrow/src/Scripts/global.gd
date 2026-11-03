extends Node

signal change_room(scene: PackedScene, playerPos: Vector2, cameraPos: Vector2, yMovement: bool, xMovement: bool)

enum rooms {throne, hallway, hall, steps_left, kitchen}

var currentScene = "room"
var currentRoom = rooms.throne
var player: CharacterBody2D
var playerInCamlockXArea: bool = false
var playerInCamlockYArea: bool = false
var inMomMinigame: bool = false
var eyeAmount = 0

var sanity = 90.0
