class_name EventButton

extends Button

@export var event_id := 0

func _ready():
    pressed.connect(on_pressed)
    tooltip_text = str(event_id)
    text += " (" + str(event_id) + ")"

func on_pressed():
    %EventsAPI.send_event(event_id)
