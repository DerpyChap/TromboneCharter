extends AcceptDialog

@onready var main : Node = get_parent()
@onready var merge_button : Button = add_button("Merge", false, "merge")
var target: float
var data: Dictionary

var notes_template = """Are you sure you want to paste %s notes at beat %s?
%s
Notes with tails going into or out of the section might end up overlapping other notes."""
var events_template = """Are you sure you want to paste %s events at beat %s?"""


func set_values(_target: float, _data: Dictionary):
    target = _target
    data = _data
    # no match statement here because it just... didn't work? might be a weird gdscript bug
    if data.trombone_charter_data_type == main.ClipboardType.COLOR_EVENTS:
        var overwrite_events = main.tmb.find_all_color_events_in_section(target,data.length)
        dialog_text = events_template % [data.count, target]
        if overwrite_events:
            ok_button_text = "Overwrite"
            dialog_text += "\n\nThere are already %s events here, you can either overwrite them or merge them." % overwrite_events.size()
            merge_button.visible = true
        else:
            ok_button_text = "OK"
            merge_button.visible = false
    elif data.trombone_charter_data_type == main.ClipboardType.NOTES:
        ok_button_text = "OK"
        var overwrite_notes = main.tmb.find_all_notes_in_section(target,data.length)
        var to_overwrite = ("\nThis will overwrite %s notes!\n" % overwrite_notes.size()) if overwrite_notes else ""
        merge_button.visible = false
        dialog_text = notes_template % [data.count, target, to_overwrite]

func _on_copy_confirmed():
    var data_types = ["notes", "color events"]
    if data.trombone_charter_data_type == main.ClipboardType.COLOR_EVENTS:
        main.tmb.clear_color_events_section(target, data.length)
        _paste_color_events()
    elif data.trombone_charter_data_type == main.ClipboardType.NOTES:
        var notes = data.notes
        if notes.is_empty():
            print("copy section empy")
            return
        
        main.tmb.clear_section(target,data.length)
        for note in notes:
            note[TMBInfo.NOTE_BAR] += target
            main.tmb.notes.append(note)
        main.tmb.notes.sort_custom(func(a,b): return a[TMBInfo.NOTE_BAR] < b[TMBInfo.NOTE_BAR])
        main.emit_signal("chart_loaded")
    Global.settings.section_length = 0
    %Alert.alert("Inserted %s %s from clipboard" % [data.count, data_types[data.trombone_charter_data_type]], Vector2(%ChartView.global_position.x, 10),
                Alert.LV_SUCCESS)

func _paste_color_events():
    var events = data.events
    var init_time = Global.beat_to_time(events[0]["time"] + target)
    var insert_pos = 0
    for event in main.tmb.color_events:
        if event["time"] > init_time:
            break
        insert_pos += 1
    for event in events:
        event["time"] = Global.beat_to_time(event["time"] + target)
        main.tmb.color_events.insert(insert_pos, event)
        insert_pos += 1
    main.emit_signal("chart_loaded")

func _on_custom_action(action: StringName) -> void:
    match action:
        "merge":
            _paste_color_events()
            Global.settings.section_length = 0
            %Alert.alert("Inserted %s events from clipboard" % data.count, Vector2(%ChartView.global_position.x, 10),
                        Alert.LV_SUCCESS)
    visible = false