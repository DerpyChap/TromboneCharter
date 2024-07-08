class_name BGEvent
extends Lyric

var id : int:
    set(value):
        id = value

@onready var spin_box : SpinBox = $SpinBox

func _ready():
    spin_box.value = id
    position.x = chart.bar_to_x(bar)

func _draw():
        draw_polyline_colors([Vector2.ZERO,Vector2(0, size.y)],
                [Color.GREEN,Color.TRANSPARENT],2.0
            )

func _on_delete_button_pressed():
    queue_free()
    Global.working_tmb.bgdata = editor.package_events()
    editor._refresh_events()

func _on_spin_box_value_changed(new_id): id = new_id

func _on_spin_box_gui_input(event:InputEvent) -> void:
    if event is InputEventKey:
        if not event.pressed:
            return
    else:
        return
    var snap_value = 1.0 / Global.settings.timing_snap
    match event.keycode:
        KEY_UP:
            bar += snap_value
        KEY_DOWN:
            bar -= snap_value
