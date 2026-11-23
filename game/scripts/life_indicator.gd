extends "res://scripts/gear_indicator.gd"
## Lives retain the same public API and share their artwork with phase ratings.

func set_lives(value: int) -> void:
    set_count(value)
