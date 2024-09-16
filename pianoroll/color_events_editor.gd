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

func package_event_pos() -> Array:
    var result := []
    for event : ColorEvent in get_children():
        if !(event is ColorEvent) || event.is_queued_for_deletion(): continue
        var data := [event.pitch, event.bar]
        result.append(data)
    result.sort_custom(func(a, b): return (a[1] < b[1]))
    var results_filtered := []
    for r in result:
        results_filtered.append(r[0])
    return results_filtered

func _refresh_events():
    var children = get_children()
    
    for i in children.size():
        var child = children[-(i + 1)]
        if child is ColorEvent && !child.is_queued_for_deletion():
            child.queue_free()
    
    var color_events = Global.working_tmb.color_events
    var color_event_pos = Global.working_tmb.color_event_pos
    print('color events:')
    print(color_event_pos)
    var pitch_max = len(color_event_pos)
    var count = len(color_events)

    for i in range(count):
        var event = color_events[i]
        var pitch = 137.5
        if i <= pitch_max && pitch_max:
            pitch = color_event_pos[i]
        print(pitch)
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
