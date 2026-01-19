extends ParallaxBackground


@onready var speed: int = 50

func _process(delta):
	scroll_offset.x -= speed * delta
