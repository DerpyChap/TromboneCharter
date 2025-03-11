class_name ColorEventsEditor
extends EventsEditor

@onready var color_event_scn = preload("res://colorevent.tscn")
@onready var last_color = %Settings.start_color

func _ready():
    Global.tmb_updated.connect(_on_tmb_update)

func _add_event(bar:float,id:int,color:Color = last_color, duration: float = 0, pitch = 137.5, package = true):
    var new_event := color_event_scn.instantiate()
    new_event.id = id
    new_event.bar = bar
    new_event.color = color
    new_event.duration = duration
    new_event.pitch = pitch
    add_child(new_event)
    if package:
        Global.working_tmb.color_events = package_events()
    return new_event

func package_events() -> Array:
    var result := []
    for event : ColorEvent in get_children():
        if !(event is ColorEvent) || event.is_queued_for_deletion(): continue
        var data := {
            "id": event.id,
            "time": Global.beat_to_time(event.bar),
            "duration": event.duration,
            "r": event.color.r,
            "g": event.color.g,
            "b": event.color.b,
            "a": event.color.a,
            "pitch": event.pitch
        }
        result.append(data)
    result.sort_custom(func(a, b): return (a["time"] < b["time"]))
    return result

func _gui_input(event) -> void:
    if Input.is_key_pressed(KEY_SHIFT):
        %Chart.update_playhead(event)
        return
    if !(event is InputEventMouseButton):
        return
    if event.double_click:
        accept_event()
        var bar = %Chart.x_to_bar(event.position.x)
        if %Settings.snap_time: bar = snapped(bar, chart.current_subdiv)
        var event_id := 0
        var pos      =  chart.get_local_mouse_position() - Vector2(0, 20)
        var snapped_pos = chart.to_snapped(pos)
        var new_event = _add_event(bar,event_id, last_color, 0, snapped_pos.y)
        new_event.spin_box.get_line_edit().grab_focus()
    elif !event.is_released():
        viewport.gui_release_focus()

func _refresh_events():
    var children: Array[Node] = get_children()
    
    for child in children:
        if child is ColorEvent && !child.is_queued_for_deletion():
            child.queue_free()
    
    var color_events = Global.working_tmb.color_events

    for event in color_events:
        var color := Color(event["r"], event["g"], event["b"], event["a"])
        _add_event(Global.time_to_beat(event["time"]),event["id"], color, event["duration"], event["pitch"], false)
        
    Global.working_tmb.color_events = package_events()	

func _on_events_mode_item_selected(mode: int) -> void:
    match mode:
        3:
            move_to_front()
            %PlayheadHandle.move_to_front()
            set_visible(true)
        _:
            set_visible(false)
