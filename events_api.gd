class_name EventsAPI
extends Node

@onready var main : Control = get_node("/root/Main")
@onready var window : Window = main.get_node("EventTester")
@onready var color_event_selector : OptionButton = %SendColorEvent
@onready var color_event_picker : ColorPickerButton = %ColorEventPicker
@onready var color_event_duration : SpinBox = %ColorEventDuration

func _on_request_completed(_result, _response_code, _headers, _body, http_request):
    print(_response_code)
    http_request.queue_free()

func send_event(id: int):
    print("Sending event {id}".format({"id": id}))
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed.bind(http_request))
    http_request.request("http://127.0.0.1:4523/event/{id}".format({"id": id}))

func send_color_event(id: int, time: float, duration: float, color: Color):
    print("Sending color event {id}".format({"id": id}))
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed.bind(http_request))
    print(color.to_html())
    var url = "http://127.0.0.1:4523/color_event/{id},{time},{duration},{colorhex}".format(
        {
            "id": id,
            "time": time,
            "duration": duration,
            "colorhex": color.to_html()
        }
    )
    http_request.request(url)

func stop_all_events():
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed.bind(http_request))
    http_request.request("http://127.0.0.1:4523/event/stop")

func reset_color_events():
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed.bind(http_request))
    http_request.request("http://127.0.0.1:4523/color_event/reset")

func _on_event_window_close_requested() -> void:
    window.visible = false


func _on_stop_events_pressed() -> void:
    stop_all_events()

func _on_stop_color_events_pressed() -> void:
    reset_color_events()

func _on_color_event_pressed() -> void:
    send_color_event(
        color_event_selector.get_selected_id(),
        0,
        color_event_duration.value,
        color_event_picker.color
    )