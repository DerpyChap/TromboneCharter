class_name EventsEditor
extends Control


var event_scn = preload("res://bgevent.tscn")
@onready var chart = %Chart
@onready var viewport = get_viewport()

var _update_queued := false

func _ready():
    print("ready")
    Global.tmb_updated.connect(_on_tmb_update)

func _on_tmb_update(): _update_queued = true
func _process(_delta): if _update_queued: _update_events()


func _add_event(bar:float,id:int):
    var new_event = event_scn.instantiate()
    new_event.id = id
    new_event.bar = bar
    add_child(new_event)
    Global.working_tmb.bgdata = package_events()
    return new_event

func _update_events():
    for child in get_children():
        if !(child is BGEvent): continue
        child.position.x = chart.bar_to_x(child.bar)
    _update_queued = false

func package_events() -> Array:
    var result := []
    for event in get_children():
        if !(event is BGEvent) || event.is_queued_for_deletion(): continue
        var data := [Global.beat_to_time(event.bar), event.id, event.bar]
        result.append(data)
    result.sort_custom(func(a, b): return (a[2] < b[2]))
    return result

func _refresh_events():
    var children = get_children()
    
    for i in children.size():
        var child = children[-(i + 1)]
        if child is BGEvent && !child.is_queued_for_deletion():
            child.queue_free()
    
    for event in Global.working_tmb.bgdata:
        _add_event(event[2],event[1])
    
    _update_events()

func _on_chart_loaded():
    _refresh_events()
    move_to_front()
    %PlayheadHandle.move_to_front()

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
        if Global.EVENTS_EDITOR_MODE == 1 && event.button_index == MOUSE_BUTTON_LEFT:
            event_id = -100
        elif Global.EVENTS_EDITOR_MODE == 1 && event.button_index == MOUSE_BUTTON_RIGHT:
            event_id = -101
        var new_event = _add_event(bar,event_id)
        new_event.spin_box.get_line_edit().grab_focus()
    elif !event.is_released():
        viewport.gui_release_focus()


func _on_option_button_item_selected(index:int) -> void:
    Global.EVENTS_EDITOR_MODE = index
    match index:
        1:
            move_to_front()
            %PlayheadHandle.move_to_front()
            for event in get_children():
                if event.id in [-100, -101]:
                    event.set_visible(true)
                else:
                    event.set_visible(false)
            set_visible(true)
        2:
            move_to_front()
            %PlayheadHandle.move_to_front()
            for event in get_children():
                event.set_visible(true)
            set_visible(true)
        _:
            set_visible(false)
