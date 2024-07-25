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

func _on_show_events_toggled(button_pressed):
    move_to_front()
    %PlayheadHandle.move_to_front()
    set_visible(button_pressed)

func _gui_input(event):
    if Input.is_key_pressed(KEY_SHIFT):
        %Chart.update_playhead(event)
        return
    if !(event is InputEventMouseButton):
        return
    if event.double_click:
        var bar = %Chart.x_to_bar(event.position.x)
        if %Settings.snap_time: bar = snapped(bar, chart.current_subdiv)
        var new_event = _add_event(bar,0)
        new_event.spin_box.get_line_edit().grab_focus()
    elif !event.is_released():
        viewport.gui_release_focus()
