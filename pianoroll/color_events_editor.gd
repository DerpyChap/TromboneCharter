class_name ColorEventsEditor
extends EventsEditor

@onready var color_event_scn = preload("res://colorevent.tscn")
@onready var last_color = %Settings.start_color

func _ready():
    Global.tmb_updated.connect(_on_tmb_update)

func _add_event(bar:float,id:int,color:Color = last_color, duration: float = 0, pitch = 137.5):
    var new_event = color_event_scn.instantiate()
    new_event.id = id
    new_event.bar = bar
    new_event.color = color
    new_event.duration = duration
    new_event.pitch = pitch
    add_child(new_event)
    Global.working_tmb.color_events = package_events()
    Global.working_tmb.color_event_pos = package_event_pos()
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
            "a": event.color.a
        }
        result.append(data)
    result.sort_custom(func(a, b): return (a["time"] < b["time"]))
    return result

func package_event_pos() -> Dictionary:
    var result := {}
    for event : ColorEvent in get_children():
        if !(event is ColorEvent) || event.is_queued_for_deletion(): continue
        # turning this into a string fixed comparisons erroneously returning false presumably
        # due to floating point issues, but when i checked i didn't spot any and they didn't happen
        # on chart load so ¯\_(ツ)_/¯
        var time = str(Global.beat_to_time(event.bar))
        var events = result.get(time, [])
        events.append([event.id, event.pitch])
        result[time] = events
    return result

func _gui_input(event):
    if Input.is_key_pressed(KEY_SHIFT):
        %Chart.update_playhead(event)
        return
    if !(event is InputEventMouseButton):
        return
    if event.double_click:
        accept_event()
        var bar = %Chart.x_to_bar(event.position.x)
        if %Settings.snap_time: bar = snapped(bar, chart.current_subdiv)
        var event_id = 0
        var pos = chart.get_local_mouse_position() - Vector2(0, 20)
        var snapped_pos = chart.to_snapped(pos)
        var new_event = _add_event(bar,event_id, last_color, 0, snapped_pos.y)
        new_event.spin_box.get_line_edit().grab_focus()
    elif !event.is_released():
        viewport.gui_release_focus()

func _refresh_events():
    var children = get_children()
    
    for i in children.size():
        var child = children[-(i + 1)]
        if child is ColorEvent && !child.is_queued_for_deletion():
            child.queue_free()
    
    var color_events = Global.working_tmb.color_events
    var color_event_pos = Global.working_tmb.color_event_pos
    var count = len(color_events)

    for i in range(count):
        var event = color_events[i]
        var pitch = 137.5
        var pos_data = color_event_pos.get(str(event["time"]))
        if pos_data:
            for e in pos_data:
                if e[0] == event.id:
                    pitch = e[1]
                    break
        var color = Color(event["r"], event["g"], event["b"], event["a"])
        _add_event(Global.time_to_beat(event["time"]),event["id"], color, event["duration"], pitch)
    
    _update_events()

func _on_events_mode_item_selected(mode: int) -> void:
    match mode:
        3:
            move_to_front()
            %PlayheadHandle.move_to_front()
            set_visible(true)
        _:
            set_visible(false)
