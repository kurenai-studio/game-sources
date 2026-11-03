class_name CandidateRes
extends Resource

@export var costumer: String
@export var frame: int
@export var first_conversation:ConvRes
@export var project: String
@export var required_funds: int = 1000

enum State {WAITING, FOUNDED, REJECTED, DELAYED}

var state:State = State.WAITING
