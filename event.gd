class_name BGEvent
extends Lyric

var id : int:
    set(value):
        if Global.EVENTS_EDITOR_MODE == 1 && id in [-100, -101] && value not in [-100, -101]:
            spin_box.value = id
            # stops lane switch mode from setting non-lane switch ids
            return
        id = value
        if Global.EVENTS_EDITOR_MODE == 1 && id not in [-100, -101]:
            set_visible(false)
        else:
            set_visible(true)

@onready var spin_box : SpinBox = $SpinBox

func _ready():
    spin_box.value = id
    position.x = chart.bar_to_x(bar)
    # this is a silly workaround to spinboxes not having a submit event
    line_edit = spin_box.get_line_edit()
    line_edit.connect("text_submitted", _on_text_submitted)
    Global.events_mode_changed.connect(_on_event_mode_changed)

func _on_text_submitted(_text:String):
    line_edit.release_focus()

func _draw():
    match id:
        -100:
            draw_polyline_colors([Vector2.ZERO,Vector2(0, size.y)],
                [Color.RED,Color.TRANSPARENT],4.0
            )
        -101:
            draw_polyline_colors([Vector2.ZERO,Vector2(0, size.y)],
                [Color.BLUE,Color.TRANSPARENT],4.0
            )
        _:
            draw_polyline_colors([Vector2.ZERO,Vector2(0, size.y)],
                [Color.GREEN,Color.TRANSPARENT],2.0
            )

func _on_delete_button_pressed():
    queue_free()
    Global.working_tmb.bgdata = editor.package_events()
    editor._refresh_events()

func _on_spin_box_value_changed(new_id):
    id = new_id
    Global.working_tmb.bgdata = editor.package_events()
    queue_redraw()

func _on_event_mode_changed(mode: int):
    match mode:
        1:
            if id in [-100, -101]:
                set_visible(true)
            else:
                set_visible(false)
        2:
            if not visible:
                set_visible(true)