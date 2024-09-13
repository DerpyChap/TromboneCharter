class_name ColorEventsEditor
extends EventsEditor

@onready var color_event_scn = preload("res://colorevent.tscn")
@onready var last_color = %Settings.start_color

func _ready():
    Global.tmb_updated.connect(_on_tmb_update)

func _add_event(bar:float,id:int,color:Color = last_color, duration: float = 0):
    var new_event = color_event_scn.instantiate()
    new_event.id = id
    new_event.bar = bar
    new_event.color = color
    new_event.duration = duration
    add_child(new_event)
    Global.working_tmb.color_events = package_events()
    return new_event

func package_events() -> Array:
    var result := []
    for event : ColorEvent in get_children():
        if !(event is ColorEvent) || event.is_queued_for_deletion(): continue
        print(event.color)
        var data := [event.id, Global.beat_to_time(event.bar), event.duration, event.color.r, event.color.g, event.color.b, event.color.a]
        result.append(data)
    result.sort_custom(func(a, b): return (a[1] < b[1]))
    return result

func _refresh_events():
    var children = get_children()
    
    for i in children.size():
        var child = children[-(i + 1)]
        if child is ColorEvent && !child.is_queued_for_deletion():
            child.queue_free()
    
    for event in Global.working_tmb.color_events:
        print(event)
        print(Global.time_to_beat(event[1]))
        var color = Color(event[3], event[4], event[5], event[6])
        _add_event(Global.time_to_beat(event[1]),event[0], color, event[2])
    
    _update_events()

func _on_events_mode_item_selected(mode: int) -> void:
    print("item selected")
    print(mode)
    if mode == Global.EVENTS_EDITOR_MODE:
        return
    match mode:
        3:
            print("setting visible")
            set_visible(true)
        _:
            set_visible(false)
