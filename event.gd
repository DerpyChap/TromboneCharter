class_name BGEvent
extends Lyric

var id : int:
    set(value):
        id = value

@onready var spin_box : SpinBox = $SpinBox

func _ready():
    spin_box.value = id
    position.x = chart.bar_to_x(bar)
    # this is a silly workaround to spinboxes not having a submit event
    line_edit = spin_box.get_line_edit()
    line_edit.connect("text_submitted", _on_text_submitted)

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
    queue_redraw()
