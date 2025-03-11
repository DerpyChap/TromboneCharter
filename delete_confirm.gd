extends AcceptDialog

@onready var main : Node = get_parent()
@onready var color_events : ColorEventsEditor = %ColorEventsEditor

func _on_delete_events():
    var start = Global.settings.section_start
    var length = Global.settings.section_length
    var events := color_events.find_all_color_event_objects_in_selection(start,length)
    for event in events:
        event.queue_free()
    Global.working_tmb.color_events = color_events.package_events()
