class_name EventsAPI
extends Node

@onready var main : Control = get_node("/root/Main")
@onready var window : Window = main.get_node("EventTester")

# -1 => PlayConfetti,
# -2 => PlaySongColorConfetti,
# -3 => PlayStartColorConfetti,
# -4 => PlayEndColorConfetti,
# -10 => PlayFireworks,
# -11 => PlayFireworkComet,
# -12 => PlayFireworkPion,
# -13 => PlayFireworkPalm,
# -14 => PlayFireworkCrossover,
# -15 => PlayFireworkFlare,
# -20 => PlayAurora,
# -21 => PlaySongColorAurora

func _on_request_completed(_result, _response_code, _headers, _body, http_request):
    http_request.queue_free()

func send_event(id: int):
    print("Sending event {id}".format({"id": id}))
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed.bind(http_request))
    http_request.request("http://127.0.0.1:4523/event/{id}".format({"id": id}))

func stop_all_events():
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request("http://127.0.0.1:4523/event/stop")


func _on_event_window_close_requested() -> void:
    window.visible = false


func _on_stop_events_pressed() -> void:
    stop_all_events()
