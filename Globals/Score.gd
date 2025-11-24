extends Node

var score: int = 0

func add_points(points: int) -> void:
    score += points
    
func reset() -> void:
    score = 0