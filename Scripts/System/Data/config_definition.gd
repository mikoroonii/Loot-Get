class_name userConfig extends Node

func _init(tc: TwitchDataClass, Weights: Array):
	self.TwitchConfig = tc
	self.weights.assign(Weights)

var TwitchConfig: TwitchDataClass

var weights: Array[float]


class TwitchDataClass: 
	var channel: String
	var user: String
	var cooldown: int
	var prefixes: Array

	func _init(Channel: String, User: String, Cooldown: int, Prefixes: Array):
		self.channel = Channel
		self.user = User
		self.cooldown = Cooldown
		self.prefixes = Prefixes
